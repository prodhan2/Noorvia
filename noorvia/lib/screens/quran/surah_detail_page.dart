import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';

// ─── Data model ───────────────────────────────────────────────────────────────

class Ayah {
  final int number;
  final String arabic;
  final String transliteration;
  final String bangla;

  const Ayah({
    required this.number,
    required this.arabic,
    required this.transliteration,
    required this.bangla,
  });
}

// Sample ayahs for Al-Fatiha (full) and placeholder for others
const Map<int, List<Ayah>> _surahAyahs = {
  1: [
    Ayah(
      number: 1,
      arabic: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      transliteration: 'Bismillāhir-raḥmānir-raḥīm',
      bangla: 'পরম করুণাময় অতি দয়ালু আল্লাহর নামে।',
    ),
    Ayah(
      number: 2,
      arabic: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
      transliteration: 'Al-ḥamdu lillāhi rabbil-ʿālamīn',
      bangla: 'সমস্ত প্রশংসা আল্লাহর জন্য, যিনি সকল সৃষ্টির প্রতিপালক।',
    ),
    Ayah(
      number: 3,
      arabic: 'الرَّحْمَٰنِ الرَّحِيمِ',
      transliteration: 'Ar-raḥmānir-raḥīm',
      bangla: 'যিনি পরম করুণাময়, অতি দয়ালু।',
    ),
    Ayah(
      number: 4,
      arabic: 'مَالِكِ يَوْمِ الدِّينِ',
      transliteration: 'Māliki yawmid-dīn',
      bangla: 'যিনি বিচার দিনের মালিক।',
    ),
    Ayah(
      number: 5,
      arabic: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
      transliteration: 'Iyyāka naʿbudu wa-iyyāka nastaʿīn',
      bangla: 'আমরা কেবল তোমারই ইবাদত করি এবং কেবল তোমারই সাহায্য চাই।',
    ),
    Ayah(
      number: 6,
      arabic: 'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
      transliteration: 'Ihdinaṣ-ṣirāṭal-mustaqīm',
      bangla: 'আমাদের সরল পথ দেখাও।',
    ),
    Ayah(
      number: 7,
      arabic:
          'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
      transliteration:
          'Ṣirāṭal-ladhīna anʿamta ʿalayhim ghayril-maghḍūbi ʿalayhim wa-laḍ-ḍāllīn',
      bangla:
          'তাদের পথ, যাদের তুমি নিয়ামত দিয়েছ; তাদের পথ নয় যাদের উপর তোমার ক্রোধ হয়েছে এবং যারা পথভ্রষ্ট।',
    ),
  ],
};

List<Ayah> _getAyahs(int surahNumber, int ayatCount) {
  if (_surahAyahs.containsKey(surahNumber)) {
    return _surahAyahs[surahNumber]!;
  }
  // Generate placeholder ayahs for other surahs
  return List.generate(
    ayatCount > 10 ? 10 : ayatCount,
    (i) => Ayah(
      number: i + 1,
      arabic: 'آيَةٌ كَرِيمَةٌ',
      transliteration: 'Āyatun karīmah',
      bangla: 'এই সূরার ${i + 1} নম্বর আয়াত। সম্পূর্ণ ডেটা শীঘ্রই যোগ হবে।',
    ),
  );
}

// ─── SurahDetailPage ──────────────────────────────────────────────────────────

class SurahDetailPage extends StatefulWidget {
  final String surahName;
  final String arabicName;
  final int surahNumber;
  final int ayatCount;
  final String type;

  const SurahDetailPage({
    super.key,
    required this.surahName,
    required this.arabicName,
    required this.surahNumber,
    required this.ayatCount,
    required this.type,
  });

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  bool _showTransliteration = true;
  bool _showTranslation = true;
  double _arabicFontSize = 26;
  late List<Ayah> _ayahs;
  final Set<int> _bookmarked = {};

