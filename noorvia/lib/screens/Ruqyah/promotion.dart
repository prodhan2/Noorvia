import 'dart:convert';

import 'package:flutter/material.dart' hide Text;
import 'package:muslim_view/core/localization/localized_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';

class RuqyahBanner {
  final int id;
  final String image;

  const RuqyahBanner({required this.id, required this.image});

  factory RuqyahBanner.fromJson(Map<String, dynamic> json) {
    return RuqyahBanner(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      image: json['image']?.toString() ?? '',
    );
  }
}

class RuqyahTeamMember {
  final String name;
  final String designation;
  final List<String> currentRoles;
  final String experience;

  const RuqyahTeamMember({
    required this.name,
    required this.designation,
    required this.currentRoles,
    required this.experience,
  });

  factory RuqyahTeamMember.fromJson(Map<String, dynamic> json) {
    return RuqyahTeamMember(
      name: json['name']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      currentRoles: _readStringList(json['current_roles']),
      experience: json['experience']?.toString() ?? '',
    );
  }
}

class RuqyahCenterInfo {
  final String name;
  final String type;
  final List<RuqyahBanner> banners;
  final String description;
  final String phone;
  final String whatsapp;
  final String address;
  final String googleMap;
  final String facebookPage;
  final List<String> services;
  final List<RuqyahTeamMember> team;
  final List<String> highlights;

  const RuqyahCenterInfo({
    required this.name,
    required this.type,
    required this.banners,
    required this.description,
    required this.phone,
    required this.whatsapp,
    required this.address,
    required this.googleMap,
    required this.facebookPage,
    required this.services,
    required this.team,
    required this.highlights,
  });

  factory RuqyahCenterInfo.fromJson(Map<String, dynamic> json) {
    final contact = _readMap(json['contact']);
    final location = _readMap(json['location']);
    final socialLinks = _readMap(json['social_links']);

    return RuqyahCenterInfo(
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      banners: _readMapList(json['banners'])
          .map(RuqyahBanner.fromJson)
          .where((banner) => banner.image.isNotEmpty)
          .toList(),
      description: json['description']?.toString() ?? '',
      phone: contact['phone']?.toString() ?? '',
      whatsapp: contact['whatsapp']?.toString() ?? '',
      address: location['address']?.toString() ?? '',
      googleMap: location['google_map']?.toString() ?? '',
      facebookPage: socialLinks['facebook_page']?.toString() ?? '',
      services: _readStringList(json['services']),
      team: _readMapList(json['team'])
          .map(RuqyahTeamMember.fromJson)
          .where((member) => member.name.isNotEmpty)
          .toList(),
      highlights: _readStringList(json['highlights']),
    );
  }
}

Map<String, dynamic> _readMap(dynamic value) {
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return {};
}

List<Map<String, dynamic>> _readMapList(dynamic value) {
  if (value is! List) return [];
  return value
      .whereType<Map>()
      .map((item) => item.map((key, item) => MapEntry(key.toString(), item)))
      .toList();
}

List<String> _readStringList(dynamic value) {
  if (value is! List) return [];
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}

class RuqyahPromotionPage extends StatefulWidget {
  const RuqyahPromotionPage({super.key});

  @override
  State<RuqyahPromotionPage> createState() => _RuqyahPromotionPageState();
}

class _RuqyahPromotionPageState extends State<RuqyahPromotionPage> {
  static const _apiUrl =
      'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/My_Ruqiya/promotion.json';
  static const _cacheKey = 'ruqyah_center_promotion_cache';

