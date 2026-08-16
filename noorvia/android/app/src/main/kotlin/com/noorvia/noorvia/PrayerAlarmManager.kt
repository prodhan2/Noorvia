package com.noorvia.noorvia

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import org.json.JSONObject
import java.util.*

class PrayerAlarmManager(private val context: Context) {

    companion object {
        private const val TAG = "PrayerAlarmManager"
        private const val PREFS_NAME = "prayer_alarm_prefs"
        private const val KEY_ALARMS = "alarms"
        
        // Prayer IDs
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
        volume: Float = 1.0f
    ) {
        Log.d(TAG, "Scheduling alarm for $prayerName at $hour:$minute (pre-alarm: $preAlarmMinutes min)")
        
        val alarmTime = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            
            // Apply pre-alarm
            add(Calendar.MINUTE, -preAlarmMinutes)
            
            // If time already passed, schedule for tomorrow
            if (before(Calendar.getInstance())) {
                add(Calendar.DAY_OF_YEAR, 1)
            }
        }

        val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
            putExtra("prayerId", prayerId)
            putExtra("prayerName", prayerName)
            putExtra("preAlarmMinutes", preAlarmMinutes)
            putExtra("vibrationEnabled", vibrationEnabled)
            putExtra("volume", volume)
        }

        val requestCode = prayerId
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            flags
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    alarmTime.timeInMillis,
                    pendingIntent
                )
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    alarmTime.timeInMillis,
                    pendingIntent
                )
            } else {
                alarmManager.set(
                    AlarmManager.RTC_WAKEUP,
                    alarmTime.timeInMillis,
                    pendingIntent
                )
            }

            // Save alarm info
            saveAlarmInfo(prayerId, prayerName, hour, minute, preAlarmMinutes, vibrationEnabled, volume)
            
            Log.d(TAG, "✅ Alarm scheduled successfully for $prayerName at ${alarmTime.time}")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error scheduling alarm", e)
        }
    }

    fun cancelAlarm(prayerId: Int) {
        Log.d(TAG, "Canceling alarm for ID: $prayerId")
        
        val intent = Intent(context, PrayerAlarmReceiver::class.java)
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            prayerId,
            intent,
            flags
        )

        try {
            alarmManager.cancel(pendingIntent)
            removeAlarmInfo(prayerId)
            Log.d(TAG, "✅ Alarm canceled for ID: $prayerId")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error canceling alarm", e)
        }
    }

    fun cancelAllAlarms() {
        Log.d(TAG, "Canceling all alarms")
        listOf(FAJR_ID, DHUHR_ID, ASR_ID, MAGHRIB_ID, ISHA_ID).forEach { id ->
            cancelAlarm(id)
        }
    }

    private fun saveAlarmInfo(
        prayerId: Int,
        prayerName: String,
        hour: Int,
        minute: Int,
        preAlarmMinutes: Int,
        vibrationEnabled: Boolean,
        volume: Float
    ) {
        val alarmsJson = JSONObject(prefs.getString(KEY_ALARMS, "{}") ?: "{}")
        
        val alarmInfo = JSONObject().apply {
            put("prayerId", prayerId)
            put("prayerName", prayerName)
            put("hour", hour)
            put("minute", minute)
            put("preAlarmMinutes", preAlarmMinutes)
            put("vibrationEnabled", vibrationEnabled)
            put("volume", volume)
            put("scheduledAt", System.currentTimeMillis())
        }

        alarmsJson.put(prayerId.toString(), alarmInfo)
        
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
            val alarmInfo = alarmsJson.getJSONObject(key)
            result[key.toInt()] = mapOf(
                "prayerId" to alarmInfo.getInt("prayerId"),
                "prayerName" to alarmInfo.getString("prayerName"),
                "hour" to alarmInfo.getInt("hour"),
                "minute" to alarmInfo.getInt("minute"),
                "preAlarmMinutes" to alarmInfo.getInt("preAlarmMinutes"),
                "vibrationEnabled" to alarmInfo.getBoolean("vibrationEnabled"),
                "volume" to alarmInfo.getDouble("volume"),
                "scheduledAt" to alarmInfo.getLong("scheduledAt")
            )
        }
        
        return result
    }

    fun rescheduleAlarmsAfterReboot() {
        Log.d(TAG, "Rescheduling alarms after reboot")
        val alarms = getScheduledAlarms()
        
        alarms.values.forEach { alarm ->
            scheduleAlarm(
                prayerId = alarm["prayerId"] as Int,
                prayerName = alarm["prayerName"] as String,
                hour = alarm["hour"] as Int,
                minute = alarm["minute"] as Int,
                preAlarmMinutes = alarm["preAlarmMinutes"] as Int,
                vibrationEnabled = alarm["vibrationEnabled"] as Boolean,
                volume = (alarm["volume"] as Double).toFloat()
            )
        }
    }
}
