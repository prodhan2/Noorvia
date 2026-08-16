package com.butterflydevs.noorvia

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingEvent

class MosqueGeofenceReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return
        val event = GeofencingEvent.fromIntent(intent) ?: return
        if (event.hasError()) return
        val manager = SmartSalahManager(context)
        val ids = event.triggeringGeofences?.map { it.requestId }.orEmpty()
        when (event.geofenceTransition) {
            Geofence.GEOFENCE_TRANSITION_ENTER,
            Geofence.GEOFENCE_TRANSITION_DWELL -> ids.forEach { manager.setActiveGeofence(it, true) }
            Geofence.GEOFENCE_TRANSITION_EXIT -> ids.forEach { manager.setActiveGeofence(it, false) }
        }
    }
}
