import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';

class CompanyInfo {
  final String name;
  final String logo;
  final String tagline;
  final String type;
  final String foundedLocation;
  final String description;
  final String mission;
  final String vision;

  const CompanyInfo({
    required this.name,
    required this.logo,
    required this.tagline,
    required this.type,
    required this.foundedLocation,
    required this.description,
    required this.mission,
    required this.vision,
  });

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      name: json['name']?.toString() ?? '',
      logo: json['logo']?.toString() ?? '',
      tagline: json['tagline']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      foundedLocation: json['foundedLocation']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      mission: json['mission']?.toString() ?? '',
      vision: json['vision']?.toString() ?? '',
    );
  }
}

class ProjectInfo {
  final String name;
  final String shortName;
  final String category;
  final String description;

  const ProjectInfo({
    required this.name,
    required this.shortName,
    required this.category,
    required this.description,
  });

  factory ProjectInfo.fromJson(Map<String, dynamic> json) {
    return ProjectInfo(
      name: json['name']?.toString() ?? '',
      shortName: json['shortName']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

class TeamCulture {
  final String environment;
  final String community;
  final List<String> focus;

  const TeamCulture({
    required this.environment,
    required this.community,
    required this.focus,
  });

  factory TeamCulture.fromJson(Map<String, dynamic> json) {
    return TeamCulture(
      environment: json['environment']?.toString() ?? '',
      community: json['community']?.toString() ?? '',
      focus: _stringList(json['focus']),
    );
  }
}

class DeveloperContact {
  final String location;
  final String email;
  final String phone;
  final String whatsapp;
  final String availability;

  const DeveloperContact({
    required this.location,
    required this.email,
    required this.phone,
    required this.whatsapp,
    required this.availability,
  });

  factory DeveloperContact.fromJson(Map<String, dynamic> json) {
    return DeveloperContact(
      location: json['location']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      whatsapp: json['whatsapp']?.toString() ?? '',
      availability: json['availability']?.toString() ?? '',
    );
  }
}

class DeveloperCompanyProfile {
  final CompanyInfo company;
  final List<String> specializations;
  final Map<String, List<String>> technologies;
  final List<ProjectInfo> projects;
  final List<String> services;
  final TeamCulture teamCulture;
  final String facebook;
  final DeveloperContact contact;

  const DeveloperCompanyProfile({
    required this.company,
    required this.specializations,
    required this.technologies,
    required this.projects,
    required this.services,
    required this.teamCulture,
    required this.facebook,
    required this.contact,
  });

  factory DeveloperCompanyProfile.fromJson(Map<String, dynamic> json) {
    final technologies = _map(
      json['technologies'],
    ).map((key, value) => MapEntry(key, _stringList(value)));

    return DeveloperCompanyProfile(
      company: CompanyInfo.fromJson(_map(json['company'])),
      specializations: _stringList(json['specializations']),
      technologies: technologies,
      projects: _mapList(json['projects']).map(ProjectInfo.fromJson).toList(),
      services: _stringList(json['services']),
      teamCulture: TeamCulture.fromJson(_map(json['teamCulture'])),
      facebook: _map(json['socialLinks'])['facebook']?.toString() ?? '',
      contact: DeveloperContact.fromJson(_map(json['contact'])),
    );
  }
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return {};
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return [];
  return value
      .whereType<Map>()
      .map((item) => item.map((key, item) => MapEntry(key.toString(), item)))
      .toList();
}

List<String> _stringList(dynamic value) {
  if (value is! List) return [];
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}

class RuqyahDeveloperInfoPage extends StatefulWidget {
  const RuqyahDeveloperInfoPage({super.key});

  @override
  State<RuqyahDeveloperInfoPage> createState() =>
      _RuqyahDeveloperInfoPageState();
}

class _RuqyahDeveloperInfoPageState extends State<RuqyahDeveloperInfoPage> {
  static const _apiUrl =
      'https://raw.githubusercontent.com/Butterfly-Devs/profile/main/Company_info.json';
  static const _cacheKey = 'ruqyah_developer_company_cache';

  DeveloperCompanyProfile? _profile;
  bool _loading = true;
  bool _offline = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _offline = false;
      _error = null;
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
      } else if (_profile == null && mounted) {
        setState(() {
          _error = 'Developer info লোড করা যায়নি (${response.statusCode})';
          _loading = false;
        });
      } else if (mounted) {
        setState(() {
          _loading = false;
          _offline = true;
        });
      }
    } catch (_) {
      if (_profile == null && mounted) {
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
        _profile = DeveloperCompanyProfile.fromJson(data);
        _loading = false;
        _offline = fromCache;
      });
    } catch (_) {
      if (!fromCache && mounted) {
        setState(() {
          _error = 'Developer info পড়তে সমস্যা হয়েছে';
          _loading = false;
        });
      }
    }
  }

  Future<void> _launch(String value, {String? scheme}) async {
    if (value.isEmpty) return;
    final uri = scheme == null
        ? Uri.parse(value)
        : Uri(scheme: scheme, path: value);
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
              'Developer Info',
              style: GoogleFonts.hindSiliguri(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            Text(
              'Butterfly Devs',
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
            onPressed: _loadProfile,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? _ErrorView(message: _error!, onRetry: _loadProfile)
          : _profile == null
          ? _ErrorView(message: 'কোনো তথ্য পাওয়া যায়নি', onRetry: _loadProfile)
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadProfile,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                children: [
                  if (_offline) ...[
                    const _OfflineBanner(),
                    const SizedBox(height: 12),
                  ],
                  _CompanyHeader(
                    company: _profile!.company,
                    cardColor: cardColor,
                    textColor: textColor,
                    subColor: subColor,
                    onLogoTap: () => _launch(_profile!.facebook),
                  ),
                  const SizedBox(height: 14),
                  _ChipSection(
                    icon: Icons.design_services_outlined,
                    title: 'Services',
                    items: _profile!.services,
                    cardColor: cardColor,
                    textColor: textColor,
                    chipColor: const Color(0xFF059669),
                  ),
                  const SizedBox(height: 14),
                  _ContactCard(
                    contact: _profile!.contact,
                    facebook: _profile!.facebook,
                    cardColor: cardColor,
                    textColor: textColor,
                    subColor: subColor,
                    onEmail: () =>
                        _launch(_profile!.contact.email, scheme: 'mailto'),
                    onCall: () =>
                        _launch(_profile!.contact.phone, scheme: 'tel'),
                    onWhatsapp: () => _launch(_profile!.contact.whatsapp),
                    onFacebook: () => _launch(_profile!.facebook),
                  ),
                ],
              ),
            ),
    );
  }
}

