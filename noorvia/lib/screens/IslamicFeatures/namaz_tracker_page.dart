import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/prayer_provider.dart';

// ─── Model ────────────────────────────────────────────────────
class DayPrayerRecord {
  final String date; // yyyy-MM-dd
  Map<String, PrayerStatus> prayers;

  DayPrayerRecord({required this.date, required this.prayers});

  factory DayPrayerRecord.empty(String date) => DayPrayerRecord(
        date: date,
        prayers: {
          'ফজর': PrayerStatus.none,
          'যোহর': PrayerStatus.none,
          'আসর': PrayerStatus.none,
          'মাগরিব': PrayerStatus.none,
          'ইশা': PrayerStatus.none,
        },
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'prayers': prayers.map((k, v) => MapEntry(k, v.index)),
      };

  factory DayPrayerRecord.fromJson(Map<String, dynamic> json) {
    final p = (json['prayers'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, PrayerStatus.values[v as int]),
    );
    return DayPrayerRecord(date: json['date'], prayers: p);
  }

  int get completedCount =>
      prayers.values.where((s) => s == PrayerStatus.completed).length;
  int get missedCount =>
      prayers.values.where((s) => s == PrayerStatus.missed).length;
  int get qazaCount =>
      prayers.values.where((s) => s == PrayerStatus.qaza).length;
}

enum PrayerStatus { none, completed, missed, qaza }

// ─── Provider ─────────────────────────────────────────────────
class NamazTrackerProvider extends ChangeNotifier {
  Map<String, DayPrayerRecord> _records = {};
  static const _key = 'namaz_tracker_data';

  NamazTrackerProvider() {
    _load();
  }

  DayPrayerRecord getRecord(String date) {
    return _records[date] ?? DayPrayerRecord.empty(date);
  }

  Future<void> togglePrayer(String date, String prayer) async {
    final rec = _records[date] ?? DayPrayerRecord.empty(date);
    final current = rec.prayers[prayer] ?? PrayerStatus.none;
    // Cycle: none → completed → missed → qaza → none
    rec.prayers[prayer] = PrayerStatus.values[(current.index + 1) % 4];
    _records[date] = rec;
    notifyListeners();
    await _save();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final list = json.decode(raw) as List;
        _records = {
          for (final item in list)
            (item['date'] as String): DayPrayerRecord.fromJson(item)
        };
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _records.values.map((r) => r.toJson()).toList();
    await prefs.setString(_key, json.encode(list));
  }

  // Monthly stats
  Map<String, int> monthlyStats(int year, int month) {
    int completed = 0, missed = 0, qaza = 0, total = 0;
    _records.forEach((date, rec) {
      final d = DateTime.tryParse(date);
      if (d != null && d.year == year && d.month == month) {
        completed += rec.completedCount;
        missed += rec.missedCount;
        qaza += rec.qazaCount;
        total += 5;
      }
    });
    return {
      'completed': completed,
      'missed': missed,
      'qaza': qaza,
      'total': total,
    };
  }

  double attendanceRate(int year, int month) {
    final s = monthlyStats(year, month);
    final total = s['total']!;
    if (total == 0) return 0;
    return s['completed']! / total;
  }
}

// ─── Main Page ────────────────────────────────────────────────
class NamazTrackerPage extends StatefulWidget {
  const NamazTrackerPage({super.key});

  @override
  State<NamazTrackerPage> createState() => _NamazTrackerPageState();
}

