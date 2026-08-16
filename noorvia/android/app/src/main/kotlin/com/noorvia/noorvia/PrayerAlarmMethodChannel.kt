package com.noorvia.noorvia

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class PrayerAlarmMethodChannel : FlutterPlugin, MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL_NAME = "com.noorvia.noorvia/prayer_alarm"
    }

    private lateinit var channel: MethodChannel
    private lateinit var alarmManager: PrayerAlarmManager
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        alarmManager = PrayerAlarmManager(context)
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
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
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
