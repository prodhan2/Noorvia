package com.butterflydevs.noorvia

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build
import android.provider.Settings
import org.json.JSONObject

/**
 * Applies and restores a user opted-in prayer-time ringer/DND mode.
 *
 * Privacy: mosque-aware mode only consumes a boolean maintained by Android
 * geofences. Raw live location is not persisted here.
 */
class SmartSalahManager(private val context: Context) {
    companion object {
        private const val PREFS = "smart_salah_prefs"
        private const val START_OFFSET = 2000
        private const val RESTORE_OFFSET = 3000
        private const val KEY_SETTINGS = "settings"
        private const val KEY_ACTIVE_GEOFENCES = "active_mosque_geofences"
        private const val KEY_PREVIOUS_RINGER = "previous_ringer"
        private const val KEY_PREVIOUS_FILTER = "previous_filter"
        private const val KEY_ACTIVE_SESSION = "active_session"

        fun settingsIntent(): Intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
    }

    private val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    private val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    fun saveSettings(map: Map<*, *>) {
        val prayers = map["prayers"] as? Map<*, *> ?: emptyMap<Any, Any>()
        val json = JSONObject().apply {
            put("enabled", map["enabled"] as? Boolean ?: false)
            put("triggerMode", map["triggerMode"]?.toString() ?: "time_only")
            put("phoneMode", map["phoneMode"]?.toString() ?: "vibrate")
            put("beforeMinutes", (map["beforeMinutes"] as? Number)?.toInt() ?: 0)
            put("afterMinutes", (map["afterMinutes"] as? Number)?.toInt() ?: 20)
            put("mosqueRadius", (map["mosqueRadius"] as? Number)?.toInt() ?: 150)
            put("restorePreviousMode", map["restorePreviousMode"] as? Boolean ?: true)
            put("prayers", JSONObject().apply {
                listOf("fajr", "dhuhr", "asr", "maghrib", "isha").forEach { key ->
                    put(key, prayers[key] as? Boolean ?: true)
                }
            })
        }
        prefs.edit().putString(KEY_SETTINGS, json.toString()).apply()
    }

    fun getSettings(): Map<String, Any> {
        val j = settingsJson()
        val prayers = j.optJSONObject("prayers") ?: JSONObject()
        return mapOf(
            "enabled" to j.optBoolean("enabled", false),
            "triggerMode" to j.optString("triggerMode", "time_only"),
            "phoneMode" to j.optString("phoneMode", "vibrate"),
            "beforeMinutes" to j.optInt("beforeMinutes", 0),
            "afterMinutes" to j.optInt("afterMinutes", 20),
            "mosqueRadius" to j.optInt("mosqueRadius", 150),
            "restorePreviousMode" to j.optBoolean("restorePreviousMode", true),
            "nearMosque" to isNearMosque(),
            "hasPolicyAccess" to hasNotificationPolicyAccess(),
            "prayers" to mapOf(
                "fajr" to prayers.optBoolean("fajr", true),
                "dhuhr" to prayers.optBoolean("dhuhr", true),
                "asr" to prayers.optBoolean("asr", true),
                "maghrib" to prayers.optBoolean("maghrib", true),
                "isha" to prayers.optBoolean("isha", true),
            ),
        )
    }

    fun scheduleForPrayer(prayerId: Int, prayerTimeMillis: Long) {
        cancelForPrayer(prayerId)
        val settings = settingsJson()
        if (!settings.optBoolean("enabled", false)) return
        val key = prayerKey(prayerId) ?: return
        if (!(settings.optJSONObject("prayers")?.optBoolean(key, true) ?: true)) return

        val before = settings.optInt("beforeMinutes", 0).coerceIn(0, 60)
        val triggerAt = prayerTimeMillis - before * 60_000L
        val intent = Intent(context, SmartSalahStartReceiver::class.java).apply {
            putExtra("prayerId", prayerId)
            putExtra("prayerTimeMillis", prayerTimeMillis)
        }
        scheduleExact(
            requestCode = prayerId + START_OFFSET,
            triggerAt = triggerAt,
            pendingIntent = PendingIntent.getBroadcast(
                context,
                prayerId + START_OFFSET,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            ),
        )
    }

    fun cancelForPrayer(prayerId: Int) {
        cancelRequest(prayerId + START_OFFSET, SmartSalahStartReceiver::class.java)
        cancelRequest(prayerId + RESTORE_OFFSET, SmartSalahRestoreReceiver::class.java)
    }

