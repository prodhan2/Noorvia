// ============================================================
//  developer_page.dart  —  App Developer Info Page
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';

class DeveloperPage extends StatelessWidget {
  const DeveloperPage({super.key});

  // ── Launch URL helper ─────────────────────────────────────
  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : Colors.white;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final sub = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Gradient Header ──────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.gradientStart,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C3CE1), Color(0xFF4A6FE3), Color(0xFF4A90D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),
                      // Avatar
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2.5),
                        ),
                        child: const Icon(Icons.person_rounded, size: 48, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Md. Rakibul Islam',
                        style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white,
                        ),
                      ),
                      Text(
                        'Flutter App Developer',
                        style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.white70, letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── About Card ───────────────────────────
                  _SectionCard(
                    card: card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(text: '👨‍💻 পরিচয়', textColor: text),
                        const SizedBox(height: 8),
                        Text(
                          'আমি একজন Flutter ডেভেলপার। ইসলামিক অ্যাপ তৈরি করা আমার প্যাশন। '
                          'নূরভিয়া অ্যাপটি মুসলিম ভাইবোনদের দৈনন্দিন ইসলামিক জীবনযাপনকে '
                          'সহজ করার লক্ষ্যে তৈরি করা হয়েছে।',
                          style: GoogleFonts.hindSiliguri(fontSize: 14, color: sub, height: 1.6),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Skills ───────────────────────────────
                  _SectionCard(
                    card: card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(text: '🛠️ দক্ষতা', textColor: text),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: const [
                            'Flutter', 'Dart', 'Firebase',
                            'REST API', 'Provider', 'Git',
                            'UI/UX Design', 'Android', 'iOS',
                          ].map((s) => _SkillChip(label: s)).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Projects ─────────────────────────────
                  _SectionCard(
                    card: card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(text: '📱 প্রজেক্টসমূহ', textColor: text),
                        const SizedBox(height: 12),
                        _ProjectTile(
                          icon: '🕌',
                          title: 'নূরভিয়া',
                          subtitle: 'ইসলামিক লাইফস্টাইল অ্যাপ — কুরআন, নামাজ, দু\'আ, যিকির',
                          tag: 'Flutter • Firebase',
                          textColor: text,
                          subColor: sub,
                        ),
                        const Divider(height: 20),
                        _ProjectTile(
                          icon: '📖',
                          title: 'Bangla Quran Reader',
                          subtitle: 'বাংলা অনুবাদ সহ সম্পূর্ণ কুরআন পাঠ অ্যাপ',
                          tag: 'Flutter • SQLite',
                          textColor: text,
                          subColor: sub,
                        ),
                        const Divider(height: 20),
                        _ProjectTile(
                          icon: '🧭',
                          title: 'Qibla Finder',
                          subtitle: 'GPS ও কম্পাস ব্যবহার করে কিবলা নির্দেশক',
                          tag: 'Flutter • Geolocator',
                          textColor: text,
                          subColor: sub,
                        ),
                        const Divider(height: 20),
                        _ProjectTile(
                          icon: '📿',
                          title: 'Digital Tasbeeh',
                          subtitle: 'ডিজিটাল তাসবিহ কাউন্টার — ভাইব্রেশন সহ',
                          tag: 'Flutter',
                          textColor: text,
                          subColor: sub,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Education ────────────────────────────
                  _SectionCard(
                    card: card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(text: '🎓 শিক্ষা', textColor: text),
                        const SizedBox(height: 12),
                        _EduTile(
                          icon: Icons.school_rounded,
                          degree: 'B.Sc in Computer Science',
                          institute: 'XYZ University',
                          year: '২০২০ – ২০২৪',
                          textColor: text,
                          subColor: sub,
                        ),
                        const SizedBox(height: 10),
                        _EduTile(
                          icon: Icons.code_rounded,
                          degree: 'Flutter Development Course',
                          institute: 'Udemy / Online',
                          year: '২০২২',
                          textColor: text,
                          subColor: sub,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Contact / Social ─────────────────────
                  _SectionCard(
                    card: card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(text: '🔗 যোগাযোগ', textColor: text),
                        const SizedBox(height: 12),
                        _ContactTile(
                          icon: Icons.email_outlined,
                          label: 'ইমেইল',
                          value: 'developer@noorvia.app',
                          color: const Color(0xFFEA4335),
                          onTap: () => _launch('mailto:developer@noorvia.app'),
                          subColor: sub,
                          textColor: text,
                        ),
                        _ContactTile(
                          icon: Icons.language_outlined,
                          label: 'ওয়েবসাইট',
                          value: 'noorvia.app',
                          color: AppColors.primary,
                          onTap: () => _launch('https://noorvia.app'),
                          subColor: sub,
                          textColor: text,
                        ),
                        _ContactTile(
                          icon: Icons.code_outlined,
                          label: 'GitHub',
                          value: 'github.com/noorvia-dev',
                          color: isDark ? Colors.white70 : Colors.black87,
                          onTap: () => _launch('https://github.com'),
                          subColor: sub,
                          textColor: text,
                        ),
                        _ContactTile(
                          icon: Icons.facebook_outlined,
                          label: 'Facebook',
                          value: 'fb.com/noorvia',
                          color: const Color(0xFF1877F2),
                          onTap: () => _launch('https://facebook.com'),
                          subColor: sub,
                          textColor: text,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── App Info ─────────────────────────────
                  _SectionCard(
                    card: card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(text: '📦 অ্যাপ তথ্য', textColor: text),
                        const SizedBox(height: 12),
                        _InfoRow(label: 'অ্যাপের নাম', value: 'নূরভিয়া (Noorvia)', textColor: text, subColor: sub),
                        _InfoRow(label: 'সংস্করণ', value: '১.০.০', textColor: text, subColor: sub),
                        _InfoRow(label: 'প্ল্যাটফর্ম', value: 'Android & iOS', textColor: text, subColor: sub),
                        _InfoRow(label: 'ফ্রেমওয়ার্ক', value: 'Flutter 3.x', textColor: text, subColor: sub),
                        _InfoRow(label: 'ব্যাকএন্ড', value: 'Firebase', textColor: text, subColor: sub),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Footer ───────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Made with ❤️ for Muslims',
                          style: GoogleFonts.poppins(fontSize: 13, color: sub),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '© 2024 Noorvia. All rights reserved.',
                          style: GoogleFonts.poppins(fontSize: 11, color: sub),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Reusable Widgets
// ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Color card;
  final Widget child;
  const _SectionCard({required this.card, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color textColor;
  const _SectionTitle({required this.text, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.hindSiliguri(
        fontSize: 16, fontWeight: FontWeight.w700, color: textColor,
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  const _SkillChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final String icon, title, subtitle, tag;
  final Color textColor, subColor;
  const _ProjectTile({
    required this.icon, required this.title, required this.subtitle,
    required this.tag, required this.textColor, required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 2),
              Text(subtitle, style: GoogleFonts.hindSiliguri(fontSize: 12, color: subColor, height: 1.4)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(tag, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EduTile extends StatelessWidget {
  final IconData icon;
  final String degree, institute, year;
  final Color textColor, subColor;
  const _EduTile({
    required this.icon, required this.degree, required this.institute,
    required this.year, required this.textColor, required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: AppColors.gradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(degree, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
              Text(institute, style: GoogleFonts.poppins(fontSize: 12, color: subColor)),
              Text(year, style: GoogleFonts.hindSiliguri(fontSize: 11, color: AppColors.primary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color, subColor, textColor;
  final VoidCallback onTap;
  const _ContactTile({
    required this.icon, required this.label, required this.value,
    required this.color, required this.onTap, required this.subColor, required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.hindSiliguri(fontSize: 11, color: subColor)),
                  Text(value, style: GoogleFonts.poppins(fontSize: 13, color: textColor, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: subColor),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final Color textColor, subColor;
  const _InfoRow({required this.label, required this.value, required this.textColor, required this.subColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.hindSiliguri(fontSize: 13, color: subColor)),
          Text(value, style: GoogleFonts.poppins(fontSize: 13, color: textColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
