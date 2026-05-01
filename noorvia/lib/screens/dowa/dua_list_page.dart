// ============================================================
//  dua_list_page.dart
//  একটি category-র সব দু'আ দেখায়
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import 'dowa_screen.dart';

class DuaListPage extends StatelessWidget {
  final DuaCategory category;

  const DuaListPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              category.title,
              style: GoogleFonts.hindSiliguri(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
      ),
      body: category.duas.isEmpty
          ? Center(
              child: Text(
                'কোনো দু\'আ পাওয়া যায়নি',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: category.duas.length,
              itemBuilder: (context, index) {
                final dua = category.duas[index];
                return _DuaCard(
                  dua: dua,
                  index: index,
                  cardColor: cardColor,
                  textColor: textColor,
                  isDark: isDark,
                );
              },
            ),
    );
  }
}

// ─── Dua Card ─────────────────────────────────────────────────

class _DuaCard extends StatefulWidget {
  final DuaItem dua;
  final int index;
  final Color cardColor;
  final Color textColor;
  final bool isDark;

  const _DuaCard({
    required this.dua,
    required this.index,
    required this.cardColor,
    required this.textColor,
    required this.isDark,
  });

  @override
  State<_DuaCard> createState() => _DuaCardState();
}

class _DuaCardState extends State<_DuaCard> {
  bool _expanded = false;

  void _copyToClipboard(BuildContext context) {
    final text =
        '${widget.dua.arabic}\n\n${widget.dua.transliteration}\n\n${widget.dua.translation}\n\nসূত্র: ${widget.dua.reference}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'দু\'আ কপি হয়েছে',
          style: GoogleFonts.hindSiliguri(),
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dua = widget.dua;
    final subtleColor = widget.isDark ? Colors.white38 : Colors.black38;
    final dividerColor = widget.isDark ? Colors.white12 : Colors.black12;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Number badge + Title ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    dua.title,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: widget.textColor,
                    ),
                  ),
                ),
                // Copy button
                GestureDetector(
                  onTap: () => _copyToClipboard(context),
                  child: Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: subtleColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Arabic Text ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              border: Border(
                left: BorderSide(color: AppColors.primary, width: 3),
              ),
            ),
            child: Text(
              dua.arabic,
              style: const TextStyle(
                fontSize: 20,
                height: 2.0,
                color: Color(0xFF1B5E20),
                fontFamily: 'serif',
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),

          // ── Transliteration ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Text(
              dua.transliteration,
              style: GoogleFonts.hindSiliguri(
                fontSize: 13,
                color: AppColors.primary,
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
          ),

          // ── Translation ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Text(
              dua.translation,
              style: GoogleFonts.hindSiliguri(
                fontSize: 14,
                color: widget.textColor,
                height: 1.6,
              ),
            ),
          ),

          // ── Reference ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Row(
              children: [
                Icon(Icons.bookmark_rounded,
                    size: 14, color: AppColors.primary.withOpacity(0.7)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    dua.reference,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 12,
                      color: AppColors.primary.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Expandable: Virtue + Note ──
          if (dua.virtue.isNotEmpty || dua.note != null) ...[
            Divider(height: 20, color: dividerColor, indent: 14, endIndent: 14),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: subtleColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ফজিলত ও বিশেষ নোট',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 12,
                            color: subtleColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (_expanded) ...[
                      const SizedBox(height: 8),
                      if (dua.virtue.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('✨ ',
                                  style: TextStyle(fontSize: 14)),
                              Expanded(
                                child: Text(
                                  dua.virtue,
                                  style: GoogleFonts.hindSiliguri(
                                    fontSize: 13,
                                    color: widget.textColor,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (dua.note != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('📝 ',
                                  style: TextStyle(fontSize: 14)),
                              Expanded(
                                child: Text(
                                  dua.note!,
                                  style: GoogleFonts.hindSiliguri(
                                    fontSize: 13,
                                    color: widget.textColor,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ] else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}
