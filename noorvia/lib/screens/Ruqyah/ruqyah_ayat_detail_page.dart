import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import 'ruqyah_list_page.dart';

class RuqyahAyatDetailPage extends StatefulWidget {
  final RuqyahAyatGroup group;
  final List<RuqyahAyatGroup> allGroups;
  final int currentIndex;

  const RuqyahAyatDetailPage({
    super.key,
    required this.group,
    required this.allGroups,
    required this.currentIndex,
  });

  @override
  State<RuqyahAyatDetailPage> createState() => _RuqyahAyatDetailPageState();
}

class _RuqyahAyatDetailPageState extends State<RuqyahAyatDetailPage> {
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

  RuqyahAyatGroup get _current => widget.allGroups[_currentIndex];

  bool get _hasPrev => _currentIndex > 0;
  bool get _hasNext => _currentIndex < widget.allGroups.length - 1;

  void _goTo(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.allGroups.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, pageIndex) {
          final group = widget.allGroups[pageIndex];
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: group.ayahs.length + (group.subtitle.isNotEmpty ? 1 : 0),
            itemBuilder: (context, i) {
              // Subtitle header
              if (group.subtitle.isNotEmpty && i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    group.subtitle,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      height: 1.6,
                    ),
                  ),
                );
              }

              final ayahIndex =
                  group.subtitle.isNotEmpty ? i - 1 : i;
              final ayah = group.ayahs[ayahIndex];

              return _AyahCard(
                ayah: ayah,
                isDark: isDark,
                cardColor: cardColor,
                textColor: textColor,
                subColor: subColor,
                fontSize: _fontSize,
              );
            },
          );
        },
      ),

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
                _NavButton(
                  label: 'পূর্ববর্তী',
                  icon: Icons.arrow_back_ios,
                  enabled: _hasPrev,
                  onTap: _hasPrev ? () => _goTo(_currentIndex - 1) : null,
                  isDark: isDark,
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    widget.allGroups.length > 7 ? 7 : widget.allGroups.length,
                    (i) {
                      final actualIndex = widget.allGroups.length > 7
                          ? (_currentIndex - 3 + i)
                              .clamp(0, widget.allGroups.length - 1)
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
          Text('${_currentIndex + 1} / ${widget.allGroups.length}', style: GoogleFonts.hindSiliguri(fontSize: 10, color: Colors.black, height: 1.2)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.text_decrease, color: Colors.black, size: 18),
          onPressed: () { if (_fontSize > 12) setState(() => _fontSize -= 1); },
          tooltip: 'ছোট',
        ),
        Center(
          child: Text('${_fontSize.toInt()}', style: GoogleFonts.poppins(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        IconButton(
          icon: const Icon(Icons.text_increase, color: Colors.black, size: 18),
          onPressed: () { if (_fontSize < 22) setState(() => _fontSize += 1); },
          tooltip: 'বড়',
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ─── Ayah Card ────────────────────────────────────────────────────────────────

class _AyahCard extends StatelessWidget {
  final RuqyahAyah ayah;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final double fontSize;

  const _AyahCard({
    required this.ayah,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ayah number badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${ayah.ayahNumber}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (ayah.ayahTitle != null && ayah.ayahTitle!.isNotEmpty)
                  Expanded(
                    child: Text(
                      ayah.ayahTitle!,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Arabic text
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    ayah.ayahArabic,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 22,
                      height: 2.0,
                      color: Color(0xFF6C3CE1),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Bangla translation
                Text(
                  ayah.ayahBangla,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: fontSize,
                    color: textColor,
                    height: 1.8,
                  ),
                ),

                // Note (if any)
                if (ayah.ayahNote != null && ayah.ayahNote!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 16, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ayah.ayahNote!,
                            style: GoogleFonts.hindSiliguri(
                              fontSize: fontSize - 1,
                              color: subColor,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nav Button ───────────────────────────────────────────────────────────────

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
            color: enabled
                ? null
                : (isDark ? AppColors.darkCard : Colors.grey.shade200),
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
                        color:
                            enabled ? Colors.white : AppColors.lightSubText,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(icon,
                        size: 13,
                        color: enabled
                            ? Colors.white
                            : AppColors.lightSubText),
                  ]
                : [
                    Icon(icon,
                        size: 13,
                        color: enabled
                            ? Colors.white
                            : AppColors.lightSubText),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            enabled ? Colors.white : AppColors.lightSubText,
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}
