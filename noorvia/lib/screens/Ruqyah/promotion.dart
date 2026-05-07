import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';

class RuqyahCenterInfo {
  final String name;
  final String type;
  final List<String> banners;
  final String description;
  final String phone;
  final String whatsapp;
  final String address;
  final String googleMap;
  final String facebookPage;

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
  });

  factory RuqyahCenterInfo.fromJson(Map<String, dynamic> json) {
    final contact = json['contact'] as Map<String, dynamic>? ?? {};
    final location = json['location'] as Map<String, dynamic>? ?? {};
    final socialLinks = json['social_links'] as Map<String, dynamic>? ?? {};
    final bannerList = json['banners'] as List<dynamic>? ?? [];

    return RuqyahCenterInfo(
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      banners: bannerList
          .whereType<Map<String, dynamic>>()
          .map((item) => item['image']?.toString() ?? '')
          .where((image) => image.isNotEmpty)
          .toList(),
      description: json['description']?.toString() ?? '',
      phone: contact['phone']?.toString() ?? '',
      whatsapp: contact['whatsapp']?.toString() ?? '',
      address: location['address']?.toString() ?? '',
      googleMap: location['google_map']?.toString() ?? '',
      facebookPage: socialLinks['facebook_page']?.toString() ?? '',
    );
  }
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
      } else if (_info == null) {
        setState(() {
          _error = 'সার্ভার থেকে তথ্য আনা যায়নি (${response.statusCode})';
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _offline = true;
        });
      }
    } catch (_) {
      if (_info == null) {
        setState(() {
          _error = 'ইন্টারনেট সংযোগ পরীক্ষা করুন';
          _loading = false;
        });
      } else {
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
      setState(() {
        _info = RuqyahCenterInfo.fromJson(data);
        _loading = false;
        _offline = fromCache;
      });
    } catch (_) {
      if (!fromCache) {
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ruqyah Center Info',
              style: GoogleFonts.hindSiliguri(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            Text(
              'যোগাযোগ ও ঠিকানা',
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
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            onPressed: _fetchInfo,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                                      : () => _launchLink(Uri.parse(_info!.facebookPage)),
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
  final List<String> images;

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
          child: Icon(Icons.image_not_supported_outlined, color: Colors.white, size: 44),
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
                  widget.images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(gradient: AppColors.gradient),
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined, color: Colors.white, size: 42),
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
            child: const Icon(Icons.health_and_safety_outlined, color: Colors.white, size: 28),
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
          Text(
            'যোগাযোগ',
            style: GoogleFonts.hindSiliguri(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.call_rounded,
                  label: info.phone,
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
          Row(
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
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              color: subColor,
              height: 1.65,
            ),
          ),
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
          Text(
            'অফলাইন মোড - সংরক্ষিত তথ্য দেখাচ্ছে',
            style: GoogleFonts.hindSiliguri(fontSize: 11, color: Colors.orange),
          ),
        ],
      ),
    );
  }
}

class _PromotionErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PromotionErrorWidget({
    required this.message,
    required this.onRetry,
  });

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
              label: Text('আবার চেষ্টা করুন', style: GoogleFonts.hindSiliguri()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