  RuqyahCenterInfo? _info;
  bool _loading = true;
  bool _offline = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInfo();
  }

  Future<void> _fetchInfo() async {
    setState(() {
      _loading = true;
      _error = null;
      _offline = false;
    });

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) _parseAndSet(cached, fromCache: true);

    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final raw = utf8.decode(response.bodyBytes);
        await prefs.setString(_cacheKey, raw);
        _parseAndSet(raw, fromCache: false);
      } else if (_info == null && mounted) {
        setState(() {
          _error = 'সার্ভার থেকে তথ্য আনা যায়নি (${response.statusCode})';
          _loading = false;
        });
      } else if (mounted) {
        setState(() {
          _loading = false;
          _offline = true;
        });
      }
    } catch (_) {
      if (_info == null && mounted) {
        setState(() {
          _error = 'ইন্টারনেট সংযোগ পরীক্ষা করুন';
          _loading = false;
        });
      } else if (mounted) {
        setState(() {
          _loading = false;
          _offline = true;
        });
      }
    }
  }

  void _parseAndSet(String raw, {required bool fromCache}) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _info = RuqyahCenterInfo.fromJson(data);
        _loading = false;
        _offline = fromCache;
      });
    } catch (_) {
      if (!fromCache && mounted) {
        setState(() {
          _error = 'তথ্য পড়তে সমস্যা হয়েছে';
          _loading = false;
        });
      }
    }
  }

  Future<void> _launchLink(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('লিংকটি খোলা যায়নি', style: GoogleFonts.hindSiliguri()),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _callPhone(String phone) async {
    if (phone.isEmpty) return;
    await _launchLink(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _openWhatsapp(String number) async {
    if (number.isEmpty) return;
    final normalized = number.replaceAll(RegExp(r'[^0-9]'), '');
    await _launchLink(Uri.parse('https://wa.me/$normalized'));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tashfiya Ruqyah',
              style: GoogleFonts.hindSiliguri(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            Text(
              'সেন্টার, সেবা ও যোগাযোগ',
              style: GoogleFonts.hindSiliguri(
                fontSize: 10,
                color: Colors.white70,
                height: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _fetchInfo,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? _PromotionErrorWidget(message: _error!, onRetry: _fetchInfo)
          : _info == null
          ? _PromotionErrorWidget(
              message: 'কোনো তথ্য পাওয়া যায়নি',
              onRetry: _fetchInfo,
            )
          : Column(
              children: [
                if (_offline) const _OfflineBanner(),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _fetchInfo,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      children: [
                        _BannerSlider(images: _info!.banners),
                        const SizedBox(height: 16),
                        _CenterHeaderCard(
                          info: _info!,
                          cardColor: cardColor,
                          textColor: textColor,
                          subColor: subColor,
                        ),
                        const SizedBox(height: 14),
                        _InfoCard(
                          icon: Icons.info_outline_rounded,
                          title: 'পরিচিতি',
                          text: _info!.description,
                          cardColor: cardColor,
                          textColor: textColor,
                          subColor: subColor,
                        ),
                        const SizedBox(height: 14),
                        _ContactActions(
                          info: _info!,
                          cardColor: cardColor,
                          textColor: textColor,
                          onCall: () => _callPhone(_info!.phone),
                          onWhatsapp: () => _openWhatsapp(_info!.whatsapp),
                        ),
                        if (_info!.services.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _ListSectionCard(
                            icon: Icons.medical_services_outlined,
                            title: 'সেবাসমূহ',
                            items: _info!.services,
                            cardColor: cardColor,
                            textColor: textColor,
                            subColor: subColor,
                            itemColor: const Color(0xFF059669),
                          ),
                        ],
                        if (_info!.team.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _TeamSectionCard(
                            members: _info!.team,
                            cardColor: cardColor,
                            textColor: textColor,
                            subColor: subColor,
                          ),
                        ],
                        if (_info!.highlights.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _ListSectionCard(
                            icon: Icons.verified_outlined,
                            title: 'বিশেষত্ব',
                            items: _info!.highlights,
                            cardColor: cardColor,
                            textColor: textColor,
                            subColor: subColor,
                            itemColor: const Color(0xFF0EA5E9),
                          ),
                        ],
                        const SizedBox(height: 14),
                        _InfoCard(
                          icon: Icons.location_on_outlined,
                          title: 'ঠিকানা',
                          text: _info!.address,
                          cardColor: cardColor,
                          textColor: textColor,
                          subColor: subColor,
                          actionLabel: 'Google Map',
                          onAction: _info!.googleMap.isEmpty
                              ? null
                              : () => _launchLink(Uri.parse(_info!.googleMap)),
                        ),
                        const SizedBox(height: 14),
                        _InfoCard(
                          icon: Icons.facebook,
                          title: 'Facebook Page',
                          text: _info!.facebookPage,
                          cardColor: cardColor,
                          textColor: textColor,
                          subColor: subColor,
                          actionLabel: 'Open Page',
                          onAction: _info!.facebookPage.isEmpty
                              ? null
                              : () =>
                                    _launchLink(Uri.parse(_info!.facebookPage)),
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

class _BannerSlider extends StatefulWidget {
  final List<RuqyahBanner> images;

  const _BannerSlider({required this.images});

  @override
  State<_BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<_BannerSlider> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: 190,
        decoration: BoxDecoration(
          gradient: AppColors.gradient,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Colors.white,
            size: 44,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 210,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  widget.images[index].image,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      decoration: BoxDecoration(gradient: AppColors.gradient),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(gradient: AppColors.gradient),
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.images.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.images.length, (index) {
              final active = index == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: active ? 18 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _CenterHeaderCard extends StatelessWidget {
  final RuqyahCenterInfo info;
  final Color cardColor;
  final Color textColor;
  final Color subColor;

  const _CenterHeaderCard({
    required this.info,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.health_and_safety_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.name,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info.type,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 12,
                    color: subColor,
                    height: 1.4,
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

class _ContactActions extends StatelessWidget {
  final RuqyahCenterInfo info;
  final Color cardColor;
  final Color textColor;
  final VoidCallback onCall;
  final VoidCallback onWhatsapp;

  const _ContactActions({
    required this.info,
    required this.cardColor,
    required this.textColor,
    required this.onCall,
    required this.onWhatsapp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.support_agent_rounded,
            title: 'যোগাযোগ',
            textColor: textColor,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.call_rounded,
                  label: info.phone.isEmpty ? 'Call' : info.phone,
                  color: const Color(0xFF059669),
                  onTap: onCall,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  color: const Color(0xFF16A34A),
                  onTap: onWhatsapp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: icon, title: title, textColor: textColor),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              text,
              style: GoogleFonts.hindSiliguri(
                fontSize: 13,
                color: subColor,
                height: 1.65,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            _ActionButton(
              icon: Icons.open_in_new_rounded,
              label: actionLabel!,
              color: AppColors.primary,
              onTap: onAction!,
            ),
          ],
        ],
      ),
    );
  }
}

class _ListSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final Color itemColor;

  const _ListSectionCard({
    required this.icon,
    required this.title,
    required this.items,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.itemColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: itemColor.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: icon, title: title, textColor: textColor),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: itemColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: itemColor,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 13,
                        color: subColor,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _TeamSectionCard extends StatelessWidget {
  final List<RuqyahTeamMember> members;
  final Color cardColor;
  final Color textColor;
  final Color subColor;

  const _TeamSectionCard({
    required this.members,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.groups_2_outlined,
            title: 'টিম',
            textColor: textColor,
          ),
          const SizedBox(height: 12),
          ...members.map(
            (member) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      height: 1.35,
                    ),
                  ),
                  if (member.designation.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      member.designation,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 12,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (member.experience.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _SmallBadge(
                      icon: Icons.workspace_premium_outlined,
                      label: member.experience,
                    ),
                  ],
                  if (member.currentRoles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...member.currentRoles.map(
                      (role) => Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.circle,
                              color: AppColors.primary.withValues(alpha: 0.72),
                              size: 7,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                role,
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 12.5,
                                  color: subColor,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color textColor;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.hindSiliguri(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SmallBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.gold, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.hindSiliguri(
                fontSize: 12,
                color: AppColors.gold,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.withValues(alpha: 0.15),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 14, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'অফলাইন মোড - সংরক্ষিত তথ্য দেখাচ্ছে',
              style: GoogleFonts.hindSiliguri(
                fontSize: 11,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PromotionErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.hindSiliguri(fontSize: 15, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'আবার চেষ্টা করুন',
                style: GoogleFonts.hindSiliguri(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
