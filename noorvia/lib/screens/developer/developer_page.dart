// ============================================================
//  developer_page.dart  —  Developer Team Page
//  Data source: GitHub raw JSON (remote fetch + cache)
//  Features: Offline support, background refresh, modern UI
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';

const _kDeveloperJsonUrl =
    'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/APPdeveloer/developer.json';
const _kCacheKey = 'cached_developers_json';
const _kCacheTimeKey = 'cached_developers_time';

// ─────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────
class _University {
  final String name;
  final String? logo;

  const _University({required this.name, this.logo});

  factory _University.fromJson(Map<String, dynamic> j) => _University(
        name: j['name'] as String,
        logo: j['logo'] as String?,
      );
}

class _SocialLink {
  final String url;
  final String icon;

  const _SocialLink({required this.url, required this.icon});

  factory _SocialLink.fromJson(Map<String, dynamic> j) => _SocialLink(
        url: j['url'] as String,
        icon: j['icon'] as String,
      );
}

class _Socials {
  final _SocialLink facebook;
  final _SocialLink telegram;
  final _SocialLink whatsapp;

  const _Socials({
    required this.facebook,
    required this.telegram,
    required this.whatsapp,
  });

  factory _Socials.fromJson(Map<String, dynamic> j) => _Socials(
        facebook: _SocialLink.fromJson(j['facebook'] as Map<String, dynamic>),
        telegram: _SocialLink.fromJson(j['telegram'] as Map<String, dynamic>),
        whatsapp: _SocialLink.fromJson(j['whatsapp'] as Map<String, dynamic>),
      );
}

class _DevStats {
  final int projects;
  final double rating;
  final int ratingCount;
  final String experience;
  final String downloads;

  const _DevStats({
    required this.projects,
    required this.rating,
    required this.ratingCount,
    required this.experience,
    required this.downloads,
  });

  factory _DevStats.fromJson(Map<String, dynamic> j) => _DevStats(
        projects: j['projects'] as int,
        rating: (j['rating'] as num).toDouble(),
        ratingCount: j['ratingCount'] as int,
        experience: j['experience'] as String,
        downloads: j['downloads'] as String,
      );
}

class _Developer {
  final int id;
  final String name;
  final String role;
  final String location;
  final String email;
  final String phone;
  final String github;
  final String website;
  final String? avatar;
  final bool isOnline;
  final String profileUrl;
  final _University university;
  final _Socials socials;
  final _DevStats stats;
  final List<String> skills;
  final String bio;

  const _Developer({
    required this.id,
    required this.name,
    required this.role,
    required this.location,
    required this.email,
    required this.phone,
    required this.github,
    required this.website,
    this.avatar,
    required this.isOnline,
    required this.profileUrl,
    required this.university,
    required this.socials,
    required this.stats,
    required this.skills,
    required this.bio,
  });

  factory _Developer.fromJson(Map<String, dynamic> j) => _Developer(
        id: j['id'] as int,
        name: j['name'] as String,
        role: j['role'] as String,
        location: j['location'] as String,
        email: j['email'] as String,
        phone: j['phone'] as String,
        github: j['github'] as String,
        website: j['website'] as String,
        avatar: j['avatar'] as String?,
        isOnline: j['isOnline'] as bool,
        profileUrl: j['profileUrl'] as String,
        university: _University.fromJson(j['university'] as Map<String, dynamic>),
        socials: _Socials.fromJson(j['socials'] as Map<String, dynamic>),
        stats: _DevStats.fromJson(j['stats'] as Map<String, dynamic>),
        skills: List<String>.from(j['skills'] as List),
        bio: j['bio'] as String,
      );
}

// ─────────────────────────────────────────────────────────────
// Accent colors per developer index
// ─────────────────────────────────────────────────────────────
const _accentColors = [
  Color(0xFF6C3CE1), // purple
  Color(0xFF4A6FE3), // blue
  Color(0xFF0891B2), // teal
  Color(0xFF7C3AED), // violet
];

Color _accentFor(int index) => _accentColors[index % _accentColors.length];

// ─────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────
class DeveloperPage extends StatefulWidget {
  const DeveloperPage({super.key});

  @override
  State<DeveloperPage> createState() => _DeveloperPageState();
}

class _DeveloperPageState extends State<DeveloperPage> {
  List<_Developer> _devs = [];
  bool _loading = true;
  bool _isFromCache = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. Try to load from cache first (instant display)
    await _loadFromCache();