  @override
  void initState() {
    super.initState();
    _ayahs = _getAyahs(widget.surahNumber, widget.ayatCount);
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(isDark, cardColor, textColor, subColor),
        ],
        body: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          itemCount: _ayahs.length,
          itemBuilder: (context, index) {
            return _buildAyahCard(
                _ayahs[index], isDark, cardColor, textColor, subColor);
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark, Color cardColor, Color textColor,
      Color subColor) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Font size controls
        IconButton(
          icon: const Icon(Icons.text_decrease, color: Colors.white, size: 20),
          onPressed: () =>
              setState(() => _arabicFontSize = (_arabicFontSize - 2).clamp(18, 40)),
        ),
        IconButton(
          icon: const Icon(Icons.text_increase, color: Colors.white, size: 20),
          onPressed: () =>
              setState(() => _arabicFontSize = (_arabicFontSize + 2).clamp(18, 40)),
        ),
        // Settings popup
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (val) {
            if (val == 'trans') {
              setState(() => _showTransliteration = !_showTransliteration);
            } else if (val == 'bangla') {
              setState(() => _showTranslation = !_showTranslation);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'trans',
              child: Row(children: [
                Icon(
                  _showTransliteration
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text('উচ্চারণ দেখান'),
              ]),
            ),
            PopupMenuItem(
              value: 'bangla',
              child: Row(children: [
                Icon(
                  _showTranslation
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text('অনুবাদ দেখান'),
              ]),
            ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F4D2A), Color(0xFF2E8B57)],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Arabic name
                Text(
                  widget.arabicName,
                  style: const TextStyle(
                    fontSize: 36,
                    color: Colors.white,
                    fontFamily: 'serif',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.surahName,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _infoPill('সূরা ${widget.surahNumber}'),
                    const SizedBox(width: 8),
                    _infoPill('${widget.ayatCount} আয়াত'),
                    const SizedBox(width: 8),
                    _infoPill(widget.type),
                  ],
                ),
                const SizedBox(height: 12),
                // Bismillah
                if (widget.surahNumber != 1 && widget.surahNumber != 9)
                  Text(
                    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      fontFamily: 'serif',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.hindSiliguri(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAyahCard(Ayah ayah, bool isDark, Color cardColor,
      Color textColor, Color subColor) {
    final isBookmarked = _bookmarked.contains(ayah.number);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ayah header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Ayah number badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _toBangla(ayah.number.toString()),
                      style: GoogleFonts.hindSiliguri(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Action icons
                _ayahAction(
                  icon: Icons.copy_outlined,
                  tooltip: 'কপি',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: ayah.arabic));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'আয়াত কপি হয়েছে',
                          style: GoogleFonts.hindSiliguri(),
                        ),
                        duration: const Duration(seconds: 1),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
                _ayahAction(
                  icon: isBookmarked
                      ? Icons.bookmark
                      : Icons.bookmark_border_outlined,
                  tooltip: 'বুকমার্ক',
                  color: isBookmarked ? AppColors.gold : null,
                  onTap: () {
                    setState(() {
                      if (isBookmarked) {
                        _bookmarked.remove(ayah.number);
                      } else {
                        _bookmarked.add(ayah.number);
                      }
                    });
                  },
                ),
                const SizedBox(width: 4),
                _ayahAction(
                  icon: Icons.share_outlined,
                  tooltip: 'শেয়ার',
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Arabic text
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              ayah.arabic,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: _arabicFontSize,
                color: isDark ? AppColors.darkText : const Color(0xFF1A1A2E),
                height: 2.0,
                fontFamily: 'serif',
              ),
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              color: AppColors.primary.withValues(alpha: 0.15),
              height: 1,
            ),
          ),

          // Transliteration
          if (_showTransliteration)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(
                ayah.transliteration,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
              ),
            ),

          // Bangla translation
          if (_showTranslation)
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, _showTransliteration ? 4 : 10, 16, 16),
              child: Text(
                ayah.bangla,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
                  height: 1.7,
                ),
              ),
            ),

          if (!_showTransliteration && !_showTranslation)
            const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _ayahAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 15,
            color: color ?? AppColors.primary,
          ),
        ),
      ),
    );
  }

  String _toBangla(String s) {
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    for (int i = 0; i < en.length; i++) {
      s = s.replaceAll(en[i], bn[i]);
    }
    return s;
  }
}
