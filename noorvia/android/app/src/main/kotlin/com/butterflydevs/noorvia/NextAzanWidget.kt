package com.butterflydevs.noorvia

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews

class NextAzanWidget : AppWidgetProvider() {
    companion object {
        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            manager.getAppWidgetIds(ComponentName(context, NextAzanWidget::class.java)).forEach {
                update(context, manager, it)
            }
        }

        private fun update(context: Context, manager: AppWidgetManager, id: Int) {
            val p = context.getSharedPreferences(WidgetDataStore.PREFS, Context.MODE_PRIVATE)
            val next = WidgetDataStore.resolveNextPrayerInfo(context)
            val views = RemoteViews(context.packageName, R.layout.widget_next_azan)
            views.setTextViewText(R.id.widget_next_title, NativeLanguage.text(context, "পরবর্তী আযান", "Next Azan"))
            views.setTextViewText(R.id.widget_next_name, next.name)
            views.setTextViewText(R.id.widget_next_time, next.displayTime)
            val remaining = (next.targetMillis - System.currentTimeMillis()).coerceAtLeast(0L)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                views.setChronometer(
                    R.id.widget_next_countdown,
                    SystemClock.elapsedRealtime() + remaining,
                    NativeLanguage.text(context, "বাকি %s", "%s remaining"),
                    true,
                )
                views.setChronometerCountDown(R.id.widget_next_countdown, true)
            } else {
                val hours = remaining / 3_600_000L
                val minutes = (remaining % 3_600_000L) / 60_000L
                views.setTextViewText(
                    R.id.widget_next_countdown,
                    if (NativeLanguage.isEnglish(context)) {
                        "${hours}h ${minutes}m remaining"
                    } else {
                        "বাকি ${NativeLanguage.digits(context, hours.toString())}ঘ ${NativeLanguage.digits(context, minutes.toString())}মি"
                    },
                )
            }
            views.setTextViewText(R.id.widget_next_location, NativeLanguage.location(context, p.getString(WidgetDataStore.LOCATION, NativeLanguage.text(context, "📍 ঢাকা", "📍 Dhaka")) ?: NativeLanguage.text(context, "📍 ঢাকা", "📍 Dhaka")))
            views.setOnClickPendingIntent(R.id.widget_next_root, openAppIntent(context))
            manager.updateAppWidget(id, views)
        }
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { update(context, manager, it) }
    }
}