    // 2. Then fetch from network in background
    await _fetchFromNetwork();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_kCacheKey);
      if (cached != null) {
        final json = jsonDecode(cached) as Map<String, dynamic>;
        final list = (json['developers'] as List)
            .map((e) => _Developer.fromJson(e as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() {
            _devs = list;
            _loading = false;
            _isFromCache = true;
          });
        }
      }
    } catch (e) {
      // Cache load failed, continue to network
    }
  }

  Future<void> _fetchFromNetwork() async {
    try {
      final response = await http
          .get(Uri.parse(_kDeveloperJsonUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (json['developers'] as List)
          .map((e) => _Developer.fromJson(e as Map<String, dynamic>))
          .toList();

      // Save to cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCacheKey, response.body);
      await prefs.setInt(_kCacheTimeKey, DateTime.now().millisecondsSinceEpoch);

      if (mounted) {
        setState(() {
          _devs = list;
          _loading = false;
          _isFromCache = false;
          _error = null;
        });
      }
    } catch (e) {
      // Network failed — if we have cache, keep showing it
      if (_devs.isEmpty && mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
      // If we already have cached data, silently fail (data still visible)
    }
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
    final bg = isDark ? AppColors.darkBg : const Color(0xFFF7F7FB);
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final sub = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(isDark, text),
      body: _loading && _devs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _devs.isEmpty
              ? _ErrorView(onRetry: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _loadData();
                })
              : ListView(
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Header Section
                    _HeaderSection(isDark: isDark, text: text, sub: sub),
                    
                    // Developer Cards
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      child: Column(
                        children: List.generate(
                          _devs.length,
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _ModernDevCard(
                              dev: _devs[i],
                              accent: _accentFor(i),
                              isDark: isDark,
                              text: text,
                              sub: sub,
                              onLaunch: _launch,
                              index: i,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, Color text) {
    return AppBar(
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: text, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.groups_rounded, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(
            'Developer Team',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: text, size: 22),
          onPressed: () => _fetchFromNetwork(),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppColors.primary.withValues(alpha: 0.2),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Header Section - App name + ButterflyDevs
// ─────────────────────────────────────────────────────────────
class _HeaderSection extends StatelessWidget {
  final bool isDark;
  final Color text, sub;

  const _HeaderSection({
    required this.isDark,
    required this.text,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkCard : Colors.white;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // App name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🕌', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'নূরভিয়া',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Noorvia',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Developer team is:
          Text(
            'Developer team is:',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.90),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 16),

          // ButterflyDevs logo - Full width
          Image.network(
            'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/IslamicAppImages/butterflydevs.webp',
            width: double.infinity,
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              height: 120,
              alignment: Alignment.center,
              child: const Icon(
                Icons.flutter_dash_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ButterflyDevs name
          Text(
            'ButterflyDevs',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Software Development Team',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Modern Developer Card with clickable links
// ─────────────────────────────────────────────────────────────
class _ModernDevCard extends StatelessWidget {
  final _Developer dev;
  final Color accent, text, sub;
  final bool isDark;
  final Future<void> Function(String) onLaunch;
  final int index;

  const _ModernDevCard({
    required this.dev,
    required this.accent,
    required this.isDark,
    required this.text,
    required this.sub,
    required this.onLaunch,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkCard : Colors.white;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Gradient header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, accent.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.25),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 3,
                          ),
                        ),
                        child: dev.avatar != null
                            ? ClipOval(
                                child: Image.network(dev.avatar!, fit: BoxFit.cover))
                            : Icon(
                                dev.id == 1
                                    ? Icons.person_rounded
                                    : Icons.person_2_rounded,
                                size: 36,
                                color: Colors.white,
                              ),
                      ),
                      if (dev.isOnline)
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              shape: BoxShape.circle,
                              border: Border.all(color: accent, width: 2.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dev.name,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dev.role,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.90),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Menu
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                    onPressed: () => _showMenu(context),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact info - CLICKABLE
                  _ClickableInfoLine(
                    icon: Icons.location_on_outlined,
                    value: dev.location,
                    sub: sub,
                    onTap: () => onLaunch(
                        'https://www.google.com/maps/search/${Uri.encodeComponent(dev.location)}'),
                  ),
                  _ClickableInfoLine(
                    icon: Icons.email_outlined,
                    value: dev.email,
                    sub: sub,
                    onTap: () => onLaunch('mailto:${dev.email}'),
                  ),
                  _ClickableInfoLine(
                    icon: Icons.phone_outlined,
                    value: dev.phone,
                    sub: sub,
                    onTap: () => onLaunch('tel:${dev.phone}'),
                  ),
                  _ClickableInfoLine(
                    icon: Icons.code_rounded,
                    value: dev.github,
                    sub: sub,
                    onTap: () => onLaunch('https://${dev.github}'),
                  ),
                  _ClickableInfoLine(
                    icon: Icons.language_outlined,
                    value: dev.website,
                    sub: sub,
                    onTap: () => onLaunch('https://${dev.website}'),
                  ),

                  const SizedBox(height: 12),

                  // University
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.school_rounded, size: 16, color: accent),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dev.university.name,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: text,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Social Links
                  Row(
                    children: [
                      Text(
                        'Social:',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: sub,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SocialButton(
                        icon: Icons.facebook_rounded,
                        color: const Color(0xFF1877F2),
                        onTap: () => onLaunch(dev.socials.facebook.url),
                      ),
                      const SizedBox(width: 6),
                      _SocialButton(
                        icon: Icons.telegram_rounded,
                        color: const Color(0xFF0088CC),
                        onTap: () => onLaunch(dev.socials.telegram.url),
                      ),
                      const SizedBox(width: 6),
                      _SocialButton(
                        icon: Icons.phone_rounded,
                        color: const Color(0xFF25D366),
                        onTap: () => onLaunch(dev.socials.whatsapp.url),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Stats
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.08),
                          accent.withValues(alpha: 0.03),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        _StatItem(
                          icon: Icons.folder_copy_outlined,
                          iconColor: accent,
                          value: '${dev.stats.projects}',
                          label: 'Projects',
                          text: text,
                          sub: sub,
                        ),
                        _StatDivider(isDark: isDark),
                        _StatItem(
                          icon: Icons.star_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          value: dev.stats.rating.toStringAsFixed(1),
                          label: '(${dev.stats.ratingCount})',
                          sublabel: 'Rating',
                          text: text,
                          sub: sub,
                        ),
                        _StatDivider(isDark: isDark),
                        _StatItem(
                          icon: Icons.calendar_today_outlined,
                          iconColor: const Color(0xFF4A6FE3),
                          value: dev.stats.experience,
                          label: 'Experience',
                          text: text,
                          sub: sub,
                        ),
                        _StatDivider(isDark: isDark),
                        _StatItem(
                          icon: Icons.download_rounded,
                          iconColor: const Color(0xFF22C55E),
                          value: dev.stats.downloads,
                          label: 'Downloads',
                          text: text,
                          sub: sub,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Skills
                  Row(
                    children: [
                      Icon(Icons.code_rounded, size: 16, color: accent),
                      const SizedBox(width: 6),
                      Text(
                        'Skills',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _SkillsRow(skills: dev.skills, accent: accent, sub: sub),

                  const SizedBox(height: 14),

                  // Bio
                  Text(
                    dev.bio,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: sub,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      // View Profile
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onLaunch(dev.profileUrl),
                          icon: Icon(Icons.person_outline_rounded,
                              size: 16, color: accent),
                          label: Text(
                            'Profile',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: accent,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: accent.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Contact
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accent, accent.withValues(alpha: 0.75)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => onLaunch('mailto:${dev.email}'),
                            icon: const Icon(Icons.email_outlined,
                                size: 16, color: Colors.white),
                            label: Text(
                              'Contact',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.share_outlined, color: accent),
                title: Text('Share Profile',
                    style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(Icons.copy_outlined, color: accent),
                title: Text('Copy Email',
                    style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: dev.email));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Email copied!',
                          style: GoogleFonts.poppins()),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.open_in_browser_outlined, color: accent),
                title: Text('Open GitHub',
                    style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  onLaunch('https://${dev.github}');
                },
              ),
              ListTile(
                leading: Icon(Icons.facebook_rounded, color: accent),
                title: Text('Open Facebook',
                    style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  onLaunch(dev.socials.facebook.url);
                },
              ),
              ListTile(
                leading: Icon(Icons.telegram_rounded, color: accent),
                title: Text('Open Telegram',
                    style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  onLaunch(dev.socials.telegram.url);
                },
              ),
              ListTile(
                leading: Icon(Icons.phone_rounded, color: accent),
                title: Text('Open WhatsApp',
                    style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  onLaunch(dev.socials.whatsapp.url);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _ClickableInfoLine extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color sub;
  final VoidCallback onTap;

  const _ClickableInfoLine({
    required this.icon,
    required this.value,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 14, color: sub),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: sub,
                    decoration: TextDecoration.underline,
                    decorationColor: sub.withValues(alpha: 0.4),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.open_in_new_rounded, size: 12, color: sub.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color sub;
  const _InfoLine(
      {required this.icon, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: sub),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 11.5, color: sub),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor, text, sub;
  final String value, label;
  final String? sublabel;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.text,
    required this.sub,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
          if (sublabel != null)
            Text(
              sublabel!,
              style: GoogleFonts.poppins(fontSize: 9.5, color: sub),
              textAlign: TextAlign.center,
            ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 9.5, color: sub),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  final bool isDark;
  const _StatDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10),
    );
  }
}

class _SkillsRow extends StatelessWidget {
  final List<String> skills;
  final Color accent, sub;
  const _SkillsRow(
      {required this.skills, required this.accent, required this.sub});

  @override
  Widget build(BuildContext context) {
    // Show first 6, then "+N" chip
    const maxShow = 6;
    final visible = skills.take(maxShow).toList();
    final extra = skills.length - maxShow;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...visible.map((s) => _SkillChip(label: s, accent: accent)),
        if (extra > 0)
          _SkillChip(label: '+$extra', accent: sub, isExtra: true),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  final Color accent;
  final bool isExtra;
  const _SkillChip(
      {required this.label, required this.accent, this.isExtra = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isExtra
            ? accent.withValues(alpha: 0.10)
            : accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: isExtra ? 0.20 : 0.25),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: accent,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Error / Retry View
// ─────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 64, color: Colors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'ডেটা লোড হয়নি',
              style: GoogleFonts.hindSiliguri(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.lightText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ইন্টারনেট সংযোগ চেক করুন এবং আবার চেষ্টা করুন।',
              style: GoogleFonts.hindSiliguri(
                  fontSize: 13, color: AppColors.lightSubText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('আবার চেষ্টা করুন',
                  style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
