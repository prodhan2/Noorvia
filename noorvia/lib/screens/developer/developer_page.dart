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
  final _DevStats stats;
  final List<String> skills;
  final String bio;
  final String profileUrl;
  final String facebook;

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
    required this.stats,
    required this.skills,
    required this.bio,
    required this.profileUrl,
    required this.facebook,
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
        stats: _DevStats.fromJson(j['stats'] as Map<String, dynamic>),
        skills: List<String>.from(j['skills'] as List),
        bio: j['bio'] as String,
        profileUrl: j['profileUrl'] as String,
        facebook: j['facebook'] as String,
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern gradient app bar
          _ModernAppBar(isDark: isDark, text: text),
          
          // Body content
          if (_loading && _devs.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null && _devs.isEmpty)
            SliverFillRemaining(
              child: _ErrorView(onRetry: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _loadData();
              }),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    if (i >= _devs.length) return null;
                    return Padding(
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
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Developer Card  — matches the screenshot design exactly
// ─────────────────────────────────────────────────────────────
class _DevCard extends StatelessWidget {
  final _Developer dev;
  final Color accent, text, sub;
  final bool isDark;
  final Future<void> Function(String) onLaunch;

  const _DevCard({
    required this.dev,
    required this.accent,
    required this.isDark,
    required this.text,
    required this.sub,
    required this.onLaunch,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkCard : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: Avatar + Info + Menu ──────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with online dot
                Stack(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.15),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.30),
                          width: 2,
                        ),
                      ),
                      child: dev.avatar != null
                          ? ClipOval(
                              child: Image.network(dev.avatar!,
                                  fit: BoxFit.cover))
                          : Icon(
                              dev.id == 1
                                  ? Icons.person_rounded
                                  : Icons.person_2_rounded,
                              size: 38,
                              color: accent,
                            ),
                    ),
                    // Online indicator
                    if (dev.isOnline)
                      Positioned(
                        bottom: 3,
                        right: 3,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: cardBg,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // Name + role + contact info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dev.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dev.role,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _InfoLine(
                          icon: Icons.location_on_outlined,
                          value: dev.location,
                          sub: sub),
                      _InfoLine(
                          icon: Icons.email_outlined,
                          value: dev.email,
                          sub: sub),
                      _InfoLine(
                          icon: Icons.phone_outlined,
                          value: dev.phone,
                          sub: sub),
                      _InfoLine(
                          icon: Icons.link_rounded,
                          value: dev.github,
                          sub: sub),
                      _InfoLine(
                          icon: Icons.language_outlined,
                          value: dev.website,
                          sub: sub),
                    ],
                  ),
                ),

                // 3-dot menu
                GestureDetector(
                  onTap: () => _showMenu(context),
                  child: Icon(Icons.more_vert_rounded, color: sub, size: 20),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Stats row ────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
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
                    label: '(${dev.stats.ratingCount} reviews)',
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

            const SizedBox(height: 14),

            // ── Skills ───────────────────────────────────
            Text(
              'Skills',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: text,
              ),
            ),
            const SizedBox(height: 8),
            _SkillsRow(skills: dev.skills, accent: accent, sub: sub),

            const SizedBox(height: 12),

            // ── Bio ──────────────────────────────────────
            Text(
              dev.bio,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: sub,
                height: 1.55,
              ),
            ),

            const SizedBox(height: 14),

            // ── Action buttons ───────────────────────────
            Row(
              children: [
                // Contact — filled gradient
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withValues(alpha: 0.75)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.30),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          onLaunch('mailto:${dev.email}'),
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
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: Text('Share Profile',
                  style: GoogleFonts.poppins(fontSize: 14)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: Text('Copy Email',
                  style: GoogleFonts.poppins(fontSize: 14)),
              onTap: () {
                Clipboard.setData(ClipboardData(text: dev.email));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_browser_outlined),
              title: Text('Open GitHub',
                  style: GoogleFonts.poppins(fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                onLaunch('https://${dev.github}');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────

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
