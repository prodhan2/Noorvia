package com.butterflydevs.noorvia

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class SmartSalahStartReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return
        SmartSalahManager(context).apply(
            prayerId = intent.getIntExtra("prayerId", -1),
            prayerTimeMillis = intent.getLongExtra("prayerTimeMillis", System.currentTimeMillis()),
        )
    }
}
