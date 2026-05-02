import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class DiagnosisQuestion {
  final String question;
  final List<String> options;
  const DiagnosisQuestion({required this.question, required this.options});
  factory DiagnosisQuestion.fromJson(Map<String, dynamic> j) => DiagnosisQuestion(
        question: j['question']?.toString() ?? '',
        options: (j['options'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );
}

class DiagnosisCategory {
  final int id;
  final String diagnosisType;
  final String resultDetails;
  final List<DiagnosisQuestion> questions;
  const DiagnosisCategory({
    required this.id,
    required this.diagnosisType,
    required this.resultDetails,
    required this.questions,
  });
  factory DiagnosisCategory.fromJson(Map<String, dynamic> j) => DiagnosisCategory(
        id: (j['id'] as num?)?.toInt() ?? 0,
        diagnosisType: j['diagnosis_type']?.toString() ?? '',
        resultDetails: j['result_details']?.toString() ?? '',
        questions: (j['questions'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map((q) => DiagnosisQuestion.fromJson(q))
                .toList() ??
            [],
      );

  String get shortTitle {
    final t = diagnosisType
        .replaceAll('যাচাই সম্পন্ন হয়েছে', '')
        .replaceAll('সমস্যা', '')
        .trim();
    return t;
  }
}

// ─── Category List Page ───────────────────────────────────────────────────────

class RuqyahDiagnosisPage extends StatefulWidget {
  const RuqyahDiagnosisPage({super.key});
  @override
  State<RuqyahDiagnosisPage> createState() => _RuqyahDiagnosisPageState();
}

class _RuqyahDiagnosisPageState extends State<RuqyahDiagnosisPage> {
  static const _apiUrl =
      'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/My_Ruqiya/all_diagnosis_check%20(2).json';
  static const _cacheKey = 'ruqyah_diagnosis_cache';

  List<DiagnosisCategory> _categories = [];
  bool _loading = true;
  String? _error;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; _offline = false; });
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      _parse(cached, fromCache: true);
    }
    try {
      final res = await http.get(Uri.parse(_apiUrl)).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final raw = utf8.decode(res.bodyBytes);
        await prefs.setString(_cacheKey, raw);
        _parse(raw, fromCache: false);
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _loading = false;
        _offline = _categories.isNotEmpty;
        if (_categories.isEmpty) _error = 'ডেটা লোড করা যায়নি। ইন্টারনেট পরীক্ষা করুন।';
      });
    }
  }

  void _parse(String raw, {required bool fromCache}) {
    try {
      final list = jsonDecode(raw) as List;
      final cats = list.whereType<Map<String, dynamic>>()
          .map((e) => DiagnosisCategory.fromJson(e))
          .toList();
      if (mounted) {
        setState(() {
          _categories = cats;
          _loading = false;
          _offline = fromCache;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const List<Map<String, dynamic>> _meta = [
    {'icon': '👶', 'colors': [Color(0xFF6C3CE1), Color(0xFF9B6FF5)]},
    {'icon': '🧒', 'colors': [Color(0xFF0891B2), Color(0xFF4A90D9)]},
    {'icon': '🪄', 'colors': [Color(0xFF7C3AED), Color(0xFFD946EF)]},
    {'icon': '👁', 'colors': [Color(0xFF059669), Color(0xFF34D399)]},
    {'icon': '🌀', 'colors': [Color(0xFFD97706), Color(0xFFF59E0B)]},
    {'icon': '❓', 'colors': [Color(0xFFDC2626), Color(0xFFF87171)]},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(),
      body: _buildBody(isDark),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/IslamicAppImages/rukaiyabg.webp',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(gradient: AppColors.gradient),
            ),
          ),
          Positioned(top: -30, right: -30, child: Container(width: 160, height: 160, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
          Positioned(bottom: -20, left: -20, child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)))),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('সেলফ ডায়াগনোসিস', style: GoogleFonts.hindSiliguri(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black, height: 1.2)),
          Text('নিজেই যাচাই করুন', style: GoogleFonts.hindSiliguri(fontSize: 10, color: Colors.black, height: 1.2)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.black, size: 20),
          onPressed: _loadData,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 14),
          ]),
        ),
      );
    }
    if (_error != null) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center,
                  style: GoogleFonts.hindSiliguri(fontSize: 15)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: Text('আবার চেষ্টা', style: GoogleFonts.hindSiliguri()),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            ]),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _introCard(isDark),
        const SizedBox(height: 20),
        Text('সমস্যার ধরন বেছে নিন',
            style: GoogleFonts.hindSiliguri(
                fontSize: 16, fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkText : AppColors.lightText)),
        const SizedBox(height: 12),
        ..._categories.asMap().entries.map((e) {
          final meta = _meta[e.key % _meta.length];
          return _CategoryCard(
            category: e.value,
            icon: meta['icon'] as String,
            gradientColors: (meta['colors'] as List).cast<Color>(),
            isDark: isDark,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => _DiagnosisQuizPage(category: e.value),
            )),
          );
        }),
      ],
    );
  }

  Widget _introCard(bool isDark) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: AppColors.gradient,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(children: [
      const Text('🔍', style: TextStyle(fontSize: 36)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('সেলফ রুকইয়াহ ডায়াগনোসিস',
            style: GoogleFonts.hindSiliguri(
                fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Text('প্রশ্নের উত্তর দিন এবং জানুন আপনার সমস্যার ধরন ও সমাধান',
            style: GoogleFonts.hindSiliguri(fontSize: 12, color: Colors.white70, height: 1.5)),
      ])),
    ]),
  );
}

