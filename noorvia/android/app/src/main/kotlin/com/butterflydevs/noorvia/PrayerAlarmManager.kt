package com.butterflydevs.noorvia

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import org.json.JSONObject
import java.util.Calendar

class PrayerAlarmManager(private val context: Context) {

    companion object {
        private const val TAG = "PrayerAlarmManager"
        private const val PREFS_NAME = "prayer_alarm_prefs"
        private const val KEY_ALARMS = "alarms"
        private const val PRE_ALARM_OFFSET = 1000

        const val FAJR_ID = 100
        const val DHUHR_ID = 101
        const val ASR_ID = 102
        const val MAGHRIB_ID = 103
        const val ISHA_ID = 104
    }

    private val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun scheduleAlarm(
        prayerId: Int,
        prayerName: String,
        hour: Int,
        minute: Int,
        preAlarmMinutes: Int = 0,
        vibrationEnabled: Boolean = true,
        volume: Float = 1.0f,
    ): Boolean {
        val prayerTime = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (!after(Calendar.getInstance())) add(Calendar.DAY_OF_YEAR, 1)
        }

        val actualScheduled = scheduleExact(
            requestCode = prayerId,
            prayerId = prayerId,
            prayerName = prayerName,
            triggerAt = prayerTime.timeInMillis,
            preAlarmMinutes = preAlarmMinutes,
            isPreAlarm = false,
            vibrationEnabled = vibrationEnabled,
            volume = volume,
            hour = hour,
            minute = minute,
        )

        if (preAlarmMinutes > 0) {
            val preTime = (prayerTime.clone() as Calendar).apply {
                add(Calendar.MINUTE, -preAlarmMinutes)
            }
            if (preTime.after(Calendar.getInstance())) {
                scheduleExact(
                    requestCode = prayerId + PRE_ALARM_OFFSET,
                    prayerId = prayerId,
                    prayerName = prayerName,
                    triggerAt = preTime.timeInMillis,
                    preAlarmMinutes = preAlarmMinutes,
                    isPreAlarm = true,
                    vibrationEnabled = vibrationEnabled,
                    volume = volume,
                    hour = hour,
                    minute = minute,
                )
            }
        }

        // Persist the user's requested alarm even if Android has not granted
        // exact-alarm access yet. The permission-state receiver can then
        // schedule it automatically as soon as access is granted.
        saveAlarmInfo(
            prayerId,
            prayerName,
            hour,
            minute,
            preAlarmMinutes,
            vibrationEnabled,
            volume,
        )

        // Smart Salah is intentionally coupled to the authoritative prayer
        // schedule. It uses its own PendingIntents, so changing Azan settings
        // never destroys the user's ringer-mode preferences.
        SmartSalahManager(context).scheduleForPrayer(prayerId, prayerTime.timeInMillis)
        return actualScheduled
    }

    private fun scheduleExact(
        requestCode: Int,
        prayerId: Int,
        prayerName: String,
        triggerAt: Long,
        preAlarmMinutes: Int,
        isPreAlarm: Boolean,
        vibrationEnabled: Boolean,
        volume: Float,
        hour: Int,
        minute: Int,
    ): Boolean {
        val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
            putExtra("prayerId", prayerId)
            putExtra("prayerName", prayerName)
            putExtra("preAlarmMinutes", preAlarmMinutes)
            putExtra("isPreAlarm", isPreAlarm)
            putExtra("vibrationEnabled", vibrationEnabled)
            putExtra("volume", volume)
            putExtra("hour", hour)
            putExtra("minute", minute)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
                Log.w(TAG, "Exact alarm permission is not granted")
                return false
            }
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ->
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT ->
                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
                else -> alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
            }
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Unable to schedule exact prayer alarm", e)
            return false
        }
    }

    fun cancelAlarm(prayerId: Int) {
        cancelRequest(prayerId)
        cancelRequest(prayerId + PRE_ALARM_OFFSET)
        SmartSalahManager(context).cancelForPrayer(prayerId)
        removeAlarmInfo(prayerId)
    }

    private fun cancelRequest(requestCode: Int) {
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            Intent(context, PrayerAlarmReceiver::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
    }

    fun cancelAllAlarms() {
        listOf(FAJR_ID, DHUHR_ID, ASR_ID, MAGHRIB_ID, ISHA_ID).forEach(::cancelAlarm)
    }

    fun rescheduleSingleAlarm(prayerId: Int) {
        val alarm = getScheduledAlarms()[prayerId] ?: return
        scheduleAlarm(
            prayerId = alarm["prayerId"] as Int,
            prayerName = alarm["prayerName"] as String,
            hour = alarm["hour"] as Int,
            minute = alarm["minute"] as Int,
            preAlarmMinutes = alarm["preAlarmMinutes"] as Int,
            vibrationEnabled = alarm["vibrationEnabled"] as Boolean,
            volume = (alarm["volume"] as Double).toFloat(),
        )
    }

    private fun saveAlarmInfo(
        prayerId: Int,
        prayerName: String,
        hour: Int,
        minute: Int,
        preAlarmMinutes: Int,
        vibrationEnabled: Boolean,
        volume: Float,
    ) {
        val alarmsJson = JSONObject(prefs.getString(KEY_ALARMS, "{}") ?: "{}")
        alarmsJson.put(prayerId.toString(), JSONObject().apply {
            put("prayerId", prayerId)
            put("prayerName", prayerName)
            put("hour", hour)
            put("minute", minute)
            put("preAlarmMinutes", preAlarmMinutes)
            put("vibrationEnabled", vibrationEnabled)
            put("volume", volume.toDouble())
            put("scheduledAt", System.currentTimeMillis())
        })
        prefs.edit().putString(KEY_ALARMS, alarmsJson.toString()).apply()
    }

    private fun removeAlarmInfo(prayerId: Int) {
        val alarmsJson = JSONObject(prefs.getString(KEY_ALARMS, "{}") ?: "{}")
        alarmsJson.remove(prayerId.toString())
        prefs.edit().putString(KEY_ALARMS, alarmsJson.toString()).apply()
    }

    fun getScheduledAlarms(): Map<Int, Map<String, Any>> {
        val alarmsJson = JSONObject(prefs.getString(KEY_ALARMS, "{}") ?: "{}")
        val result = mutableMapOf<Int, Map<String, Any>>()
        alarmsJson.keys().forEach { key ->
            val info = alarmsJson.getJSONObject(key)
            result[key.toInt()] = mapOf(
                "prayerId" to info.getInt("prayerId"),
                "prayerName" to info.getString("prayerName"),
                "hour" to info.getInt("hour"),
                "minute" to info.getInt("minute"),
                "preAlarmMinutes" to info.getInt("preAlarmMinutes"),
                "vibrationEnabled" to info.getBoolean("vibrationEnabled"),
                "volume" to info.getDouble("volume"),
                "scheduledAt" to info.getLong("scheduledAt"),
            )
        }
        return result
    }

    fun rescheduleAlarmsAfterReboot() {
        getScheduledAlarms().values.forEach { alarm ->
            scheduleAlarm(
                prayerId = alarm["prayerId"] as Int,
                prayerName = alarm["prayerName"] as String,
                hour = alarm["hour"] as Int,
                minute = alarm["minute"] as Int,
                preAlarmMinutes = alarm["preAlarmMinutes"] as Int,
                vibrationEnabled = alarm["vibrationEnabled"] as Boolean,
                volume = (alarm["volume"] as Double).toFloat(),
            )
        }
    }
}