    fun apply(prayerId: Int, prayerTimeMillis: Long): Boolean {
        val settings = settingsJson()
        if (!settings.optBoolean("enabled", false)) return false
        val key = prayerKey(prayerId) ?: return false
        if (!(settings.optJSONObject("prayers")?.optBoolean(key, true) ?: true)) return false
        if (settings.optString("triggerMode") == "mosque_aware" && !isNearMosque()) return false

        val audio = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val session = "$prayerId:$prayerTimeMillis"
        if (prefs.getString(KEY_ACTIVE_SESSION, null) == null) {
            prefs.edit()
                .putInt(KEY_PREVIOUS_RINGER, audio.ringerMode)
                .putInt(KEY_PREVIOUS_FILTER, if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) nm.currentInterruptionFilter else -1)
                .putString(KEY_ACTIVE_SESSION, session)
                .apply()
        } else {
            prefs.edit().putString(KEY_ACTIVE_SESSION, session).apply()
        }

        when (settings.optString("phoneMode", "vibrate")) {
            "silent" -> {
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N || hasNotificationPolicyAccess()) {
                    audio.ringerMode = AudioManager.RINGER_MODE_SILENT
                } else {
                    audio.ringerMode = AudioManager.RINGER_MODE_VIBRATE
                }
            }
            "dnd" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && hasNotificationPolicyAccess()) {
                    // Priority mode respects the user's Android DND exceptions such as
                    // starred/repeat callers instead of Noorvia overriding their policy.
                    nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
                } else {
                    audio.ringerMode = AudioManager.RINGER_MODE_VIBRATE
                }
            }
            else -> audio.ringerMode = AudioManager.RINGER_MODE_VIBRATE
        }

        if (settings.optBoolean("restorePreviousMode", true)) {
            val after = settings.optInt("afterMinutes", 20).coerceIn(5, 120)
            val restoreAt = prayerTimeMillis + after * 60_000L
            val restoreIntent = Intent(context, SmartSalahRestoreReceiver::class.java).apply {
                putExtra("session", session)
            }
            scheduleExact(
                requestCode = prayerId + RESTORE_OFFSET,
                triggerAt = restoreAt,
                pendingIntent = PendingIntent.getBroadcast(
                    context,
                    prayerId + RESTORE_OFFSET,
                    restoreIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                ),
            )
        }
        return true
    }

    fun restore(session: String? = null) {
        val active = prefs.getString(KEY_ACTIVE_SESSION, null) ?: return
        // A newer prayer session owns the current mode; an old restore alarm must
        // never undo it.
        if (session != null && session != active) return

        val audio = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val previousRinger = prefs.getInt(KEY_PREVIOUS_RINGER, AudioManager.RINGER_MODE_NORMAL)
        val previousFilter = prefs.getInt(KEY_PREVIOUS_FILTER, -1)

        try {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N || hasNotificationPolicyAccess() || previousRinger != AudioManager.RINGER_MODE_SILENT) {
                audio.ringerMode = previousRinger
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && hasNotificationPolicyAccess() && previousFilter >= 0) {
                nm.setInterruptionFilter(previousFilter)
            }
        } catch (_: SecurityException) {
        } finally {
            prefs.edit()
                .remove(KEY_ACTIVE_SESSION)
                .remove(KEY_PREVIOUS_RINGER)
                .remove(KEY_PREVIOUS_FILTER)
                .apply()
        }
    }

    fun hasNotificationPolicyAccess(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return nm.isNotificationPolicyAccessGranted
    }

    fun setActiveGeofence(id: String, active: Boolean) {
        val set = prefs.getStringSet(KEY_ACTIVE_GEOFENCES, emptySet())?.toMutableSet() ?: mutableSetOf()
        if (active) set.add(id) else set.remove(id)
        prefs.edit().putStringSet(KEY_ACTIVE_GEOFENCES, set).apply()
    }

    fun clearActiveGeofences() {
        prefs.edit().remove(KEY_ACTIVE_GEOFENCES).apply()
    }

    fun isNearMosque(): Boolean = !prefs.getStringSet(KEY_ACTIVE_GEOFENCES, emptySet()).isNullOrEmpty()

    private fun settingsJson(): JSONObject = try {
        JSONObject(prefs.getString(KEY_SETTINGS, "{}") ?: "{}")
    } catch (_: Exception) {
        JSONObject()
    }

    private fun prayerKey(id: Int): String? = when (id) {
        PrayerAlarmManager.FAJR_ID -> "fajr"
        PrayerAlarmManager.DHUHR_ID -> "dhuhr"
        PrayerAlarmManager.ASR_ID -> "asr"
        PrayerAlarmManager.MAGHRIB_ID -> "maghrib"
        PrayerAlarmManager.ISHA_ID -> "isha"
        else -> null
    }

    private fun scheduleExact(requestCode: Int, triggerAt: Long, pendingIntent: PendingIntent) {
        if (triggerAt <= System.currentTimeMillis()) return
        try {
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms() ->
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ->
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT ->
                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
                else -> alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
            }
        } catch (_: SecurityException) {
            alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
        }
    }

    private fun cancelRequest(requestCode: Int, receiver: Class<*>) {
        val pi = PendingIntent.getBroadcast(
            context,
            requestCode,
            Intent(context, receiver),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        ) ?: return
        alarmManager.cancel(pi)
        pi.cancel()
    }
}
