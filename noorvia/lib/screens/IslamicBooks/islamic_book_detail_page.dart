import 'package:flutter/material.dart' hide Text;
import 'package:muslim_view/core/localization/localized_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import 'islamic_books_page.dart';

class IslamicBookDetailPage extends StatefulWidget {
  final BookNode book;
  final List<BookNode> allBooks;
  final int currentIndex;

  const IslamicBookDetailPage({
    super.key,
    required this.book,
    required this.allBooks,
    required this.currentIndex,
  });

  @override
  State<IslamicBookDetailPage> createState() => _IslamicBookDetailPageState();
}

class _IslamicBookDetailPageState extends State<IslamicBookDetailPage> {
  late int _currentIndex;
  late BookNode _book;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _book = widget.book;
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.allBooks.length) return;
    setState(() {
      _currentIndex = index;
      _book = widget.allBooks[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    final hasPrev = _currentIndex > 0;
    final hasNext = _currentIndex < widget.allBooks.length - 1;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.gradient),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'কিতাবের বিবরণ',
          style: GoogleFonts.hindSiliguri(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                '${_currentIndex + 1} / ${widget.allBooks.length}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Content ──────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Cover card ────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppColors.gradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '📖',
                          style: const TextStyle(fontSize: 56),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _book.name,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Navigation ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Previous
                Expanded(
                  child: TextButton.icon(
                    onPressed: hasPrev ? () => _goTo(_currentIndex - 1) : null,
                    icon: Icon(
                      Icons.arrow_back_ios,
                      size: 14,
                      color: hasPrev ? AppColors.primary : subColor,
                    ),
                    label: Text(
                      'আগের কিতাব',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: hasPrev ? AppColors.primary : subColor,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),

                // Divider
                Container(
                  width: 1,
                  height: 32,
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),

                // Next
                Expanded(
                  child: TextButton.icon(
                    onPressed: hasNext ? () => _goTo(_currentIndex + 1) : null,
                    icon: Text(
                      'পরের কিতাব',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: hasNext ? AppColors.primary : subColor,
                      ),
                    ),
                    label: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: hasNext ? AppColors.primary : subColor,
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
