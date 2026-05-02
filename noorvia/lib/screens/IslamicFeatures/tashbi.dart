import 'dart:async';
import 'dart:collection';
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

  // ── Bead animation state ───────────────────────────────────
  // How many beads are "counted" (slid to right side)
  int _animatedBeadCount = 0;
  // Queue of pending slide animations
  final Queue<_BeadSlide> _slideQueue = Queue();
  bool _isAnimating = false;
  // Timestamp of last tap for speed detection
  DateTime? _lastTapTime;
  // The bead currently mid-animation
  int? _animatingBeadIndex; // index in the visual row being animated
  double _animatingBeadOffset = 0.0; // 0.0 = left pos, 1.0 = right pos

  ZikrItem get _currentZikr => _zikrList[_selectedIndex];
  int get _counter => _zikrData[_currentZikr.name]?['counter'] ?? 0;
  int get _completedTimes => _zikrData[_currentZikr.name]?['completedTimes'] ?? 0;
  double get _progress => _targetCount > 0 ? (_counter / _targetCount).clamp(0.0, 1.0) : 0.0;

  @override
  void initState() {
    super.initState();

    _pulseCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _rippleCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _countCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
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

  // ── Bead animation queue processor ────────────────────────
  void _enqueueBeadSlide(int tapIntervalMs) {
    _slideQueue.add(_BeadSlide(intervalMs: tapIntervalMs));
    if (!_isAnimating) _processNextSlide();
  }

  void _processNextSlide() {
    if (_slideQueue.isEmpty || !mounted) {
      _isAnimating = false;
      return;
    }
    _isAnimating = true;
    final slide = _slideQueue.removeFirst();

    // Speed: faster taps = shorter animation (min 80ms, max 320ms)
    final dur = (slide.intervalMs * 0.55).clamp(80.0, 320.0).toInt();
    final beadIdx = _animatedBeadCount;

    setState(() {
      _animatingBeadIndex = beadIdx;
      _animatingBeadOffset = 0.0;
    });

    _animateOffset(dur, beadIdx);
  }

  void _animateOffset(int durationMs, int beadIdx) {
    const steps = 20;
    final stepDur = (durationMs ~/ steps).clamp(4, 20);
    int step = 0;

    Timer.periodic(Duration(milliseconds: stepDur), (t) {
      if (!mounted) { t.cancel(); return; }
      step++;
      final progress = Curves.easeInOut.transform(step / steps);
      setState(() => _animatingBeadOffset = progress);

      if (step >= steps) {
        t.cancel();
        setState(() {
          _animatedBeadCount++;
          _animatingBeadIndex = null;
          _animatingBeadOffset = 0.0;
        });
        Future.delayed(Duration(milliseconds: (stepDur * 0.5).toInt()), () {
          _processNextSlide();
        });
      }
    });
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
      // Sync bead visual to saved counter
      _animatedBeadCount = _counter.clamp(0, _targetCount);
      _animatingBeadIndex = null;
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

    // Measure tap interval for speed-based animation
    final now = DateTime.now();
    final intervalMs = _lastTapTime != null
        ? now.difference(_lastTapTime!).inMilliseconds
        : 400;
    _lastTapTime = now;

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
        // Reset bead visual state for new round
        _animatedBeadCount = 0;
        _slideQueue.clear();
        _isAnimating = false;
        _animatingBeadIndex = null;
        _saveData();
        Future.microtask(() => _showSuccessSheet(cur['completedTimes']));
        return;
      }

      cur['lastUpdated'] = DateTime.now().toIso8601String();
      _zikrData[_currentZikr.name] = cur;
    });

    _saveData();

    // Enqueue a bead slide with current tap speed
    _enqueueBeadSlide(intervalMs.clamp(80, 1000));

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
      // Reset bead visual
      _animatedBeadCount = 0;
      _slideQueue.clear();
      _isAnimating = false;
      _animatingBeadIndex = null;
      _animatingBeadOffset = 0.0;
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
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final zikrColor = _currentZikr.color;
    final screenH = MediaQuery.of(context).size.height;

    // Responsive button size
    final double btnSize = (screenH * 0.22).clamp(130.0, 190.0);
    final double countFontSize = (btnSize * 0.32).clamp(36.0, 58.0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.gradient),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        // Arabic + name in the title area
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currentZikr.arabic,
              style: const TextStyle(
                fontSize: 17,
                color: Colors.white,
                fontFamily: 'Amiri',
                height: 1.3,
              ),
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _currentZikr.name,
              style: GoogleFonts.hindSiliguri(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 22),
            onPressed: _showHistory,
            tooltip: 'পরিসংখ্যান',
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
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
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
                        _animatedBeadCount = (_zikrData[_zikrList[i].name]?['counter'] ?? 0) as int;
                        _slideQueue.clear();
                        _isAnimating = false;
                        _animatingBeadIndex = null;
                        _animatingBeadOffset = 0.0;
                      });
                      _saveData();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 6, top: 5, bottom: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: selected ? _zikrList[i].color : (isDark ? AppColors.darkCard : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: selected ? [
                          BoxShadow(color: _zikrList[i].color.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2)),
                        ] : [],
                        border: Border.all(
                          color: selected ? Colors.transparent : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _zikrList[i].name,
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 11,
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

            const SizedBox(height: 6),

            // ── Bead string ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _TasbihBeadRow(
                total: _targetCount.clamp(1, 100),
                counted: _animatedBeadCount,
                animatingIndex: _animatingBeadIndex,
                animatingOffset: _animatingBeadOffset,
                color: zikrColor,
                isDark: isDark,
              ),
            ),

            const SizedBox(height: 8),

            // ── Counter button (center, takes remaining space) ─
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: _increment,
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, child) => Transform.scale(
                      scale: _pulseAnim.value,
                      child: child,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ripple
                        AnimatedBuilder(
                          animation: _rippleAnim,
                          builder: (_, __) => Opacity(
                            opacity: (1 - _rippleAnim.value).clamp(0.0, 1.0),
                            child: Container(
                              width: btnSize + 50 * _rippleAnim.value,
                              height: btnSize + 50 * _rippleAnim.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: zikrColor.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Glow
                        Container(
                          width: btnSize + 20,
                          height: btnSize + 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [zikrColor.withValues(alpha: 0.12), Colors.transparent],
                            ),
                          ),
                        ),
                        // Main button
                        Container(
                          width: btnSize,
                          height: btnSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [zikrColor, zikrColor.withValues(alpha: 0.75)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: zikrColor.withValues(alpha: 0.4),
                                blurRadius: 28,
                                spreadRadius: 3,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _countAnim,
                                builder: (_, child) => Transform.scale(
                                  scale: _countAnim.value,
                                  child: child,
                                ),
                                child: Text(
                                  _bn(_counter),
                                  style: GoogleFonts.hindSiliguri(
                                    fontSize: countFontSize,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ট্যাপ করুন',
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Stats row (compact inline) ───────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _InlineStat(label: 'সম্পন্ন', value: _bn(_completedTimes), color: zikrColor, subColor: subColor),
                    _Divider(color: subColor),
                    _InlineStat(label: 'বর্তমান', value: _bn(_counter), color: zikrColor, subColor: subColor),
                    _Divider(color: subColor),
                    _InlineStat(label: 'লক্ষ্য', value: _bn(_targetCount), color: zikrColor, subColor: subColor),
                    _Divider(color: subColor),
                    _InlineStat(label: 'বাকি', value: _bn((_targetCount - _counter).clamp(0, _targetCount)), color: zikrColor, subColor: subColor),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Progress bar ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: _progress),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        builder: (_, val, __) => LinearProgressIndicator(
                          value: val,
                          minHeight: 8,
                          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(zikrColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${(_progress * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 12,
                      color: zikrColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Reset icon button inline
                  GestureDetector(
                    onTap: _reset,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: zikrColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: zikrColor.withValues(alpha: 0.3)),
                      ),
                      child: Icon(Icons.refresh_rounded, color: zikrColor, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _BeadSlide — data class for queued animations
// ─────────────────────────────────────────────────────────────────────────────
class _BeadSlide {
  final int intervalMs;
  const _BeadSlide({required this.intervalMs});
}

// ─────────────────────────────────────────────────────────────────────────────
// _TasbihBeadRow — real tasbih bead string visual
// ─────────────────────────────────────────────────────────────────────────────
class _TasbihBeadRow extends StatelessWidget {
  final int total;
  final int counted;
  final int? animatingIndex;
  final double animatingOffset;
  final Color color;
  final bool isDark;

  const _TasbihBeadRow({
    required this.total,
    required this.counted,
    required this.animatingIndex,
    required this.animatingOffset,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // We show at most 33 beads visually; if target > 33 we group them
    const int maxVisible = 33;
    final int visibleTotal = total.clamp(1, maxVisible);
    // Scale counted/animating to visible range
    final double ratio = visibleTotal / total;
    final int visibleCounted = (counted * ratio).floor().clamp(0, visibleTotal);
    final int? visibleAnimating = animatingIndex != null
        ? ((animatingIndex! * ratio).floor()).clamp(0, visibleTotal - 1)
        : null;

    return SizedBox(
      height: 72,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth - 32;
          // Bead size scales with count
          final double beadD = (width / (visibleTotal + 1)).clamp(10.0, 26.0);
          final double beadR = beadD / 2;
          final double stringY = 36.0;

          // Divider x position: separates counted (right) from remaining (left)
          // Beads are evenly spaced; counted beads cluster to the right
          final double spacing = width / (visibleTotal + 1);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // ── String line ──────────────────────────────
              Positioned(
                left: 16,
                right: 16,
                top: stringY - 1.5,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.4),
                        color.withValues(alpha: 0.8),
                        color.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Left knot ────────────────────────────────
              Positioned(
                left: 12,
                top: stringY - 5,
                child: Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.6),
                  ),
                ),
              ),

              // ── Right knot ───────────────────────────────
              Positioned(
                right: 12,
                top: stringY - 5,
                child: Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.6),
                  ),
                ),
              ),

              // ── Beads ────────────────────────────────────
              ...List.generate(visibleTotal, (i) {
                final bool isCounted = i < visibleCounted;
                final bool isAnimating = visibleAnimating != null && i == visibleAnimating;

                // Layout: slots 0..visibleTotal-1 evenly spaced left to right.
                // Uncounted beads occupy left slots (0-based from left).
                // Counted beads occupy right slots (0-based from right).
                //
                // Slot assignment:
                //   uncounted beads: slot index = their order among uncounted (left side)
                //   counted beads:   slot index = visibleTotal-1 - their order among counted (right side)
                //   animating bead:  interpolates from its uncounted slot → first right slot

                double slotX(int slot) => 16 + (slot + 1) * spacing - beadR;

                double baseX;
                if (isCounted) {
                  // i goes 0..visibleCounted-1; rightmost counted = slot visibleTotal-1
                  final int countedOrder = i; // 0 = first counted (rightmost)
                  final int slot = visibleTotal - 1 - countedOrder;
                  baseX = slotX(slot);
                } else if (isAnimating) {
                  // How many uncounted beads are to the left of this one?
                  final int uncountedOrder = i - visibleCounted;
                  final double fromX = slotX(uncountedOrder);
                  // Target: the slot that will become the newest counted bead
                  final int targetSlot = visibleTotal - 1 - visibleCounted;
                  final double toX = slotX(targetSlot);
                  baseX = fromX + (toX - fromX) * animatingOffset;
                } else {
                  // Pure uncounted bead — shift left by 1 if animating bead was before it
                  int uncountedOrder = i - visibleCounted;
                  if (visibleAnimating != null && i > visibleAnimating!) {
                    uncountedOrder -= 1;
                  }
                  baseX = slotX(uncountedOrder);
                }

                // Slight vertical arc: beads in the middle dip a little
                final double midFraction = (i / (visibleTotal - 1).clamp(1, 999)) - 0.5;
                final double arcDip = 8 * (1 - 4 * midFraction * midFraction).clamp(0.0, 1.0);
                final double beadY = stringY - beadR + arcDip;

                return Positioned(
                  left: baseX,
                  top: beadY,
                  child: _Bead(
                    diameter: beadD,
                    color: color,
                    isCounted: isCounted,
                    isAnimating: isAnimating,
                    progress: isAnimating ? animatingOffset : 0,
                    isDark: isDark,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _Bead — single tasbih bead
// ─────────────────────────────────────────────────────────────────────────────
class _Bead extends StatelessWidget {
  final double diameter;
  final Color color;
  final bool isCounted;
  final bool isAnimating;
  final double progress;
  final bool isDark;

  const _Bead({
    required this.diameter,
    required this.color,
    required this.isCounted,
    required this.isAnimating,
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final double scale = isAnimating ? (1.0 + 0.25 * sin(progress * pi)) : 1.0;
    final Color beadColor = isCounted
        ? color
        : (isDark ? color.withValues(alpha: 0.28) : color.withValues(alpha: 0.18));
    final Color borderColor = isCounted
        ? color.withValues(alpha: 0.9)
        : color.withValues(alpha: 0.45);

    return Transform.scale(
      scale: scale,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: beadColor,
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: isCounted || isAnimating
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: isAnimating ? 0.55 : 0.3),
                    blurRadius: isAnimating ? 8 : 4,
                    spreadRadius: isAnimating ? 1 : 0,
                  ),
                ]
              : null,
          gradient: isCounted
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.9),
                    color,
                    color.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        // Shine dot on counted beads
        child: isCounted
            ? Align(
                alignment: const Alignment(-0.3, -0.3),
                child: Container(
                  width: diameter * 0.22,
                  height: diameter * 0.22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              )
            : null,
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
// _InlineStat — compact stat cell used in the stats row
// ─────────────────────────────────────────────────────────────────────────────
class _InlineStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color subColor;

  const _InlineStat({
    required this.label,
    required this.value,
    required this.color,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.hindSiliguri(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.hindSiliguri(
              fontSize: 10,
              color: subColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _Divider — thin vertical separator between inline stats
// ─────────────────────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: color.withValues(alpha: 0.25),
      margin: const EdgeInsets.symmetric(horizontal: 4),
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
