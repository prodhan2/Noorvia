package com.butterflydevs.noorvia

import android.Manifest
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices

class MosqueGeofenceManager(private val context: Context) {
    private val client = LocationServices.getGeofencingClient(context)
    private val pendingIntent: PendingIntent by lazy {
        PendingIntent.getBroadcast(
            context,
            9100,
            Intent(context, MosqueGeofenceReceiver::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
        )
    }

    fun register(mosques: List<Map<*, *>>, radiusMeters: Int, callback: (Boolean, String?) -> Unit) {
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            callback(false, "location_permission")
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
            ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_BACKGROUND_LOCATION) != PackageManager.PERMISSION_GRANTED
        ) {
            callback(false, "background_location_permission")
            return
        }

        val radius = radiusMeters.coerceIn(100, 1000).toFloat()
        val geofences = mosques.take(50).mapIndexedNotNull { index, map ->
            val lat = (map["latitude"] as? Number)?.toDouble() ?: return@mapIndexedNotNull null
            val lon = (map["longitude"] as? Number)?.toDouble() ?: return@mapIndexedNotNull null
            val rawId = map["id"]?.toString() ?: "mosque_$index"
            Geofence.Builder()
                .setRequestId(rawId.take(80))
                .setCircularRegion(lat, lon, radius)
                .setExpirationDuration(Geofence.NEVER_EXPIRE)
                .setTransitionTypes(
                    Geofence.GEOFENCE_TRANSITION_ENTER or
                        Geofence.GEOFENCE_TRANSITION_DWELL or
                        Geofence.GEOFENCE_TRANSITION_EXIT,
                )
                .setLoiteringDelay(120_000)
                .setNotificationResponsiveness(120_000)
                .build()
        }
        if (geofences.isEmpty()) {
            callback(false, "no_mosques")
            return
        }

        val request = GeofencingRequest.Builder()
            .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_DWELL or GeofencingRequest.INITIAL_TRIGGER_ENTER)
            .addGeofences(geofences)
            .build()

        client.removeGeofences(pendingIntent).addOnCompleteListener {
            SmartSalahManager(context).clearActiveGeofences()
            try {
                client.addGeofences(request, pendingIntent)
                    .addOnSuccessListener { callback(true, null) }
                    .addOnFailureListener { callback(false, it.message) }
            } catch (e: SecurityException) {
                callback(false, e.message)
            }
        }
    }

    fun clear(callback: (Boolean) -> Unit = {}) {
        client.removeGeofences(pendingIntent).addOnCompleteListener {
            SmartSalahManager(context).clearActiveGeofences()
            callback(it.isSuccessful)
        }
    }
}
