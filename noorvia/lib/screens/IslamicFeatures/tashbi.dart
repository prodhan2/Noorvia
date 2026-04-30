import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Zikr model
// ─────────────────────────────────────────────────────────────────────────────
class ZikrItem {
  final String name;
  final String arabic;
  final int defaultTarget;
  final Color color;

  const ZikrItem({
    required this.name,
    required this.arabic,
    required this.defaultTarget,
    required this.color,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// TasbihCounter widget
// ─────────────────────────────────────────────────────────────────────────────
class TasbihCounter extends StatefulWidget {
  const TasbihCounter({super.key});

  @override
  State<TasbihCounter> createState() => _TasbihCounterState();
}

class _TasbihCounterState extends State<TasbihCounter>
    with TickerProviderStateMixin {

  // ── Zikr list ──────────────────────────────────────────────
  static const List<ZikrItem> _zikrList = [
    ZikrItem(name: 'সুবহানাল্লাহ',       arabic: 'سُبْحَانَ اللّٰهِ',          defaultTarget: 33, color: Color(0xFF1B6B3A)),
    ZikrItem(name: 'আলহামদুলিল্লাহ',     arabic: 'اَلْحَمْدُ لِلّٰهِ',          defaultTarget: 33, color: Color(0xFF1565C0)),
    ZikrItem(name: 'আল্লাহু আকবার',      arabic: 'اَللّٰهُ أَكْبَرُ',           defaultTarget: 34, color: Color(0xFF6A1B9A)),
    ZikrItem(name: 'লা ইলাহা ইল্লাল্লাহ', arabic: 'لَا إِلٰهَ إِلَّا اللّٰهُ',  defaultTarget: 100, color: Color(0xFFE65100)),
    ZikrItem(name: 'আস্তাগফিরুল্লাহ',    arabic: 'أَسْتَغْفِرُ اللّٰهَ',        defaultTarget: 100, color: Color(0xFF00838F)),
    ZikrItem(name: 'দরূদ শরীফ',          arabic: 'صَلَّى اللّٰهُ عَلَيْهِ وَسَلَّمَ', defaultTarget: 100, color: Color(0xFFAD1457)),
    ZikrItem(name: 'বিসমিল্লাহ',         arabic: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيمِ', defaultTarget: 21, color: Color(0xFF2E7D32)),
    ZikrItem(name: 'ইয়া আল্লাহ',        arabic: 'يَا اللّٰهُ',                 defaultTarget: 100, color: Color(0xFF4527A0)),
    ZikrItem(name: 'সুবহানাল্লাহি ওয়া বিহামদিহি', arabic: 'سُبْحَانَ اللّٰهِ وَبِحَمْدِهِ', defaultTarget: 100, color: Color(0xFF00695C)),
    ZikrItem(name: 'লা হাওলা ওয়ালা কুওয়াতা', arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰهِ', defaultTarget: 100, color: Color(0xFF558B2F)),
  ];

  int _selectedIndex = 0;
  int _targetCount = 33;
  Map<String, dynamic> _zikrData = {};

  // ── Animation controllers ──────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _rippleCtrl;
  late AnimationController _countCtrl;
  late AnimationController _successCtrl;

  late Animation<double> _pulseAnim;
  late Animation<double> _rippleAnim;
  late Animation<double> _countAnim;

  bool _tapped = false; // ignore: unused_field

  ZikrItem get _currentZikr => _zikrList[_selectedIndex];
  int get _counter => _zikrData[_currentZikr.name]?['counter'] ?? 0;
  int get _completedTimes => _zikrData[_currentZikr.name]?['completedTimes'] ?? 0;
  double get _progress => _targetCount > 0 ? (_counter / _targetCount).clamp(0.0, 1.0) : 0.0;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _rippleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _countCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _successCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    _pulseAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _rippleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut),
    );
    _countAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _countCtrl, curve: Curves.elasticOut),
    );

    _loadData();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rippleCtrl.dispose();
    _countCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  // ── Persistence ────────────────────────────────────────────
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('tasbih_zikr_data_v2');
    final idx  = prefs.getInt('tasbih_selected_index') ?? 0;
    setState(() {
      _zikrData = raw != null ? Map<String, dynamic>.from(jsonDecode(raw)) : {};
      _selectedIndex = idx.clamp(0, _zikrList.length - 1);
      _targetCount = prefs.getInt('tasbih_target_${_currentZikr.name}') ?? _currentZikr.defaultTarget;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasbih_zikr_data_v2', jsonEncode(_zikrData));
    await prefs.setInt('tasbih_selected_index', _selectedIndex);
    await prefs.setInt('tasbih_target_${_currentZikr.name}', _targetCount);
  }

  // ── Increment ──────────────────────────────────────────────
  void _increment() {
    HapticFeedback.lightImpact();

    // Animate button press
    _pulseCtrl.forward().then((_) => _pulseCtrl.reverse());
    _rippleCtrl.forward(from: 0);
    _countCtrl.forward(from: 0);

    setState(() {
      _tapped = true;
      final cur = Map<String, dynamic>.from(
        _zikrData[_currentZikr.name] ?? {'counter': 0, 'completedTimes': 0},
      );
      cur['counter'] = (cur['counter'] ?? 0) + 1;

      if (cur['counter'] >= _targetCount) {
        cur['completedTimes'] = (cur['completedTimes'] ?? 0) + 1;
        cur['counter'] = 0;
        _zikrData[_currentZikr.name] = cur;
        _saveData();
        Future.microtask(() => _showSuccessSheet(cur['completedTimes']));
        return;
      }

      cur['lastUpdated'] = DateTime.now().toIso8601String();
      _zikrData[_currentZikr.name] = cur;
    });

    _saveData();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _tapped = false);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      final cur = Map<String, dynamic>.from(_zikrData[_currentZikr.name] ?? {});
      cur['counter'] = 0;
      _zikrData[_currentZikr.name] = cur;
    });
    _saveData();
  }

  // ── Bangla digits ──────────────────────────────────────────
  String _bn(int n) {
    const e = ['0','1','2','3','4','5','6','7','8','9'];
    const b = ['০','১','২','৩','৪','৫','৬','৭','৮','৯'];
    String s = n.toString();
    for (int i = 0; i < e.length; i++) { s = s.replaceAll(e[i], b[i]); }
    return s;
  }

  // ── Success bottom sheet ───────────────────────────────────
  Future<void> _showSuccessSheet(int times) async {
    HapticFeedback.heavyImpact();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SuccessSheet(
        zikr: _currentZikr,
        times: times,
        target: _targetCount,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  // ── Settings bottom sheet ──────────────────────────────────
  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SettingsSheet(
        zikrList: _zikrList,
        selectedIndex: _selectedIndex,
        targetCount: _targetCount,
        onSave: (idx, target) {
          setState(() {
            _selectedIndex = idx;
            _targetCount = target;
          });
          _saveData();
          Navigator.pop(context);
        },
      ),
    );
  }

  // ── History bottom sheet ───────────────────────────────────
  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _HistorySheet(
        zikrList: _zikrList,
        zikrData: _zikrData,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final zikrColor = _currentZikr.color;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'তাসবিহ কাউন্টার',
          style: GoogleFonts.hindSiliguri(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart_rounded, color: textColor),
            onPressed: _showHistory,
            tooltip: 'পরিসংখ্যান',
          ),
          IconButton(
            icon: Icon(Icons.tune_rounded, color: textColor),
            onPressed: _showSettings,
            tooltip: 'সেটিংস',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Zikr selector chips ──────────────────────────
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _zikrList.length,
                itemBuilder: (_, i) {
                  final selected = i == _selectedIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = i;
                        _targetCount = _zikrData['tasbih_target_${_zikrList[i].name}'] != null
                            ? _zikrData['tasbih_target_${_zikrList[i].name}'] as int
                            : _zikrList[i].defaultTarget;
                      });
                      _saveData();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: selected ? _zikrList[i].color : (isDark ? AppColors.darkCard : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: selected ? [
                          BoxShadow(color: _zikrList[i].color.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3)),
                        ] : [],
                        border: Border.all(
                          color: selected ? Colors.transparent : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _zikrList[i].name,
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 12,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? Colors.white : subColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // ── Arabic text card ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [zikrColor, zikrColor.withValues(alpha: 0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: zikrColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _currentZikr.arabic,
                      style: const TextStyle(
                        fontSize: 26,
                        color: Colors.white,
                        fontFamily: 'Amiri',
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentZikr.name,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Stats row ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _StatCard(
                    label: 'সম্পন্ন',
                    value: _bn(_completedTimes),
                    unit: 'বার',
                    color: zikrColor,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'লক্ষ্য',
                    value: _bn(_targetCount),
                    unit: 'বার',
                    color: zikrColor,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'বাকি',
                    value: _bn((_targetCount - _counter).clamp(0, _targetCount)),
                    unit: 'বার',
                    color: zikrColor,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Main counter button ──────────────────────────
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: _increment,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ripple ring
                      AnimatedBuilder(
                        animation: _rippleAnim,
                        builder: (_, __) {
                          return Opacity(
                            opacity: (1 - _rippleAnim.value).clamp(0.0, 1.0),
                            child: Container(
                              width: 220 + 80 * _rippleAnim.value,
                              height: 220 + 80 * _rippleAnim.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: zikrColor.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Outer glow ring
                      Container(
                        width: 230,
                        height: 230,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              zikrColor.withValues(alpha: 0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                      // Main button
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, child) => Transform.scale(
                          scale: _pulseAnim.value,
                          child: child,
                        ),
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                zikrColor,
                                zikrColor.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: zikrColor.withValues(alpha: 0.45),
                                blurRadius: 30,
                                spreadRadius: 4,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Counter number with bounce
                              AnimatedBuilder(
                                animation: _countAnim,
                                builder: (_, child) => Transform.scale(
                                  scale: _countAnim.value,
                                  child: child,
                                ),
                                child: Text(
                                  _bn(_counter),
                                  style: GoogleFonts.hindSiliguri(
                                    fontSize: 64,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'ট্যাপ করুন',
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Progress bar ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(_progress * 100).toStringAsFixed(0)}% সম্পন্ন',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 12,
                          color: subColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${_bn(_counter)} / ${_bn(_targetCount)}',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 12,
                          color: subColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _progress),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      builder: (_, val, __) => LinearProgressIndicator(
                        value: val,
                        minHeight: 10,
                        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(zikrColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Reset button ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _reset,
                  icon: Icon(Icons.refresh_rounded, color: zikrColor, size: 18),
                  label: Text(
                    'রিসেট করুন',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: zikrColor,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: zikrColor.withValues(alpha: 0.5), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatCard
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.hindSiliguri(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              unit,
              style: GoogleFonts.hindSiliguri(
                fontSize: 11,
                color: color.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.hindSiliguri(
                fontSize: 11,
                color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SuccessSheet — shown when target is reached
// ─────────────────────────────────────────────────────────────────────────────
class _SuccessSheet extends StatefulWidget {
  final ZikrItem zikr;
  final int times;
  final int target;
  final VoidCallback onClose;

  const _SuccessSheet({
    required this.zikr,
    required this.times,
    required this.target,
    required this.onClose,
  });

  @override
  State<_SuccessSheet> createState() => _SuccessSheetState();
}

class _SuccessSheetState extends State<_SuccessSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  String _bn(int n) {
    const e = ['0','1','2','3','4','5','6','7','8','9'];
    const b = ['০','১','২','৩','৪','৫','৬','৭','৮','৯'];
    String s = n.toString();
    for (int i = 0; i < e.length; i++) { s = s.replaceAll(e[i], b[i]); }
    return s;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final color = widget.zikr.color;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Animated star icon
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'মাশাআল্লাহ! 🎉',
              style: GoogleFonts.hindSiliguri(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.zikr.arabic,
              style: const TextStyle(
                fontSize: 22,
                color: Colors.grey,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),
            Text(
              'আপনি ${widget.zikr.name} ${_bn(widget.target)} বার সম্পন্ন করেছেন',
              style: GoogleFonts.hindSiliguri(
                fontSize: 15,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'মোট ${_bn(widget.times)} বার সম্পন্ন',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'চালিয়ে যান',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SettingsSheet
// ─────────────────────────────────────────────────────────────────────────────
class _SettingsSheet extends StatefulWidget {
  final List<ZikrItem> zikrList;
  final int selectedIndex;
  final int targetCount;
  final void Function(int index, int target) onSave;

  const _SettingsSheet({
    required this.zikrList,
    required this.selectedIndex,
    required this.targetCount,
    required this.onSave,
  });

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late int _selIdx;
  late int _target;
  late TextEditingController _targetCtrl;

  static const List<int> _presets = [11, 21, 33, 34, 99, 100, 1000];

  @override
  void initState() {
    super.initState();
    _selIdx = widget.selectedIndex;
    _target = widget.targetCount;
    _targetCtrl = TextEditingController(text: _target.toString());
  }

  @override
  void dispose() {
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final color = widget.zikrList[_selIdx].color;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'সেটিংস',
              style: GoogleFonts.hindSiliguri(
                fontSize: 20, fontWeight: FontWeight.w800, color: textColor,
              ),
            ),
            const SizedBox(height: 20),

            // Zikr selector
            Text(
              'জিকির নির্বাচন করুন',
              style: GoogleFonts.hindSiliguri(
                fontSize: 13, fontWeight: FontWeight.w600, color: subColor,
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(widget.zikrList.length, (i) {
              final z = widget.zikrList[i];
              final sel = i == _selIdx;
              return GestureDetector(
                onTap: () => setState(() {
                  _selIdx = i;
                  _target = z.defaultTarget;
                  _targetCtrl.text = _target.toString();
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? z.color.withValues(alpha: 0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel ? z.color : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: sel ? z.color : Colors.grey[400],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          z.name,
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 14,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            color: sel ? z.color : textColor,
                          ),
                        ),
                      ),
                      Text(
                        z.arabic,
                        style: TextStyle(
                          fontSize: 14,
                          color: sel ? z.color : subColor,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // Target count
            Text(
              'লক্ষ্য সংখ্যা',
              style: GoogleFonts.hindSiliguri(
                fontSize: 13, fontWeight: FontWeight.w600, color: subColor,
              ),
            ),
            const SizedBox(height: 10),

            // Preset chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((p) {
                final sel = _target == p;
                return GestureDetector(
                  onTap: () => setState(() {
                    _target = p;
                    _targetCtrl.text = p.toString();
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? color : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? color : (isDark ? Colors.grey[600]! : Colors.grey[300]!),
                      ),
                    ),
                    child: Text(
                      p.toString(),
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : subColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Custom input
            TextField(
              controller: _targetCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.hindSiliguri(color: textColor),
              decoration: InputDecoration(
                labelText: 'কাস্টম সংখ্যা লিখুন',
                labelStyle: GoogleFonts.hindSiliguri(color: subColor, fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (v) {
                final n = int.tryParse(v);
                if (n != null && n > 0) setState(() => _target = n);
              },
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => widget.onSave(_selIdx, _target),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  'সেভ করুন',
                  style: GoogleFonts.hindSiliguri(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HistorySheet
// ─────────────────────────────────────────────────────────────────────────────
class _HistorySheet extends StatelessWidget {
  final List<ZikrItem> zikrList;
  final Map<String, dynamic> zikrData;

  const _HistorySheet({
    required this.zikrList,
    required this.zikrData,
  });

  String _bn(int n) {
    const e = ['0','1','2','3','4','5','6','7','8','9'];
    const b = ['০','১','২','৩','৪','৫','৬','৭','৮','৯'];
    String s = n.toString();
    for (int i = 0; i < e.length; i++) { s = s.replaceAll(e[i], b[i]); }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    // Total across all zikr
    int totalCompleted = 0;
    for (final z in zikrList) {
      totalCompleted += (zikrData[z.name]?['completedTimes'] ?? 0) as int;
    }

    return Container(
      margin: const EdgeInsets.only(top: 60),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'পরিসংখ্যান',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 20, fontWeight: FontWeight.w800, color: textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'মোট ${_bn(totalCompleted)} বার',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // List
          ...zikrList.map((z) {
            final data = zikrData[z.name];
            final counter = (data?['counter'] ?? 0) as int;
            final completed = (data?['completedTimes'] ?? 0) as int;
            if (counter == 0 && completed == 0) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBg : AppColors.lightBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: z.color.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: z.color.withValues(alpha: 0.15),
                    ),
                    child: Center(
                      child: Text(
                        z.arabic.substring(0, min(2, z.arabic.length)),
                        style: TextStyle(fontSize: 14, color: z.color),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          z.name,
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 14, fontWeight: FontWeight.w600, color: textColor,
                          ),
                        ),
                        if (counter > 0)
                          Text(
                            'চলমান: ${_bn(counter)}',
                            style: GoogleFonts.hindSiliguri(fontSize: 12, color: subColor),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _bn(completed),
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 22, fontWeight: FontWeight.w800, color: z.color,
                        ),
                      ),
                      Text(
                        'বার',
                        style: GoogleFonts.hindSiliguri(fontSize: 11, color: subColor),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          // Empty state
          if (zikrList.every((z) {
            final d = zikrData[z.name];
            return (d?['counter'] ?? 0) == 0 && (d?['completedTimes'] ?? 0) == 0;
          }))
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.history_rounded, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'এখনো কোনো জিকির করা হয়নি',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 14, color: subColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