// ─── Category Card ────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final DiagnosisCategory category;
  final String icon;
  final List<Color> gradientColors;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.icon,
    required this.gradientColors,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor  = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final accentColor = gradientColors.first;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: isDark ? 0.12 : 0.10),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: accentColor.withValues(alpha: isDark ? 0.18 : 0.12),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            // Accent icon box
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.shortTitle,
                  style: GoogleFonts.hindSiliguri(
                      fontSize: 15, fontWeight: FontWeight.w700, color: textColor),
                ),
                const SizedBox(height: 3),
                Text(
                  '${category.questions.length} টি প্রশ্ন',
                  style: GoogleFonts.hindSiliguri(
                      fontSize: 12, color: subColor, height: 1.4),
                ),
              ],
            )),
            const SizedBox(width: 8),
            // Arrow
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  color: accentColor, size: 14),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Quiz Page ────────────────────────────────────────────────────────────────

class _DiagnosisQuizPage extends StatefulWidget {
  final DiagnosisCategory category;
  const _DiagnosisQuizPage({required this.category});

  @override
  State<_DiagnosisQuizPage> createState() => _DiagnosisQuizPageState();
}

class _DiagnosisQuizPageState extends State<_DiagnosisQuizPage> {
  final Map<int, String> _answers = {};
  int _currentQ = 0;
  bool _submitted = false;

  List<DiagnosisQuestion> get _questions => widget.category.questions;

  void _selectOption(String option) {
    setState(() => _answers[_currentQ] = option);
  }

  void _next() {
    if (_currentQ < _questions.length - 1) {
      setState(() => _currentQ++);
    } else {
      setState(() => _submitted = true);
    }
  }

  void _prev() {
    if (_currentQ > 0) setState(() => _currentQ--);
  }

  // Score: হ্যাঁ = 2, মাঝে মধ্যে = 1, না = 0
  int get _score => _answers.values.fold(0, (sum, a) {
        if (a == 'হ্যাঁ') return sum + 2;
        if (a == 'মাঝে মধ্যে') return sum + 1;
        return sum;
      });

  int get _maxScore => _questions.length * 2;

  double get _scorePercent => _maxScore == 0 ? 0 : _score / _maxScore;

