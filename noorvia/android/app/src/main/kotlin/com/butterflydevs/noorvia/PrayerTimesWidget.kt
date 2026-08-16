package com.butterflydevs.noorvia

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class PrayerTimesWidget : AppWidgetProvider() {
    companion object {
        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            manager.getAppWidgetIds(ComponentName(context, PrayerTimesWidget::class.java))
                .forEach { updateAppWidget(context, manager, it) }
        }
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { updateAppWidget(context, manager, it) }
    }
}

private fun updateAppWidget(context: Context, manager: AppWidgetManager, id: Int) {
    val p = context.getSharedPreferences(WidgetDataStore.PREFS, Context.MODE_PRIVATE)
    val views = RemoteViews(context.packageName, R.layout.widget_prayer_times)
    views.setTextViewText(R.id.widget_title, NativeLanguage.text(context, "🕌 নামাজের সময়", "🕌 Prayer Times"))
    views.setTextViewText(R.id.widget_fajr_label, NativeLanguage.text(context, "ফজর", "Fajr"))
    views.setTextViewText(R.id.widget_dhuhr_label, NativeLanguage.text(context, "যোহর", "Dhuhr"))
    views.setTextViewText(R.id.widget_asr_label, NativeLanguage.text(context, "আসর", "Asr"))
    views.setTextViewText(R.id.widget_maghrib_label, NativeLanguage.text(context, "মাগরিব", "Maghrib"))
    views.setTextViewText(R.id.widget_isha_label, NativeLanguage.text(context, "ইশা", "Isha"))
    views.setTextViewText(R.id.widget_fajr_time, p.getString(WidgetDataStore.FAJR, "--:--"))
    views.setTextViewText(R.id.widget_dhuhr_time, p.getString(WidgetDataStore.DHUHR, "--:--"))
    views.setTextViewText(R.id.widget_asr_time, p.getString(WidgetDataStore.ASR, "--:--"))
    views.setTextViewText(R.id.widget_maghrib_time, p.getString(WidgetDataStore.MAGHRIB, "--:--"))
    views.setTextViewText(R.id.widget_isha_time, p.getString(WidgetDataStore.ISHA, "--:--"))
    views.setTextViewText(R.id.widget_location, NativeLanguage.location(context, p.getString(WidgetDataStore.LOCATION, NativeLanguage.text(context, "📍 ঢাকা", "📍 Dhaka")) ?: NativeLanguage.text(context, "📍 ঢাকা", "📍 Dhaka")))
    views.setOnClickPendingIntent(R.id.widget_title, openAppIntent(context))
    manager.updateAppWidget(id, views)
}

internal fun openAppIntent(context: Context): PendingIntent = PendingIntent.getActivity(
    context,
    0,
    Intent(context, MainActivity::class.java),
    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
)
