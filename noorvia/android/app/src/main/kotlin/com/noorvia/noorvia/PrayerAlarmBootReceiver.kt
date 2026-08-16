package com.noorvia.noorvia

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class PrayerAlarmBootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "PrayerAlarmBootReceiver"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        Log.d(TAG, "Boot received: ${intent?.action}")
        
        if (context == null) return

        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON" -> {
                val alarmManager = PrayerAlarmManager(context)
                alarmManager.rescheduleAlarmsAfterReboot()
            }
        }
    }
}
