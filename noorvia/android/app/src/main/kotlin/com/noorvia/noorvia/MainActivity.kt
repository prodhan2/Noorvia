package com.noorvia.noorvia

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.noorvia.noorvia/prayer_alarm"
    private lateinit var alarmManager: PrayerAlarmManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        alarmManager = PrayerAlarmManager(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val args = call.arguments as? Map<*, *>
                    val prayerId = args?.get("prayerId") as? Int ?: -1
                    val prayerName = args?.get("prayerName") as? String ?: ""
                    val hour = args?.get("hour") as? Int ?: 0
                    val minute = args?.get("minute") as? Int ?: 0
                    val preAlarmMinutes = args?.get("preAlarmMinutes") as? Int ?: 0
                    val vibrationEnabled = args?.get("vibrationEnabled") as? Boolean ?: true
                    val volume = (args?.get("volume") as? Double)?.toFloat() ?: 1.0f

                    alarmManager.scheduleAlarm(
                        prayerId = prayerId,
                        prayerName = prayerName,
                        hour = hour,
                        minute = minute,
                        preAlarmMinutes = preAlarmMinutes,
                        vibrationEnabled = vibrationEnabled,
                        volume = volume
                    )
                    result.success(true)
                }
                "cancelAlarm" -> {
                    val args = call.arguments as? Map<*, *>
                    val prayerId = args?.get("prayerId") as? Int ?: -1
                    alarmManager.cancelAlarm(prayerId)
                    result.success(true)
                }
                "cancelAllAlarms" -> {
                    alarmManager.cancelAllAlarms()
                    result.success(true)
                }
                "getScheduledAlarms" -> {
                    val alarms = alarmManager.getScheduledAlarms()
                    result.success(alarms)
                }
                "updateWidget" -> {
                    val args = call.arguments as? Map<*, *>
                    val fajr = args?.get("fajr") as? String ?: "05:30"
                    val dhuhr = args?.get("dhuhr") as? String ?: "12:15"
                    val asr = args?.get("asr") as? String ?: "15:45"
                    val maghrib = args?.get("maghrib") as? String ?: "18:30"
                    val isha = args?.get("isha") as? String ?: "19:45"
                    val location = args?.get("location") as? String ?: "📍 ঢাকা"

                    PrayerTimesWidget.updatePrayerTimes(
                        this@MainActivity,
                        fajr, dhuhr, asr, maghrib, isha, location
                    )
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
