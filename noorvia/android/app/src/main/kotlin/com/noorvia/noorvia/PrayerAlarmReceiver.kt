package com.noorvia.noorvia

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.butterflydevs.noorvia.MainActivity
import com.butterflydevs.noorvia.R


class PrayerAlarmReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "PrayerAlarmReceiver"
        const val CHANNEL_ID = "prayer_alarm_channel"
        const val NOTIFICATION_ID_BASE = 500
    }

    private var mediaPlayer: MediaPlayer? = null

    override fun onReceive(context: Context?, intent: Intent?) {
        Log.d(TAG, "Alarm received!")
        
        if (context == null || intent == null) return

        val prayerId = intent.getIntExtra("prayerId", -1)
        val prayerName = intent.getStringExtra("prayerName") ?: "নামাজ"
        val preAlarmMinutes = intent.getIntExtra("preAlarmMinutes", 0)
        val vibrationEnabled = intent.getBooleanExtra("vibrationEnabled", true)
        val volume = intent.getFloatExtra("volume", 1.0f)

        // Show notification
        showNotification(context, prayerId, prayerName, preAlarmMinutes)

        // Play azan audio
        playAzan(context, volume)

        // Vibrate if enabled
        if (vibrationEnabled) {
            vibrate(context)
        }
    }

    private fun showNotification(
        context: Context,
        prayerId: Int,
        prayerName: String,
        preAlarmMinutes: Int
    ) {
        createNotificationChannel(context)

        val contentText = if (preAlarmMinutes > 0) {
            "$preAlarmMinutes মিনিট পরে $prayerName নামাজের সময় হবে"
        } else {
            "$prayerName নামাজের সময় হয়েছে"
        }

        val notificationIntent = Intent(context, MainActivity::class.java)
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        
        val pendingIntent = PendingIntent.getActivity(
            context,
            prayerId,
            notificationIntent,
            flags
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setLargeIcon(
                BitmapFactory.decodeResource(context.resources, R.mipmap.ic_launcher)
            )
            .setContentTitle("🕌 $prayerName নামাজ")
            .setContentText(contentText)
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText(if (preAlarmMinutes > 0) 
                        "$preAlarmMinutes মিনিট পরে $prayerName নামাজের সময় হবে। প্রস্তুতি নিন।" 
                    else 
                        "$prayerName নামাজের সময় হয়েছে। এখনই নামাজ পড়ুন।"
                    )
                    .setBigContentTitle("🕌 $prayerName নামাজের সময়")
                    .setSummaryText("মুসলিম ভিউ - ইসলামিক অ্যাপ")
            )
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setOngoing(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setDefaults(Notification.DEFAULT_LIGHTS)
            .build()

        try {
            NotificationManagerCompat.from(context)
                .notify(NOTIFICATION_ID_BASE + prayerId, notification)
            Log.d(TAG, "Notification shown for $prayerName")
        } catch (e: Exception) {
            Log.e(TAG, "Error showing notification", e)
        }
    }

    private fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "নামাজের আযান"
            val descriptionText = "নামাজের সময় আযান বাজানোর জন্য"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                enableVibration(true)
                enableLights(true)
            }

            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun playAzan(context: Context, volume: Float) {
        try {
            mediaPlayer?.release()
            
            mediaPlayer = MediaPlayer().apply {
                val audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
                
                setAudioAttributes(audioAttributes)
                
                // Try to load from assets
                try {
                    val assetFileDescriptor = context.assets.openFd("audio/azan.mp3")
                    setDataSource(
                        assetFileDescriptor.fileDescriptor,
                        assetFileDescriptor.startOffset,
                        assetFileDescriptor.length
                    )
                    assetFileDescriptor.close()
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to load from assets, trying raw resource", e)
                    // Fallback to raw resource if available
                    val resId = context.resources.getIdentifier("azan", "raw", context.packageName)
                    if (resId != 0) {
                        val uri = Uri.parse("android.resource://${context.packageName}/$resId")
                        setDataSource(context, uri)
                    }
                }

                setVolume(volume, volume)
                prepare()
                start()
                
                Log.d(TAG, "Azan playing at volume: $volume")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error playing azan", e)
        }
    }

    private fun vibrate(context: Context) {
        try {
            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vibratorManager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val effect = VibrationEffect.createWaveform(
                    longArrayOf(0, 500, 200, 500, 200, 500),
                    -1
                )
                vibrator.vibrate(effect)
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(longArrayOf(0, 500, 200, 500, 200, 500), -1)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error vibrating", e)
        }
    }
}
