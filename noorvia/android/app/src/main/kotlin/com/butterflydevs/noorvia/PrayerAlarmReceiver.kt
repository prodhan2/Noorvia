package com.butterflydevs.noorvia

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class PrayerAlarmReceiver : BroadcastReceiver() {
    companion object {
        const val CHANNEL_ID = "prayer_alarm_channel"
        const val NOTIFICATION_ID_BASE = 500
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return

        val prayerId = intent.getIntExtra("prayerId", -1)
        val rawPrayerName = intent.getStringExtra("prayerName") ?: "নামাজ"
        val prayerName = NativeLanguage.prayerName(context, rawPrayerName)
        val preAlarmMinutes = intent.getIntExtra("preAlarmMinutes", 0)
        val isPreAlarm = intent.getBooleanExtra("isPreAlarm", false)
        val vibrationEnabled = intent.getBooleanExtra("vibrationEnabled", true)
        val volume = intent.getFloatExtra("volume", 1.0f)

        showNotification(context, prayerId, prayerName, preAlarmMinutes, isPreAlarm)

        if (!isPreAlarm) {
            // Actual prayer time: play full Azan reliably in a foreground service.
            AzanPlaybackService.start(context, volume)
            if (vibrationEnabled) vibrate(context)
            NextAzanWidget.updateAllWidgets(context)

            // Safety fallback for users who don't open the app every day.
            // Fresh app/API sync will replace this with the new day's exact time.
            PrayerAlarmManager(context).rescheduleSingleAlarm(prayerId)
        }
    }

    private fun showNotification(
        context: Context,
        prayerId: Int,
        prayerName: String,
        preAlarmMinutes: Int,
        isPreAlarm: Boolean,
    ) {
        createNotificationChannel(context)
        val contentText = if (isPreAlarm) {
            if (NativeLanguage.isEnglish(context)) {
                "$prayerName prayer time is in $preAlarmMinutes minutes"
            } else {
                "$preAlarmMinutes মিনিট পরে $prayerName নামাজের সময় হবে"
            }
        } else {
            if (NativeLanguage.isEnglish(context)) {
                "It is time for $prayerName prayer"
            } else {
                "$prayerName নামাজের সময় হয়েছে"
            }
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            prayerId,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(
                if (isPreAlarm) NativeLanguage.text(context, "🕌 নামাজের রিমাইন্ডার", "🕌 Prayer Reminder")
                else if (NativeLanguage.isEnglish(context)) "🕌 $prayerName Prayer" else "🕌 $prayerName নামাজ"
            )
            .setContentText(contentText)
            .setStyle(NotificationCompat.BigTextStyle().bigText(contentText))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()

        try {
            NotificationManagerCompat.from(context)
                .notify(NOTIFICATION_ID_BASE + prayerId + if (isPreAlarm) 1000 else 0, notification)
        } catch (_: SecurityException) {
        }
    }

    private fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                NativeLanguage.text(context, "নামাজের আযান ও রিমাইন্ডার", "Prayer Azan & Reminders"),
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = NativeLanguage.text(context, "নামাজের সময় আযান ও আগে রিমাইন্ডার", "Azan at prayer time with pre-prayer reminders")
                enableVibration(true)
            }
            (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(channel)
        }
    }

    private fun vibrate(context: Context) {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 500, 200, 500), -1))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(longArrayOf(0, 500, 200, 500), -1)
        }
    }
}
