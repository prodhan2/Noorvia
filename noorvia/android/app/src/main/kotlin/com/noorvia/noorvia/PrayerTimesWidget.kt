package com.noorvia.noorvia

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.butterflydevs.noorvia.MainActivity
import com.butterflydevs.noorvia.R

class PrayerTimesWidget : AppWidgetProvider() {

    companion object {
        const val PREFS_NAME = "prayer_widget_prefs"
        const val KEY_FAJR = "fajr_time"
        const val KEY_DHUHR = "dhuhr_time"
        const val KEY_ASR = "asr_time"
        const val KEY_MAGHRIB = "maghrib_time"
        const val KEY_ISHA = "isha_time"
        const val KEY_LOCATION = "location_name"

        fun updatePrayerTimes(
            context: Context,
            fajr: String,
            dhuhr: String,
            asr: String,
            maghrib: String,
            isha: String,
            location: String
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().apply {
                putString(KEY_FAJR, fajr)
                putString(KEY_DHUHR, dhuhr)
                putString(KEY_ASR, asr)
                putString(KEY_MAGHRIB, maghrib)
                putString(KEY_ISHA, isha)
                putString(KEY_LOCATION, location)
                apply()
            }

            updateAllWidgets(context)
        }

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, PrayerTimesWidget::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            
            appWidgetIds.forEach { appWidgetId ->
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { appWidgetId ->
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        updateAllWidgets(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        super.onReceive(context, intent)
        context?.let { updateAllWidgets(it) }
    }
}

internal fun updateAppWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int
) {
    val prefs = context.getSharedPreferences(PrayerTimesWidget.PREFS_NAME, Context.MODE_PRIVATE)
    
    val fajr = prefs.getString(PrayerTimesWidget.KEY_FAJR, "05:30") ?: "05:30"
    val dhuhr = prefs.getString(PrayerTimesWidget.KEY_DHUHR, "12:15") ?: "12:15"
    val asr = prefs.getString(PrayerTimesWidget.KEY_ASR, "15:45") ?: "15:45"
    val maghrib = prefs.getString(PrayerTimesWidget.KEY_MAGHRIB, "18:30") ?: "18:30"
    val isha = prefs.getString(PrayerTimesWidget.KEY_ISHA, "19:45") ?: "19:45"
    val location = prefs.getString(PrayerTimesWidget.KEY_LOCATION, "📍 ঢাকা") ?: "📍 ঢাকা"

    val views = RemoteViews(context.packageName, R.layout.widget_prayer_times)
    
    views.setTextViewText(R.id.widget_fajr_time, fajr)
    views.setTextViewText(R.id.widget_dhuhr_time, dhuhr)
    views.setTextViewText(R.id.widget_asr_time, asr)
    views.setTextViewText(R.id.widget_maghrib_time, maghrib)
    views.setTextViewText(R.id.widget_isha_time, isha)
    views.setTextViewText(R.id.widget_location, location)

    val intent = Intent(context, MainActivity::class.java)
    val pendingIntent = PendingIntent.getActivity(
        context,
        0,
        intent,
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
    )
    views.setOnClickPendingIntent(R.id.widget_title, pendingIntent)

    appWidgetManager.updateAppWidget(appWidgetId, views)
}
