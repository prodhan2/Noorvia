package com.butterflydevs.noorvia

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.view.View
import android.widget.RemoteViews

class RamadanWidget : AppWidgetProvider() {
    companion object {
        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            manager.getAppWidgetIds(ComponentName(context, RamadanWidget::class.java)).forEach {
                update(context, manager, it)
            }
        }

        private fun update(context: Context, manager: AppWidgetManager, id: Int) {
            val p = context.getSharedPreferences(WidgetDataStore.PREFS, Context.MODE_PRIVATE)
            val (isRamadan, day) = WidgetDataStore.resolveRamadanDay(context)
            val views = RemoteViews(context.packageName, R.layout.widget_ramadan)
            views.setTextViewText(
                R.id.widget_ramadan_title,
                if (isRamadan && day.isNotEmpty()) {
                    NativeLanguage.text(context, "রমজান • $day", "Ramadan • $day")
                } else {
                    NativeLanguage.text(context, "রমজান প্রস্তুতি", "Ramadan Ready")
                },
            )
            views.setTextViewText(R.id.widget_ramadan_status, NativeLanguage.text(context, "অফলাইন সময় প্রস্তুত থাকবে", "Offline times stay available"))
            views.setTextViewText(R.id.widget_sehri_label, NativeLanguage.text(context, "সেহরি শেষ", "Sehri ends"))
            views.setTextViewText(R.id.widget_iftar_label, NativeLanguage.text(context, "ইফতার", "Iftar"))
            views.setTextViewText(R.id.widget_sehri_time, p.getString(WidgetDataStore.FAJR, "--:--"))
            views.setTextViewText(R.id.widget_iftar_time, p.getString(WidgetDataStore.MAGHRIB, "--:--"))
            views.setTextViewText(R.id.widget_ramadan_location, NativeLanguage.location(context, p.getString(WidgetDataStore.LOCATION, NativeLanguage.text(context, "📍 ঢাকা", "📍 Dhaka")) ?: NativeLanguage.text(context, "📍 ঢাকা", "📍 Dhaka")))
            views.setViewVisibility(R.id.widget_ramadan_status, if (isRamadan) View.GONE else View.VISIBLE)
            views.setOnClickPendingIntent(R.id.widget_ramadan_root, openAppIntent(context))
            manager.updateAppWidget(id, views)
        }
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { update(context, manager, it) }
    }
}