  // Answered "হ্যাঁ" or "মাঝে মধ্যে" questions
  List<String> get _positiveSymptoms => _answers.entries
      .where((e) => e.value == 'হ্যাঁ' || e.value == 'মাঝে মধ্যে')
      .map((e) => _questions[e.key].question)
      .toList();

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: AppColors.gradient)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _submitted ? 'ফলাফল' : widget.category.shortTitle,
          style: GoogleFonts.hindSiliguri(
              fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black),
        ),
      ),
      body: _submitted ? _buildResult(isDark) : _buildQuiz(isDark),
    );
  }

  // ── Quiz UI ──────────────────────────────────────────────────
  Widget _buildQuiz(bool isDark) {
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final q = _questions[_currentQ];
    final answered = _answers[_currentQ];
    final progress = (_currentQ + 1) / _questions.length;

    return Column(children: [
      // Progress bar
      Container(
        color: isDark ? AppColors.darkCard : Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('প্রশ্ন ${_currentQ + 1} / ${_questions.length}',
                style: GoogleFonts.hindSiliguri(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
            Text('${(_answers.length)} টি উত্তর দেওয়া হয়েছে',
                style: GoogleFonts.hindSiliguri(fontSize: 11, color: Colors.grey)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ]),
      ),

      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Question card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 10, offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('লক্ষণ ${_currentQ + 1}',
                      style: GoogleFonts.hindSiliguri(
                          fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
                const SizedBox(height: 14),
                Text(q.question,
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 16, fontWeight: FontWeight.w600,
                        color: textColor, height: 1.6)),
              ]),
            ),

            const SizedBox(height: 20),
            Text('আপনার উত্তর বেছে নিন:',
                style: GoogleFonts.hindSiliguri(
                    fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 10),

            // Options
            ...q.options.map((opt) {
              final isSelected = answered == opt;
              Color optColor;
              if (opt == 'হ্যাঁ') optColor = const Color(0xFFDC2626);
              else if (opt == 'মাঝে মধ্যে') optColor = const Color(0xFFD97706);
              else optColor = const Color(0xFF059669);

              return GestureDetector(
                onTap: () => _selectOption(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? optColor.withValues(alpha: 0.12) : cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? optColor : Colors.grey.withValues(alpha: 0.2),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(color: optColor.withValues(alpha: 0.2),
                          blurRadius: 8, offset: const Offset(0, 2)),
                    ] : [],
                  ),
                  child: Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? optColor : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? optColor : Colors.grey.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Text(opt,
                        style: GoogleFonts.hindSiliguri(
                            fontSize: 15, fontWeight: FontWeight.w600,
                            color: isSelected ? optColor : textColor)),
                  ]),
                ),
              );
            }),
          ]),
        ),
      ),

      // Navigation buttons
      Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: cardColor,
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 10, offset: const Offset(0, -3)),
          ],
        ),
        child: SafeArea(
          child: Row(children: [
            if (_currentQ > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _prev,
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                  label: Text('পূর্ববর্তী', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            if (_currentQ > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: answered != null ? _next : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    _currentQ == _questions.length - 1 ? 'ফলাফল দেখুন' : 'পরবর্তী',
                    style: GoogleFonts.hindSiliguri(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 6),
                  Icon(_currentQ == _questions.length - 1
                      ? Icons.check_circle_rounded
                      : Icons.arrow_forward_ios_rounded,
                      size: 16),
                ]),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }

  // ── Result UI ────────────────────────────────────────────────
  Widget _buildResult(bool isDark) {
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final pct = _scorePercent;

    Color riskColor;
    String riskLabel;
    String riskEmoji;
    if (pct >= 0.6) {
      riskColor = const Color(0xFFDC2626);
      riskLabel = 'উচ্চ সম্ভাবনা';
      riskEmoji = '⚠️';
    } else if (pct >= 0.3) {
      riskColor = const Color(0xFFD97706);
      riskLabel = 'মাঝারি সম্ভাবনা';
      riskEmoji = '🔶';
    } else {
      riskColor = const Color(0xFF059669);
      riskLabel = 'কম সম্ভাবনা';
      riskEmoji = '✅';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        // Score card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.gradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: [
            Text('যাচাই সম্পন্ন হয়েছে ✅',
                style: GoogleFonts.hindSiliguri(
                    fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 12),
            Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 110, height: 110,
                child: CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 10,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      pct >= 0.6 ? const Color(0xFFFF6B6B) : Colors.white),
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${(_score)}/${_maxScore}',
                    style: GoogleFonts.poppins(
                        fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                Text('স্কোর', style: GoogleFonts.hindSiliguri(fontSize: 11, color: Colors.white70)),
              ]),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$riskEmoji $riskLabel',
                  style: GoogleFonts.hindSiliguri(
                      fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ]),
        ),

        const SizedBox(height: 20),

        // Symptoms found
        if (_positiveSymptoms.isNotEmpty) ...[
          Text('আপনার লক্ষণসমূহ',
              style: GoogleFonts.hindSiliguri(
                  fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: riskColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _positiveSymptoms.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.circle, size: 7, color: riskColor),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s,
                      style: GoogleFonts.hindSiliguri(
                          fontSize: 13, color: textColor, height: 1.5))),
                ]),
              )).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Result details
        Text('পরামর্শ ও সমাধান',
            style: GoogleFonts.hindSiliguri(
                fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: MarkdownBody(
            data: _htmlToMarkdown(widget.category.resultDetails),
            styleSheet: MarkdownStyleSheet(
              p: GoogleFonts.hindSiliguri(fontSize: 14, color: textColor, height: 1.7),
              strong: GoogleFonts.hindSiliguri(
                  fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
              a: GoogleFonts.hindSiliguri(
                  fontSize: 14, color: AppColors.primary,
                  decoration: TextDecoration.underline),
            ),
            onTapLink: (text, href, title) async {
              if (href != null) {
                final uri = Uri.parse(href);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ),

        const SizedBox(height: 24),

        // Retry button
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: Text('ফিরে যান', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => setState(() {
                _answers.clear();
                _currentQ = 0;
                _submitted = false;
              }),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text('আবার করুন', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
      ],
    );
  }

  /// Converts basic HTML tags to Markdown for flutter_markdown
  String _htmlToMarkdown(String html) {
    return html
        .replaceAll(RegExp(r'<p[^>]*>'), '\n')
        .replaceAll('</p>', '\n')
        .replaceAll('<b>', '**')
        .replaceAll('</b>', '**')
        .replaceAll('<strong>', '**')
        .replaceAll('</strong>', '**')
        .replaceAll(RegExp(r'<a\s+href="([^"]+)"[^>]*>([^<]+)</a>'),
            r'[\2](\1)')
        .replaceAll(RegExp(r'<div[^>]*>'), '')
        .replaceAll('</div>', '')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}
