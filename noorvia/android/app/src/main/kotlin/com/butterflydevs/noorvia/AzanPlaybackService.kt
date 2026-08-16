package com.butterflydevs.noorvia

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import androidx.core.content.ContextCompat
import androidx.core.app.NotificationCompat
import io.flutter.FlutterInjector

/**
 * Foreground playback keeps the Azan alive after BroadcastReceiver.onReceive()
 * returns and while the phone is locked/dozing.
 */
class AzanPlaybackService : Service() {
    companion object {
        private const val CHANNEL_ID = "azan_playback_channel"
        private const val NOTIFICATION_ID = 9101
        private const val ACTION_START = "com.butterflydevs.noorvia.action.PLAY_AZAN"
        private const val ACTION_STOP = "com.butterflydevs.noorvia.action.STOP_AZAN"
        private const val EXTRA_VOLUME = "volume"

        fun start(context: Context, volume: Float) {
            val intent = Intent(context, AzanPlaybackService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_VOLUME, volume)
            }
            ContextCompat.startForegroundService(context, intent)
        }
    }

    private var mediaPlayer: MediaPlayer? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopPlayback()
            return START_NOT_STICKY
        }

        createChannel()
        val stopIntent = Intent(this, AzanPlaybackService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = android.app.PendingIntent.getService(
            this,
            99,
            stopIntent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(NativeLanguage.text(this, "আযান চলছে", "Azan is playing"))
            .setContentText(NativeLanguage.text(this, "নামাজের সময় হয়েছে", "It is prayer time"))
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setOngoing(true)
            .addAction(0, NativeLanguage.text(this, "বন্ধ করুন", "Stop"), stopPendingIntent)
            .build()

        startForeground(NOTIFICATION_ID, notification)
        play(intent?.getFloatExtra(EXTRA_VOLUME, 1.0f) ?: 1.0f)
        return START_NOT_STICKY
    }

    private fun play(volume: Float) {
        try {
            mediaPlayer?.release()
            val assetKey = FlutterInjector.instance()
                .flutterLoader()
                .getLookupKeyForAsset("assets/audio/azan.mp3")
            val afd = assets.openFd(assetKey)
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build(),
                )
                setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                afd.close()
                setVolume(volume.coerceIn(0f, 1f), volume.coerceIn(0f, 1f))
                setOnCompletionListener { stopPlayback() }
                setOnErrorListener { _, _, _ ->
                    stopPlayback()
                    true
                }
                prepare()
                start()
            }
        } catch (_: Exception) {
            stopPlayback()
        }
    }

    private fun stopPlayback() {
        try {
            mediaPlayer?.stop()
        } catch (_: Exception) {
        }
        mediaPlayer?.release()
        mediaPlayer = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                NativeLanguage.text(this, "আযান প্লেব্যাক", "Azan Playback"),
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = NativeLanguage.text(this@AzanPlaybackService, "নামাজের সময় আযান চালানোর জন্য", "Plays Azan at prayer time")
                setSound(null, null)
            }
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        mediaPlayer?.release()
        mediaPlayer = null
        super.onDestroy()
    }
}
