import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import 'ruqyah_list_page.dart';

class RuqyahDetailPage extends StatefulWidget {
  final RuqyahChapter chapter;
  final List<RuqyahChapter> allChapters;
  final int currentIndex;

  const RuqyahDetailPage({
    super.key,
    required this.chapter,
    required this.allChapters,
    required this.currentIndex,
  });

  @override
  State<RuqyahDetailPage> createState() => _RuqyahDetailPageState();
}

class _RuqyahDetailPageState extends State<RuqyahDetailPage> {
  late int _currentIndex;
  late PageController _pageController;
  double _fontSize = 15.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  RuqyahChapter get _current => widget.allChapters[_currentIndex];

  bool get _hasPrev => _currentIndex > 0;
  bool get _hasNext => _currentIndex < widget.allChapters.length - 1;

  void _goTo(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Converts body text to paragraphs (handles both real \n and escaped \\n)
  List<String> _getParagraphs(String body) {
    return body
        .replaceAll('\\n', '\n')
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.allChapters.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) {
          final chapter = widget.allChapters[index];
          final paragraphs = _getParagraphs(chapter.body);
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: paragraphs.length,
            itemBuilder: (context, pIndex) {
              final para = paragraphs[pIndex];
              final isArabic = _isArabicText(para);
              final isHeading = _isHeading(para);

              if (isArabic) {
                return _ArabicBlock(
                  text: para,
                  isDark: isDark,
                  cardColor: cardColor,
                );
              }

              if (isHeading) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 8),
                  child: Text(
                    para,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: _fontSize + 1,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      height: 1.5,
                    ),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  para,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: _fontSize,
                    color: textColor,
                    height: 1.8,
                  ),
                ),
              );
            },
          );
        },
      ),

      // ── Bottom navigation ──────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Prev button
                _NavButton(
                  label: 'পূর্ববর্তী',
                  icon: Icons.arrow_back_ios,
                  enabled: _hasPrev,
                  onTap: _hasPrev ? () => _goTo(_currentIndex - 1) : null,
                  isDark: isDark,
                ),
                const Spacer(),
                // Page indicator dots
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    widget.allChapters.length > 7
                        ? 7
                        : widget.allChapters.length,
                    (i) {
                      final actualIndex = widget.allChapters.length > 7
                          ? (_currentIndex - 3 + i)
                              .clamp(0, widget.allChapters.length - 1)
                          : i;
                      final isActive = actualIndex == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: isActive ? AppColors.gradient : null,
                          color: isActive
                              ? null
                              : AppColors.primary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    },
                  ),
                ),
                const Spacer(),
                // Next button
                _NavButton(
                  label: 'পরবর্তী',
                  icon: Icons.arrow_forward_ios,
                  enabled: _hasNext,
                  isNext: true,
                  onTap: _hasNext ? () => _goTo(_currentIndex + 1) : null,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
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
          Text(
            _current.title,
            style: GoogleFonts.hindSiliguri(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black, height: 1.2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text('${_currentIndex + 1} / ${widget.allChapters.length}', style: GoogleFonts.hindSiliguri(fontSize: 10, color: Colors.black, height: 1.2)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.text_decrease, color: Colors.black, size: 18),
          onPressed: () {
            if (_fontSize > 12) setState(() => _fontSize -= 1);
          },
          tooltip: 'ছোট',
        ),
        Center(
          child: Text(
            '${_fontSize.toInt()}',
            style: GoogleFonts.poppins(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.text_increase, color: Colors.black, size: 18),
          onPressed: () {
            if (_fontSize < 22) setState(() => _fontSize += 1);
          },
          tooltip: 'বড়',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  bool _isArabicText(String text) {
    // Check if text contains Arabic Unicode characters
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  bool _isHeading(String para) {
    // Treat short lines ending with : or starting with numbered list as headings
    if (para.length < 60 && (para.endsWith(':') || para.endsWith('—'))) {
      return true;
    }
    if (RegExp(r'^[০-৯]+[।\.]').hasMatch(para) && para.length < 80) {
      return false; // numbered list item, not heading
    }
    return false;
  }
}

class _ArabicBlock extends StatelessWidget {
  final String text;
  final bool isDark;
  final Color cardColor;

  const _ArabicBlock({
    required this.text,
    required this.isDark,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
          fontFamily: 'Amiri',
          fontSize: 20,
          height: 2.0,
          color: Color(0xFF6C3CE1),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final bool isNext;
  final VoidCallback? onTap;
  final bool isDark;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.isDark,
    this.isNext = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.35,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: enabled ? AppColors.gradient : null,
            color: enabled ? null : (isDark ? AppColors.darkCard : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: isNext
                ? [
                    Text(
                      label,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: enabled ? Colors.white : AppColors.lightSubText,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(icon,
                        size: 13,
                        color: enabled ? Colors.white : AppColors.lightSubText),
                  ]
                : [
                    Icon(icon,
                        size: 13,
                        color: enabled ? Colors.white : AppColors.lightSubText),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: enabled ? Colors.white : AppColors.lightSubText,
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}
