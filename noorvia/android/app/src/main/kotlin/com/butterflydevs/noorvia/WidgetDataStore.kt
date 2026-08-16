package com.butterflydevs.noorvia

import android.content.Context
import java.util.Calendar
import java.time.Instant
import java.time.ZoneId

object WidgetDataStore {
    const val PREFS = "noorvia_home_widget_prefs"
    const val FAJR = "fajr"
    const val DHUHR = "dhuhr"
    const val ASR = "asr"
    const val MAGHRIB = "maghrib"
    const val ISHA = "isha"
    const val LOCATION = "location"
    const val NEXT_PRAYER = "next_prayer"
    const val NEXT_PRAYER_TIME = "next_prayer_time"
    const val RAMADAN_DAY = "ramadan_day"
    const val IS_RAMADAN = "is_ramadan"
    private const val RAMADAN_SAVED_AT = "ramadan_saved_at"

    fun save(
        context: Context,
        fajr: String,
        dhuhr: String,
        asr: String,
        maghrib: String,
        isha: String,
        location: String,
        nextPrayer: String,
        nextPrayerTime: String,
        ramadanDay: String,
        isRamadan: Boolean,
    ) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(FAJR, fajr)
            .putString(DHUHR, dhuhr)
            .putString(ASR, asr)
            .putString(MAGHRIB, maghrib)
            .putString(ISHA, isha)
            .putString(LOCATION, location)
            .putString(NEXT_PRAYER, nextPrayer)
            .putString(NEXT_PRAYER_TIME, nextPrayerTime)
            .putString(RAMADAN_DAY, ramadanDay)
            .putBoolean(IS_RAMADAN, isRamadan)
            .putLong(RAMADAN_SAVED_AT, System.currentTimeMillis())
            .apply()
    }

    /**
     * Re-evaluate the next prayer from the five stored clock times whenever
     * Android refreshes the widget. This prevents the "next Azan" card from
     * staying stuck on the prayer that was next when the Flutter app closed.
     */
    data class NextPrayerInfo(
        val name: String,
        val displayTime: String,
        val targetMillis: Long,
    )

    fun resolveNextPrayer(context: Context): Pair<String, String> {
        val next = resolveNextPrayerInfo(context)
        return next.name to next.displayTime
    }

    fun resolveNextPrayerInfo(context: Context): NextPrayerInfo {
        val p = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val prayers = listOf(
            NativeLanguage.text(context, "ফজর", "Fajr") to (p.getString(FAJR, "--:--") ?: "--:--"),
            NativeLanguage.text(context, "যোহর", "Dhuhr") to (p.getString(DHUHR, "--:--") ?: "--:--"),
            NativeLanguage.text(context, "আসর", "Asr") to (p.getString(ASR, "--:--") ?: "--:--"),
            NativeLanguage.text(context, "মাগরিব", "Maghrib") to (p.getString(MAGHRIB, "--:--") ?: "--:--"),
            NativeLanguage.text(context, "ইশা", "Isha") to (p.getString(ISHA, "--:--") ?: "--:--"),
        )
        val now = Calendar.getInstance()
        val nowMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        val valid = prayers.mapNotNull { (name, time) ->
            toMinutes(time)?.let { minutes -> Triple(name, time, minutes) }
        }
        if (valid.isEmpty()) {
            return NextPrayerInfo(
                name = NativeLanguage.prayerName(context, p.getString(NEXT_PRAYER, "ফজর") ?: "ফজর"),
                displayTime = formatDisplayTime(context, p.getString(NEXT_PRAYER_TIME, "--:--") ?: "--:--"),
                targetMillis = System.currentTimeMillis() + 60 * 60 * 1000L,
            )
        }

        val next = valid.firstOrNull { it.third > nowMinutes } ?: valid.first()
        val target = Calendar.getInstance().apply {
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            set(Calendar.HOUR_OF_DAY, next.third / 60)
            set(Calendar.MINUTE, next.third % 60)
            if (next.third <= nowMinutes) add(Calendar.DAY_OF_YEAR, 1)
        }
        return NextPrayerInfo(next.first, formatDisplayTime(context, next.second), target.timeInMillis)
    }

    /**
     * Keep the Ramadan day label useful across midnight even if the app was
     * not opened. The stored Hijri day is advanced by elapsed local dates and
     * automatically leaves Ramadan after day 30.
     */
    fun resolveRamadanDay(context: Context): Pair<Boolean, String> {
        val p = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!p.getBoolean(IS_RAMADAN, false)) return false to ""
        val rawDay = p.getString(RAMADAN_DAY, "")?.toIntOrNull() ?: return true to ""
        val savedAt = p.getLong(RAMADAN_SAVED_AT, System.currentTimeMillis())
        val elapsedDays = (daySerial(System.currentTimeMillis()) - daySerial(savedAt))
            .coerceAtLeast(0L)
            .toInt()
        val day = rawDay + elapsedDays
        return if (day in 1..30) true to NativeLanguage.digits(context, day.toString()) else false to ""
    }

    private fun daySerial(ms: Long): Long =
        Instant.ofEpochMilli(ms).atZone(ZoneId.systemDefault()).toLocalDate().toEpochDay()

    private fun toMinutes(value: String): Int? {
        val clean = value.trim().split(" ").firstOrNull() ?: return null
        val parts = clean.split(":")
        if (parts.size < 2) return null
        val hour = parts[0].toIntOrNull() ?: return null
        val minute = parts[1].take(2).toIntOrNull() ?: return null
        return hour * 60 + minute
    }

    private fun formatDisplayTime(context: Context, value: String): String {
        val minutes = toMinutes(value) ?: return value
        val h24 = minutes / 60
        val minute = minutes % 60
        val h12 = when {
            h24 == 0 -> 12
            h24 > 12 -> h24 - 12
            else -> h24
        }
        val suffix = if (h24 >= 12) "PM" else "AM"
        return "${NativeLanguage.digits(context, h12.toString())}:${NativeLanguage.digits(context, minute.toString().padStart(2, '0'))} $suffix"
    }

}
