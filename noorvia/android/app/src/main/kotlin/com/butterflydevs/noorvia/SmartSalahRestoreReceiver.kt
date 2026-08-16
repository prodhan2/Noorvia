package com.butterflydevs.noorvia

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class SmartSalahRestoreReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null) return
        SmartSalahManager(context).restore(intent?.getStringExtra("session"))
    }
}
