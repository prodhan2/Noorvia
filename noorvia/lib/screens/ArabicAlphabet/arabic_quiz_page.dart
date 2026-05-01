import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import 'arabic_letter_model.dart';
import 'arabic_quiz_result_page.dart';

class ArabicQuizPage extends StatefulWidget {
  final List<ArabicLetter> letters;

  const ArabicQuizPage({super.key, required this.letters});

  @override
  State<ArabicQuizPage> createState() => _ArabicQuizPageState();
}

class _ArabicQuizPageState extends State<ArabicQuizPage>
    with SingleTickerProviderStateMixin {
  final _rng = Random();
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  int _questionIndex = 0;
  int _score = 0;
  int _total = 0;
  bool _answered = false;
  int? _selectedOption;
  int? _correctOption;

  late ArabicLetter _question;
  late List<String> _options;

  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);
    _total = min(widget.letters.length, 10);
    _nextQuestion();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  void _nextQuestion() {
    if (_questionIndex >= _total) return;
    final shuffled = List<ArabicLetter>.from(widget.letters)..shuffle(_rng);
    _question = shuffled[0];

    // 4 unique options
    final pool = List<ArabicLetter>.from(widget.letters)
      ..removeWhere((l) => l.letter == _question.letter)
      ..shuffle(_rng);
    final wrong = pool.take(3).map((l) => l.bangla).toList();
    _options = [...wrong, _question.bangla]..shuffle(_rng);
    _correctOption = _options.indexOf(_question.bangla);

    setState(() {
      _answered = false;
      _selectedOption = null;
    });
    _animCtrl.reset();
    _animCtrl.forward();
  }

  void _answer(int index) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _selectedOption = index;
      if (index == _correctOption) _score++;
      _questionIndex++;
    });
  }

  void _next() {
    if (_questionIndex >= _total) {
      _showResult();
    } else {
      _nextQuestion();
    }
  }

  void _showResult() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => ArabicQuizResultPage(
          score: _score,
          total: _total,
          onRetry: () {
            setState(() {
              _questionIndex = 0;
              _score = 0;
            });
            _nextQuestion();
          },
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.darkText : AppColors.lightText,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'কুইজ',
          style: GoogleFonts.hindSiliguri(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'স্কোর: $_score',
              style: GoogleFonts.hindSiliguri(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: _questionIndex >= _total
          ? const SizedBox()
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Progress bar
                  _buildProgress(isDark),
                  const SizedBox(height: 24),
                  // Question card
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: _buildQuestionCard(isDark),
                  ),
                  const SizedBox(height: 24),
                  // Options
                  ..._buildOptions(isDark),
                  const Spacer(),
                  // Next button
                  if (_answered)
                    _buildNextButton(isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildProgress(bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'প্রশ্ন ${_questionIndex + 1} / $_total',
              style: GoogleFonts.hindSiliguri(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkText.withValues(alpha: 0.6)
                    : Colors.grey[600],
              ),
            ),
            Text(
              '${((_questionIndex / _total) * 100).round()}%',
              style: GoogleFonts.hindSiliguri(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _questionIndex / _total,
            backgroundColor: isDark
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.primary.withValues(alpha: 0.1),
            valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C3CE1), Color(0xFF4A6FE3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C3CE1).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'এই অক্ষরের বাংলা নাম কী?',
            style: GoogleFonts.hindSiliguri(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _question.letter,
            style: const TextStyle(
              fontSize: 80,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOptions(bool isDark) {
    return List.generate(_options.length, (i) {
      Color? bg;
      Color? border;
      Color textColor =
          isDark ? AppColors.darkText : AppColors.lightText;

      if (_answered) {
        if (i == _correctOption) {
          bg = const Color(0xFF2ECC71).withValues(alpha: 0.15);
          border = const Color(0xFF2ECC71);
          textColor = const Color(0xFF2ECC71);
        } else if (i == _selectedOption) {
          bg = const Color(0xFFE74C3C).withValues(alpha: 0.15);
          border = const Color(0xFFE74C3C);
          textColor = const Color(0xFFE74C3C);
        }
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () => _answer(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: bg ??
                  (isDark ? AppColors.darkCard : Colors.white),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: border ??
                    AppColors.primary.withValues(alpha: 0.15),
                width: border != null ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + i),
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _options[i],
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                if (_answered && i == _correctOption)
                  const Icon(Icons.check_circle,
                      color: Color(0xFF2ECC71), size: 20),
                if (_answered &&
                    i == _selectedOption &&
                    i != _correctOption)
                  const Icon(Icons.cancel,
                      color: Color(0xFFE74C3C), size: 20),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildNextButton(bool isDark) {
    return GestureDetector(
      onTap: _next,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C3CE1), Color(0xFF4A6FE3)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C3CE1).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          _questionIndex >= _total ? 'ফলাফল দেখুন' : 'পরের প্রশ্ন →',
          style: GoogleFonts.hindSiliguri(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
