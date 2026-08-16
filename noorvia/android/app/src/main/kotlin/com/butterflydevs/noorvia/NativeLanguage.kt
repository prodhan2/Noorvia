package com.butterflydevs.noorvia

import android.content.Context

/** Lightweight native localization for alarms, foreground notifications and widgets. */
object NativeLanguage {
    private const val PREFS = "noorvia_native_settings"
    private const val KEY_LANGUAGE = "language"

    fun set(context: Context, languageCode: String) {
        val value = if (languageCode.lowercase().startsWith("en")) "en" else "bn"
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString(KEY_LANGUAGE, value).apply()
    }

    fun code(context: Context): String =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_LANGUAGE, "bn") ?: "bn"

    fun isEnglish(context: Context): Boolean = code(context) == "en"

    fun text(context: Context, bangla: String, english: String): String =
        if (isEnglish(context)) english else bangla

    fun prayerName(context: Context, raw: String): String {
        if (!isEnglish(context)) return raw
        return when (raw.trim()) {
            "ফজর" -> "Fajr"
            "যোহর", "জোহর" -> "Dhuhr"
            "আসর" -> "Asr"
            "মাগরিব" -> "Maghrib"
            "এশা", "ইশা" -> "Isha"
            "জুমা", "জুম্মা" -> "Jumu'ah"
            "নামাজ", "নামায" -> "Salah"
            else -> raw
        }
    }


    fun location(context: Context, raw: String): String {
        if (!isEnglish(context)) return raw
        val names = linkedMapOf(
            "ঢাকা" to "Dhaka", "চট্টগ্রাম" to "Chattogram", "সিলেট" to "Sylhet",
            "রাজশাহী" to "Rajshahi", "খুলনা" to "Khulna", "বরিশাল" to "Barishal",
            "রংপুর" to "Rangpur", "ময়মনসিংহ" to "Mymensingh", "কুমিল্লা" to "Cumilla",
            "নারায়ণগঞ্জ" to "Narayanganj", "গাজীপুর" to "Gazipur", "বগুড়া" to "Bogura",
            "দিনাজপুর" to "Dinajpur", "কক্সবাজার" to "Cox's Bazar", "মক্কা" to "Makkah",
            "মদিনা" to "Madinah", "রিয়াদ" to "Riyadh", "দুবাই" to "Dubai",
            "লন্ডন" to "London", "নিউ ইয়র্ক" to "New York", "কুয়ালালামপুর" to "Kuala Lumpur",
            "জাকার্তা" to "Jakarta", "ইস্তাম্বুল" to "Istanbul", "কায়রো" to "Cairo",
            "করাচি" to "Karachi", "লাহোর" to "Lahore", "দিল্লি" to "Delhi", "কলকাতা" to "Kolkata",
        )
        var out = raw
        names.forEach { (bn, en) -> out = out.replace(bn, en) }
        return out
    }

    fun digits(context: Context, value: String): String {
        if (isEnglish(context)) return value
        val bn = charArrayOf('০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯')
        return buildString {
            value.forEach { ch -> append(if (ch in '0'..'9') bn[ch - '0'] else ch) }
        }
    }
}