class _CompanyHeader extends StatelessWidget {
  final CompanyInfo company;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final VoidCallback onLogoTap;

  const _CompanyHeader({
    required this.company,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.onLogoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onLogoTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              height: 170,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: company.logo.isEmpty
                  ? const Icon(
                      Icons.code_rounded,
                      color: AppColors.primary,
                      size: 64,
                    )
                  : Image.network(
                      company.logo,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.code_rounded,
                        color: AppColors.primary,
                        size: 64,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            company.name,
            style: GoogleFonts.hindSiliguri(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: textColor,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            company.type,
            style: GoogleFonts.hindSiliguri(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          Text(
            company.tagline,
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              color: textColor,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            company.description,
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              color: subColor,
              height: 1.65,
            ),
          ),
          if (company.foundedLocation.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SmallLine(
              icon: Icons.location_on_outlined,
              text: company.foundedLocation,
              color: subColor,
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;
  final Color cardColor;
  final Color textColor;
  final Color chipColor;

  const _ChipSection({
    required this.icon,
    required this.title,
    required this.items,
    required this.cardColor,
    required this.textColor,
    required this.chipColor,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return _SectionCard(
      cardColor: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: icon, title: title, textColor: textColor),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map((item) => _ChipLabel(label: item, color: chipColor))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final DeveloperContact contact;
  final String facebook;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final VoidCallback onEmail;
  final VoidCallback onCall;
  final VoidCallback onWhatsapp;
  final VoidCallback onFacebook;

  const _ContactCard({
    required this.contact,
    required this.facebook,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.onEmail,
    required this.onCall,
    required this.onWhatsapp,
    required this.onFacebook,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      cardColor: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.contact_mail_outlined,
            title: 'Contact',
            textColor: textColor,
          ),
          const SizedBox(height: 12),
          if (contact.availability.isNotEmpty)
            Text(
              contact.availability,
              style: GoogleFonts.hindSiliguri(
                fontSize: 13,
                color: textColor,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          if (contact.location.isNotEmpty) ...[
            const SizedBox(height: 10),
            _SmallLine(
              icon: Icons.location_on_outlined,
              text: contact.location,
              color: subColor,
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionChipButton(
                icon: Icons.email_outlined,
                label: 'Email',
                color: AppColors.primary,
                onTap: onEmail,
              ),
              _ActionChipButton(
                icon: Icons.call_outlined,
                label: 'Call',
                color: const Color(0xFF059669),
                onTap: onCall,
              ),
              _ActionChipButton(
                icon: Icons.chat_outlined,
                label: 'WhatsApp',
                color: const Color(0xFF16A34A),
                onTap: onWhatsapp,
              ),
              _ActionChipButton(
                icon: Icons.facebook,
                label: 'Facebook',
                color: const Color(0xFF2563EB),
                onTap: onFacebook,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Color cardColor;
  final Widget child;

  const _SectionCard({required this.cardColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: child,
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
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.hindSiliguri(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChipLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _ChipLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: GoogleFonts.hindSiliguri(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.hindSiliguri(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _SmallLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 17),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.hindSiliguri(
              fontSize: 12.5,
              color: color,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 15, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'অফলাইন মোড - সংরক্ষিত তথ্য দেখাচ্ছে',
              style: GoogleFonts.hindSiliguri(
                fontSize: 11,
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.hindSiliguri(fontSize: 15, color: Colors.grey),
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