class _NamazTrackerPageState extends State<NamazTrackerPage> {
  late DateTime _focusedMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
    _selectedDay = DateTime.now();
  }

  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  String _bn(dynamic n) {
    const e = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const b = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var s = n.toString();
    for (int i = 0; i < e.length; i++) {
      s = s.replaceAll(e[i], b[i]);
    }
    return s;
  }

  String _banglaMonth(int m) {
    const months = [
      '', 'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল',
      'মে', 'জুন', 'জুলাই', 'আগস্ট',
      'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];
    return months[m];
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NamazTrackerProvider(),
      child: Consumer<NamazTrackerProvider>(
        builder: (context, tracker, _) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
          final cardBg = isDark ? AppColors.darkCard : Colors.white;
          final textColor = isDark ? AppColors.darkText : AppColors.lightText;
          final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;

          final today = DateTime.now();
          final todayKey = _dateKey(today);
          final todayRecord = tracker.getRecord(todayKey);
          final stats = tracker.monthlyStats(_focusedMonth.year, _focusedMonth.month);
          final rate = tracker.attendanceRate(_focusedMonth.year, _focusedMonth.month);

          return Scaffold(
            backgroundColor: bg,
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── AppBar ──────────────────────────────────
                SliverAppBar(
                  expandedHeight: 120,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.gradient,
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text(
                                'নামাজ ট্র্যাকিং',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'নিজেকে আরও ভালো মুসলিম হিসেবে গড়ে তুলুন',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.bar_chart_rounded,
                          color: Colors.white),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded,
                          color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Today's Prayer Card ──────────────
                        _TodayPrayerCard(
                          record: todayRecord,
                          dateKey: todayKey,
                          tracker: tracker,
                          cardBg: cardBg,
                          textColor: textColor,
                          subColor: subColor,
                          bn: _bn,
                        ),
                        const SizedBox(height: 16),

                        // ── Monthly Progress ─────────────────
                        _MonthlyProgressCard(
                          stats: stats,
                          rate: rate,
                          month: _banglaMonth(_focusedMonth.month),
                          year: _bn(_focusedMonth.year),
                          cardBg: cardBg,
                          textColor: textColor,
                          subColor: subColor,
                          bn: _bn,
                        ),
                        const SizedBox(height: 16),

                        // ── Calendar ─────────────────────────
                        _CalendarCard(
                          focusedMonth: _focusedMonth,
                          selectedDay: _selectedDay,
                          tracker: tracker,
                          cardBg: cardBg,
                          textColor: textColor,
                          subColor: subColor,
                          isDark: isDark,
                          bn: _bn,
                          banglaMonth: _banglaMonth,
                          onMonthChanged: (m) =>
                              setState(() => _focusedMonth = m),
                          onDaySelected: (d) =>
                              setState(() => _selectedDay = d),
                        ),
                        const SizedBox(height: 16),

                        // ── Selected Day Detail ──────────────
                        if (_dateKey(_selectedDay) != todayKey)
                          _DayDetailCard(
                            date: _selectedDay,
                            record: tracker.getRecord(_dateKey(_selectedDay)),
                            dateKey: _dateKey(_selectedDay),
                            tracker: tracker,
                            cardBg: cardBg,
                            textColor: textColor,
                            subColor: subColor,
                            bn: _bn,
                          ),

                        // ── Settings ─────────────────────────
                        _SettingsCard(
                          cardBg: cardBg,
                          textColor: textColor,
                          subColor: subColor,
                        ),
                        const SizedBox(height: 16),

                        // ── Add Qaza Button ──────────────────
                        _AddQazaButton(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Today Prayer Card ────────────────────────────────────────
class _TodayPrayerCard extends StatelessWidget {
  final DayPrayerRecord record;
  final String dateKey;
  final NamazTrackerProvider tracker;
  final Color cardBg, textColor, subColor;
  final String Function(dynamic) bn;

  const _TodayPrayerCard({
    required this.record,
    required this.dateKey,
    required this.tracker,
    required this.cardBg,
    required this.textColor,
    required this.subColor,
    required this.bn,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final prayerProvider = context.watch<PrayerProvider>();
    final pt = prayerProvider.prayerTimes;

    final prayers = ['ফজর', 'যোহর', 'আসর', 'মাগরিব', 'ইশা'];
    final icons = [
      Icons.wb_twilight_rounded,
      Icons.wb_sunny_rounded,
      Icons.wb_cloudy_rounded,
      Icons.nights_stay_rounded,
      Icons.dark_mode_rounded,
    ];
    final times = pt != null
        ? [pt.fajr, pt.dhuhr, pt.asr, pt.maghrib, pt.isha]
        : ['--:--', '--:--', '--:--', '--:--', '--:--'];

    final months = [
      '', 'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল',
      'মে', 'জুন', 'জুলাই', 'আগস্ট',
      'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];
    final days = [
      '', 'সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার',
      'শুক্রবার', 'শনিবার', 'রবিবার'
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'আজ, ${bn(now.day)} ${months[now.month]} ${bn(now.year)}',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      days[now.weekday],
                      style: TextStyle(color: subColor, fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'আজকের নামাজ সময়সূচি',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Prayer rows
          ...List.generate(prayers.length, (i) {
            final status = record.prayers[prayers[i]] ?? PrayerStatus.none;
            return _PrayerRow(
              name: prayers[i],
              time: _formatTime12(times[i], bn),
              icon: icons[i],
              status: status,
              onTap: () => tracker.togglePrayer(dateKey, prayers[i]),
            );
          }),
        ],
      ),
    );
  }

  static String _formatTime12(String t, String Function(dynamic) bn) {
    if (t == '--:--') return t;
    try {
      final parts = t.split(':');
      final h = int.parse(parts[0]);
      final m = parts[1];
      final bh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      final ampm = h >= 12 ? 'PM' : 'AM';
      return '${bn(bh)}:${bn(m)} $ampm';
    } catch (_) {
      return t;
    }
  }
}

// ─── Prayer Row ───────────────────────────────────────────────
class _PrayerRow extends StatelessWidget {
  final String name, time;
  final IconData icon;
  final PrayerStatus status;
  final VoidCallback onTap;

  const _PrayerRow({
    required this.name,
    required this.time,
    required this.icon,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case PrayerStatus.completed:
        statusColor = const Color(0xFF22C55E);
        statusIcon = Icons.check_circle_rounded;
        break;
      case PrayerStatus.missed:
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel_rounded;
        break;
      case PrayerStatus.qaza:
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.schedule_rounded;
        break;
      default:
        statusColor = isDark ? Colors.white24 : Colors.black12;
        statusIcon = Icons.radio_button_unchecked_rounded;
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: statusColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ),
            Text(
              time,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor, width: 1.5),
                ),
                child: Icon(statusIcon, color: statusColor, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Monthly Progress Card ────────────────────────────────────
class _MonthlyProgressCard extends StatelessWidget {
  final Map<String, int> stats;
  final double rate;
  final String month, year;
  final Color cardBg, textColor, subColor;
  final String Function(dynamic) bn;

  const _MonthlyProgressCard({
    required this.stats,
    required this.rate,
    required this.month,
    required this.year,
    required this.cardBg,
    required this.textColor,
    required this.subColor,
    required this.bn,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (rate * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.trending_up_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'মাসিক অগ্রগতি',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$month $year',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Circular progress
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: rate,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${bn(percent)}%',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'উপস্থিতি হার',
                          style: TextStyle(color: subColor, fontSize: 9),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Stats
              Expanded(
                child: Column(
                  children: [
                    _StatRow(
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF22C55E),
                      label: 'সম্পূর্ণ হয়েছে',
                      value: bn(stats['completed'] ?? 0),
                      textColor: textColor,
                      subColor: subColor,
                    ),
                    const SizedBox(height: 8),
                    _StatRow(
                      icon: Icons.cancel_rounded,
                      color: const Color(0xFFEF4444),
                      label: 'মিস হয়েছে',
                      value: bn(stats['missed'] ?? 0),
                      textColor: textColor,
                      subColor: subColor,
                    ),
                    const SizedBox(height: 8),
                    _StatRow(
                      icon: Icons.schedule_rounded,
                      color: const Color(0xFFF59E0B),
                      label: 'কাজা রয়েছে',
                      value: bn(stats['qaza'] ?? 0),
                      textColor: textColor,
                      subColor: subColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  final Color textColor, subColor;

  const _StatRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label,
              style: TextStyle(color: subColor, fontSize: 12)),
        ),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ─── Calendar Card ────────────────────────────────────────────
class _CalendarCard extends StatelessWidget {
  final DateTime focusedMonth, selectedDay;
  final NamazTrackerProvider tracker;
  final Color cardBg, textColor, subColor;
  final bool isDark;
  final String Function(dynamic) bn;
  final String Function(int) banglaMonth;
  final void Function(DateTime) onMonthChanged;
  final void Function(DateTime) onDaySelected;

  const _CalendarCard({
    required this.focusedMonth,
    required this.selectedDay,
    required this.tracker,
    required this.cardBg,
    required this.textColor,
    required this.subColor,
    required this.isDark,
    required this.bn,
    required this.banglaMonth,
    required this.onMonthChanged,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay =
        DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun

    final weekdays = ['রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${banglaMonth(focusedMonth.month)} ${bn(focusedMonth.year)}',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  _NavBtn(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => onMonthChanged(DateTime(
                        focusedMonth.year, focusedMonth.month - 1)),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _NavBtn(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => onMonthChanged(DateTime(
                        focusedMonth.year, focusedMonth.month + 1)),
                    isDark: isDark,
                    isPrimary: true,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Weekday headers
          Row(
            children: weekdays
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            color: subColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Days grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 4,
              crossAxisSpacing: 2,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startWeekday) return const SizedBox();
              final day = index - startWeekday + 1;
              final date = DateTime(
                  focusedMonth.year, focusedMonth.month, day);
              final dateKey =
                  DateFormat('yyyy-MM-dd').format(date);
              final record = tracker.getRecord(dateKey);
              final isToday = _isSameDay(date, DateTime.now());
              final isSelected = _isSameDay(date, selectedDay);
              final isFuture = date.isAfter(DateTime.now());

              return GestureDetector(
                onTap: () => onDaySelected(date),
                child: _CalendarDay(
                  day: day,
                  record: record,
                  isToday: isToday,
                  isSelected: isSelected,
                  isFuture: isFuture,
                  isDark: isDark,
                  bn: bn,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final bool isPrimary;

  const _NavBtn({
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary
              : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isPrimary
              ? Colors.white
              : (isDark ? Colors.white70 : Colors.black54),
          size: 20,
        ),
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  final int day;
  final DayPrayerRecord record;
  final bool isToday, isSelected, isFuture, isDark;
  final String Function(dynamic) bn;

  const _CalendarDay({
    required this.day,
    required this.record,
    required this.isToday,
    required this.isSelected,
    required this.isFuture,
    required this.isDark,
    required this.bn,
  });

  @override
  Widget build(BuildContext context) {
    // Determine day indicator
    Widget? indicator;
    if (!isFuture && record.completedCount > 0) {
      if (record.completedCount == 5) {
        indicator = const Icon(Icons.check_rounded,
            color: Color(0xFF22C55E), size: 10);
      } else if (record.missedCount > 0) {
        indicator = const Icon(Icons.close_rounded,
            color: Color(0xFFEF4444), size: 10);
      } else if (record.qazaCount > 0) {
        indicator = const Icon(Icons.schedule_rounded,
            color: Color(0xFFF59E0B), size: 10);
      } else {
        indicator = const Icon(Icons.check_rounded,
            color: Color(0xFF22C55E), size: 10);
      }
    }

    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary
            : isToday
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isToday && !isSelected
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            bn(day),
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  isToday || isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? Colors.white
                  : isFuture
                      ? (isDark ? Colors.white30 : Colors.black26)
                      : (isDark ? AppColors.darkText : AppColors.lightText),
            ),
          ),
          if (indicator != null) indicator,
        ],
      ),
    );
  }
}

// ─── Day Detail Card ──────────────────────────────────────────
class _DayDetailCard extends StatelessWidget {
  final DateTime date;
  final DayPrayerRecord record;
  final String dateKey;
  final NamazTrackerProvider tracker;
  final Color cardBg, textColor, subColor;
  final String Function(dynamic) bn;

  const _DayDetailCard({
    required this.date,
    required this.record,
    required this.dateKey,
    required this.tracker,
    required this.cardBg,
    required this.textColor,
    required this.subColor,
    required this.bn,
  });

  @override
  Widget build(BuildContext context) {
    final months = [
      '', 'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল',
      'মে', 'জুন', 'জুলাই', 'আগস্ট',
      'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];
    final prayers = ['ফজর', 'যোহর', 'আসর', 'মাগরিব', 'ইশা'];
    final icons = [
      Icons.wb_twilight_rounded,
      Icons.wb_sunny_rounded,
      Icons.wb_cloudy_rounded,
      Icons.nights_stay_rounded,
      Icons.dark_mode_rounded,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '${bn(date.day)} ${months[date.month]} ${bn(date.year)}',
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ...List.generate(prayers.length, (i) {
            final status =
                record.prayers[prayers[i]] ?? PrayerStatus.none;
            return _PrayerRow(
              name: prayers[i],
              time: '',
              icon: icons[i],
              status: status,
              onTap: () => tracker.togglePrayer(dateKey, prayers[i]),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Settings Card ────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final Color cardBg, textColor, subColor;

  const _SettingsCard({
    required this.cardBg,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.settings_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'নামাজ ট্রাকিং সেটিংস',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _SettingsTile(
            icon: Icons.notifications_rounded,
            iconBg: const Color(0xFFEDE9FE),
            iconColor: AppColors.primary,
            title: 'নামাজ রিমাইন্ডার',
            subtitle: 'সময়মতো নামাজের জন্য রিমাইন্ডার পান',
            trailing: Switch(
              value: true,
              onChanged: (_) {},
              activeThumbColor: AppColors.primary,
            ),
            textColor: textColor,
            subColor: subColor,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _SettingsTile(
            icon: Icons.nightlight_round,
            iconBg: const Color(0xFFEDE9FE),
            iconColor: const Color(0xFF7C3AED),
            title: 'কাজা নামাজ ট্র্যাকিং',
            subtitle: 'কাজা নামাজ যোগ ও ট্র্যাক করুন',
            trailing: const Icon(Icons.chevron_right_rounded,
                color: Colors.grey),
            textColor: textColor,
            subColor: subColor,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _SettingsTile(
            icon: Icons.edit_note_rounded,
            iconBg: const Color(0xFFEDE9FE),
            iconColor: const Color(0xFF2563EB),
            title: 'নোট যোগ করুন',
            subtitle: 'আপনার অনুভূতি ও নোট লিখুন',
            trailing: const Icon(Icons.chevron_right_rounded,
                color: Colors.grey),
            textColor: textColor,
            subColor: subColor,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle;
  final Widget trailing;
  final Color textColor, subColor;

  const _SettingsTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: TextStyle(color: subColor, fontSize: 11)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

// ─── Add Qaza Button ──────────────────────────────────────────
class _AddQazaButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline_rounded,
                  color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'কাজা নামাজ যোগ করুন',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
