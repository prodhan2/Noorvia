package com.butterflydevs.noorvia

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.butterflydevs.noorvia/prayer_alarm"
    private lateinit var alarmManager: PrayerAlarmManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        alarmManager = PrayerAlarmManager(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val args = call.arguments as? Map<*, *>
                    val scheduled = alarmManager.scheduleAlarm(
                        prayerId = args?.get("prayerId") as? Int ?: -1,
                        prayerName = args?.get("prayerName") as? String ?: "",
                        hour = args?.get("hour") as? Int ?: 0,
                        minute = args?.get("minute") as? Int ?: 0,
                        preAlarmMinutes = args?.get("preAlarmMinutes") as? Int ?: 0,
                        vibrationEnabled = args?.get("vibrationEnabled") as? Boolean ?: true,
                        volume = (args?.get("volume") as? Double)?.toFloat() ?: 1.0f,
                    )
                    result.success(scheduled)
                }
                "cancelAlarm" -> {
                    val args = call.arguments as? Map<*, *>
                    alarmManager.cancelAlarm(args?.get("prayerId") as? Int ?: -1)
                    result.success(true)
                }
                "cancelAllAlarms" -> {
                    alarmManager.cancelAllAlarms()
                    result.success(true)
                }
                "getScheduledAlarms" -> result.success(alarmManager.getScheduledAlarms())
                "updateWidget" -> {
                    val args = call.arguments as? Map<*, *>
                    WidgetDataStore.save(
                        context = this,
                        fajr = args?.get("fajr") as? String ?: "--:--",
                        dhuhr = args?.get("dhuhr") as? String ?: "--:--",
                        asr = args?.get("asr") as? String ?: "--:--",
                        maghrib = args?.get("maghrib") as? String ?: "--:--",
                        isha = args?.get("isha") as? String ?: "--:--",
                        location = args?.get("location") as? String ?: "📍 ঢাকা",
                        nextPrayer = args?.get("nextPrayer") as? String ?: "ফজর",
                        nextPrayerTime = args?.get("nextPrayerTime") as? String ?: "--:--",
                        ramadanDay = args?.get("ramadanDay") as? String ?: "",
                        isRamadan = args?.get("isRamadan") as? Boolean ?: false,
                    )
                    PrayerTimesWidget.updateAllWidgets(this)
                    NextAzanWidget.updateAllWidgets(this)
                    RamadanWidget.updateAllWidgets(this)
                    result.success(true)
                }
                "requestPinWidget" -> {
                    val args = call.arguments as? Map<*, *>
                    result.success(requestPinWidget(args?.get("type") as? String ?: "prayer"))
                }
                "setAppLanguage" -> {
                    val args = call.arguments as? Map<*, *>
                    NativeLanguage.set(this, args?.get("language") as? String ?: "bn")
                    PrayerTimesWidget.updateAllWidgets(this)
                    NextAzanWidget.updateAllWidgets(this)
                    RamadanWidget.updateAllWidgets(this)
                    result.success(true)
                }
                "saveSmartSalahSettings" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                    SmartSalahManager(this).saveSettings(args)
                    // Re-evaluate Smart Salah windows for every already enabled prayer alarm.
                    alarmManager.getScheduledAlarms().keys.forEach { alarmManager.rescheduleSingleAlarm(it) }
                    result.success(SmartSalahManager(this).getSettings())
                }
                "getSmartSalahSettings" -> result.success(SmartSalahManager(this).getSettings())
                "hasNotificationPolicyAccess" -> result.success(SmartSalahManager(this).hasNotificationPolicyAccess())
                "openNotificationPolicyAccess" -> {
                    startActivity(SmartSalahManager.settingsIntent())
                    result.success(true)
                }
                "setMosqueGeofences" -> {
                    val args = call.arguments as? Map<*, *>
                    val mosques = (args?.get("mosques") as? List<*>)
                        ?.mapNotNull { it as? Map<*, *> } ?: emptyList()
                    val radius = (args?.get("radius") as? Number)?.toInt() ?: 150
                    MosqueGeofenceManager(this).register(mosques, radius) { ok, error ->
                        runOnUiThread {
                            if (ok) result.success(mapOf("ok" to true))
                            else result.success(mapOf("ok" to false, "error" to (error ?: "unknown")))
                        }
                    }
                }
                "clearMosqueGeofences" -> {
                    MosqueGeofenceManager(this).clear { ok ->
                        runOnUiThread { result.success(ok) }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestPinWidget(type: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        val manager = AppWidgetManager.getInstance(this)
        if (!manager.isRequestPinAppWidgetSupported) return false

        val providerClass = when (type) {
            "azan" -> NextAzanWidget::class.java
            "ramadan" -> RamadanWidget::class.java
            else -> PrayerTimesWidget::class.java
        }
        return manager.requestPinAppWidget(ComponentName(this, providerClass), null, null)
    }
}
