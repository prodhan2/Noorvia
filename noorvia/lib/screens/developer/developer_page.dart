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

class DeveloperPage extends StatefulWidget {
  const DeveloperPage({super.key});

  @override
  State<DeveloperPage> createState() => _DeveloperPageState();
}

class _DeveloperPageState extends State<DeveloperPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
          // ── Hero AppBar ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.gradientStart,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: _HeroHeader(),
            ),
          ),

          // ── Body ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats row
                      _StatsRow(card: card, text: text, sub: sub),
                      const SizedBox(height: 16),

                      // About
                      _SectionCard(
                        card: card,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle('👨‍💻 পরিচয়', text),
                            const SizedBox(height: 10),
                            Text(
                              'আমি একজন Flutter ডেভেলপার। ইসলামিক অ্যাপ তৈরি করা আমার প্যাশন। '
                              'নূরভিয়া অ্যাপটি মুসলিম ভাই-বোনদের দৈনন্দিন ইসলামিক জীবনযাপনকে '
                              'সহজ করার লক্ষ্যে তৈরি করা হয়েছে।',
                              style: GoogleFonts.hindSiliguri(
                                  fontSize: 14, color: sub, height: 1.7),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Skills
                      _SectionCard(
                        card: card,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle('🛠️ দক্ষতা', text),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: const [
                                'Flutter',
                                'Dart',
                                'Firebase',
                                'REST API',
                                'Provider',
                                'Git',
                                'UI/UX Design',
                                'Android',
                                'iOS',
                              ].map((s) => _SkillChip(label: s)).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Projects
                      _SectionCard(
                        card: card,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle('📱 প্রজেক্টসমূহ', text),
                            const SizedBox(height: 10),
                            _ProjectTile(
                              icon: '🕌',
                              title: 'নূরভিয়া',
                              subtitle:
                                  'ইসলামিক লাইফস্টাইল অ্যাপ — কুরআন, নামাজ, দু\'আ, যিকির',
                              color: AppColors.primary,
                              text: text,
                              sub: sub,
                            ),
                            const Divider(height: 20),
                            _ProjectTile(
                              icon: '📖',
                              title: 'বাংলা কুরআন',
                              subtitle:
                                  'বাংলা অনুবাদ সহ সম্পূর্ণ কুরআন রিডার',
                              color: AppColors.amolColor,
                              text: text,
                              sub: sub,
                            ),
                            const Divider(height: 20),
                            _ProjectTile(
                              icon: '🤲',
                              title: 'দু\'আ সংকলন',
                              subtitle: 'দৈনন্দিন দু\'আ ও আমলের সংকলন',
                              color: AppColors.sebaColor,
                              text: text,
                              sub: sub,
                            ),
                            const Divider(height: 20),
                            _ProjectTile(
                              icon: '🧮',
                              title: 'ইসলামিক টুলস',
                              subtitle:
                                  'কিবলা, যাকাত ক্যালকুলেটর, ইসলামিক ক্যালেন্ডার',
                              color: AppColors.bibidhoColor,
                              text: text,
                              sub: sub,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Education
                      _SectionCard(
                        card: card,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle('🎓 শিক্ষা', text),
                            const SizedBox(height: 10),
                            _EduTile(
                              year: '২০২০ – ২০২৪',
                              degree: 'BSc in Computer Science',
                              institute: 'XYZ University, Bangladesh',
                              text: text,
                              sub: sub,
                            ),
                            const Divider(height: 20),
                            _EduTile(
                              year: '২০১৮ – ২০২০',
                              degree: 'HSC — বিজ্ঞান বিভাগ',
                              institute: 'ABC College, Dhaka',
                              text: text,
                              sub: sub,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Contact
                      _SectionCard(
                        card: card,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle('📬 যোগাযোগ', text),
                            const SizedBox(height: 10),
                            _ContactTile(
                              icon: Icons.email_outlined,
                              label: 'ইমেইল',
                              value: 'dev@noorvia.app',
                              color: const Color(0xFFEA4335),
                              onTap: () => _launch('mailto:dev@noorvia.app'),
                              text: text,
                              sub: sub,
                            ),
                            _ContactTile(
                              icon: Icons.language_outlined,
                              label: 'ওয়েবসাইট',
                              value: 'www.noorvia.app',
                              color: AppColors.primary,
                              onTap: () => _launch('https://noorvia.app'),
                              text: text,
                              sub: sub,
                            ),
                            _ContactTile(
                              icon: Icons.code_outlined,
                              label: 'GitHub',
                              value: 'github.com/noorvia-dev',
                              color: isDark ? Colors.white70 : Colors.black87,
                              onTap: () => _launch('https://github.com'),
                              text: text,
                              sub: sub,
                            ),
                            _ContactTile(
                              icon: Icons.facebook_outlined,
                              label: 'Facebook',
                              value: 'fb.com/noorvia',
                              color: const Color(0xFF1877F2),
                              onTap: () => _launch('https://facebook.com'),
                              text: text,
                              sub: sub,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // App Info
                      _SectionCard(
                        card: card,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle('ℹ️ অ্যাপ তথ্য', text),
                            const SizedBox(height: 10),
                            _InfoRow(
                                label: 'সংস্করণ',
                                value: '১.০.০',
                                text: text,
                                sub: sub),
                            _InfoRow(
                                label: 'প্ল্যাটফর্ম',
                                value: 'Android & iOS',
                                text: text,
                                sub: sub),
                            _InfoRow(
                                label: 'ফ্রেমওয়ার্ক',
                                value: 'Flutter 3.x',
                                text: text,
                                sub: sub),
                            _InfoRow(
                                label: 'ভাষা',
                                value: 'Dart',
                                text: text,
                                sub: sub),
                            _InfoRow(
                                label: 'ব্যাকএন্ড',
                                value: 'Firebase',
                                text: text,
                                sub: sub),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Footer
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: AppColors.gradient,
                                shape: BoxShape.circle,
                              ),
                              child: const Text('🕌',
                                  style: TextStyle(fontSize: 26)),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'নূরভিয়া — আল্লাহর রহমতে তৈরি',
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 13,
                                color: sub,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '© 2024 Noorvia. All rights reserved.',
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: sub),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Hero Header
// ─────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A2BAD), Color(0xFF6C3CE1), Color(0xFF4A6FE3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar with ring
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.9),
                          Colors.white.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF7B4FE8), Color(0xFF5B8DEF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.person_rounded,
                          size: 52, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Md. Rakibul Islam',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Flutter App Developer',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Quick social icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialBtn(
                        icon: Icons.email_rounded,
                        onTap: () {},
                      ),
                      const SizedBox(width: 10),
                      _SocialBtn(
                        icon: Icons.language_rounded,
                        onTap: () {},
                      ),
                      const SizedBox(width: 10),
                      _SocialBtn(
                        icon: Icons.code_rounded,
                        onTap: () {},
                      ),
                      const SizedBox(width: 10),
                      _SocialBtn(
                        icon: Icons.facebook_rounded,
                        onTap: () {},
                      ),
                    ],
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

class _SocialBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SocialBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Stats Row
// ─────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final Color card, text, sub;
  const _StatsRow(
      {required this.card, required this.text, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
            card: card,
            text: text,
            sub: sub,
            value: '৪+',
            label: 'প্রজেক্ট'),
        const SizedBox(width: 10),
        _StatCard(
            card: card,
            text: text,
            sub: sub,
            value: '২+',
            label: 'বছর অভিজ্ঞতা'),
        const SizedBox(width: 10),
        _StatCard(
            card: card,
            text: text,
            sub: sub,
            value: '১০K+',
            label: 'ব্যবহারকারী'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final Color card, text, sub;
  final String value, label;
  const _StatCard({
    required this.card,
    required this.text,
    required this.sub,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.gradient.createShader(bounds),
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.hindSiliguri(fontSize: 11, color: sub),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Reusable widgets
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
  final String title;
  final Color color;
  const _SectionTitle(this.title, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: AppColors.gradient,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.hindSiliguri(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
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
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final String icon, title, subtitle;
  final Color color, text, sub;
  const _ProjectTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.text,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.hindSiliguri(fontSize: 12, color: sub),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios_rounded, size: 13, color: sub),
      ],
    );
  }
}

class _EduTile extends StatelessWidget {
  final String year, degree, institute;
  final Color text, sub;
  const _EduTile({
    required this.year,
    required this.degree,
    required this.institute,
    required this.text,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: AppColors.gradient,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                degree,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                institute,
                style: GoogleFonts.hindSiliguri(fontSize: 12, color: sub),
              ),
              const SizedBox(height: 3),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  year,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
  final Color color, text, sub;
  final VoidCallback onTap;
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
    required this.text,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.hindSiliguri(
                          fontSize: 12, color: sub),
                    ),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: text,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 13, color: sub),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final Color text, sub;
  const _InfoRow(
      {required this.label,
      required this.value,
      required this.text,
      required this.sub});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.hindSiliguri(fontSize: 14, color: sub),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
