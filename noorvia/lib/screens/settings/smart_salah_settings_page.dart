import 'package:flutter/material.dart' hide Text;
import 'package:muslim_view/core/localization/localized_text.dart';
import 'package:muslim_view/core/localization/app_i18n.dart';
import 'package:provider/provider.dart';

import '../../core/models/smart_salah_settings.dart';
import '../../core/providers/smart_salah_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';

class SmartSalahSettingsPage extends StatelessWidget {
  const SmartSalahSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SmartSalahProvider>();
    final s = provider.settings;
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : Colors.white;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final sub = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    if (provider.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('স্মার্ট সালাহ মোড'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: AppI18n.current('স্ট্যাটাস রিফ্রেশ'),
            onPressed: provider.refreshStatus,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _InfoCard(
            color: card,
            textColor: text,
            subColor: sub,
            icon: Icons.mosque_rounded,
            title: 'নামাজের সময় ফোন নিজে থেকেই প্রস্তুত হবে',
            body:
                'আপনার পছন্দ অনুযায়ী ভাইব্রেশন, সাইলেন্ট বা Do Not Disturb চালু হবে। চাইলে শুধু মসজিদের কাছে থাকলেই এটি সক্রিয় হবে।',
          ),
          const SizedBox(height: 12),
          _Panel(
            color: card,
            children: [
              SwitchListTile.adaptive(
                value: s.enabled,
                activeColor: AppColors.primary,
                title: Text('স্মার্ট সালাহ মোড চালু করুন', style: TextStyle(color: text, fontWeight: FontWeight.w700)),
                subtitle: Text('সম্পূর্ণ ঐচ্ছিক — যেকোনো সময় বন্ধ করতে পারবেন', style: TextStyle(color: sub)),
                secondary: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
                onChanged: (v) => provider.update(s.copyWith(enabled: v), refreshGeofences: true),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _Heading('কখন চালু হবে', text),
          _Panel(
            color: card,
            children: [
              RadioListTile<SmartSalahTriggerMode>(
                value: SmartSalahTriggerMode.prayerTimeOnly,
                groupValue: s.triggerMode,
                activeColor: AppColors.primary,
                title: Text('শুধু নামাজের সময়', style: TextStyle(color: text)),
                subtitle: Text('লোকেশন সবসময় চালু রাখার প্রয়োজন নেই', style: TextStyle(color: sub)),
                onChanged: s.enabled
                    ? (v) => provider.update(s.copyWith(triggerMode: v), refreshGeofences: true)
                    : null,
              ),
              Divider(height: 1, color: sub.withValues(alpha: .16)),
              RadioListTile<SmartSalahTriggerMode>(
                value: SmartSalahTriggerMode.mosqueAware,
                groupValue: s.triggerMode,
                activeColor: AppColors.primary,
                title: Text('মসজিদের কাছে + নামাজের সময়', style: TextStyle(color: text)),
                subtitle: Text('মসজিদের জিওফেন্সে থাকলে তবেই অটো মোড চালু হবে', style: TextStyle(color: sub)),
                onChanged: s.enabled
                    ? (v) => provider.update(s.copyWith(triggerMode: v), refreshGeofences: true)
                    : null,
              ),
            ],
          ),
          if (s.mosqueAware) ...[
            const SizedBox(height: 12),
            _Panel(
              color: card,
              children: [
                ListTile(
                  leading: Icon(
                    provider.locationAccess ? Icons.location_on_rounded : Icons.location_off_rounded,
                    color: provider.locationAccess ? Colors.green : Colors.orange,
                  ),
                  title: Text('মসজিদ অটো-ডিটেকশন অনুমতি', style: TextStyle(color: text, fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    provider.locationAccess
                        ? 'Always location permission দেওয়া আছে'
                        : 'Background-এ মসজিদ শনাক্ত করতে Always location permission প্রয়োজন',
                    style: TextStyle(color: sub),
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: provider.locationAccess
                        ? provider.refreshGeofences
                        : provider.requestLocationAccess,
                    child: Text(provider.locationAccess ? 'রিফ্রেশ' : 'অনুমতি দিন'),
                  ),
                ),
                if (!provider.locationAccess)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: provider.openAppSettings,
                        child: const Text('অ্যাপ সেটিংস খুলুন'),
                      ),
                    ),
                  ),
                if (provider.geofenceMessage != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Text(provider.geofenceMessage!, style: TextStyle(color: sub)),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('মসজিদের ব্যাসার্ধ: ${s.mosqueRadius} মিটার', style: TextStyle(color: text, fontWeight: FontWeight.w700)),
                      Slider(
                        value: s.mosqueRadius.toDouble(),
                        min: 100,
                        max: 500,
                        divisions: 8,
                        label: '${s.mosqueRadius}m',
                        activeColor: AppColors.primary,
                        onChanged: s.enabled
                            ? (v) => provider.update(s.copyWith(mosqueRadius: v.round()))
                            : null,
                        onChangeEnd: s.enabled && provider.locationAccess
                            ? (_) => provider.refreshGeofences()
                            : null,
                      ),
                      Text(
                        provider.nearMosque ? 'বর্তমানে মসজিদ জোনের মধ্যে আছেন' : 'বর্তমানে সক্রিয় মসজিদ জোন পাওয়া যায়নি',
                        style: TextStyle(color: provider.nearMosque ? Colors.green : sub),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          _Heading('ফোনের মোড', text),
          _Panel(
            color: card,
            children: [
              _PhoneModeTile(
                value: SmartSalahPhoneMode.vibrate,
                group: s.phoneMode,
                icon: Icons.vibration_rounded,
                title: 'ভাইব্রেশন',
                text: text,
                sub: sub,
                onChanged: s.enabled ? (v) => provider.update(s.copyWith(phoneMode: v)) : null,
              ),
              Divider(height: 1, color: sub.withValues(alpha: .16)),
              _PhoneModeTile(
                value: SmartSalahPhoneMode.silent,
                group: s.phoneMode,
                icon: Icons.volume_off_rounded,
                title: 'সাইলেন্ট',
                text: text,
                sub: sub,
                onChanged: s.enabled ? (v) => provider.update(s.copyWith(phoneMode: v)) : null,
              ),
              Divider(height: 1, color: sub.withValues(alpha: .16)),
              _PhoneModeTile(
                value: SmartSalahPhoneMode.dnd,
                group: s.phoneMode,
                icon: Icons.do_not_disturb_on_rounded,
                title: 'Do Not Disturb (DND)',
                text: text,
                sub: sub,
                onChanged: s.enabled ? (v) => provider.update(s.copyWith(phoneMode: v)) : null,
              ),
              if (s.needsDndAccess)
                ListTile(
                  leading: Icon(
                    provider.dndAccess ? Icons.verified_rounded : Icons.warning_amber_rounded,
                    color: provider.dndAccess ? Colors.green : Colors.orange,
                  ),
                  title: Text(
                    provider.dndAccess ? 'DND নিয়ন্ত্রণের অনুমতি দেওয়া আছে' : 'DND নিয়ন্ত্রণের অনুমতি প্রয়োজন',
                    style: TextStyle(color: text),
                  ),
                  subtitle: Text(
                    'Priority callers ও emergency exceptions Android-এর DND সেটিংস অনুযায়ী থাকবে।',
                    style: TextStyle(color: sub),
                  ),
                  trailing: provider.dndAccess
                      ? null
                      : TextButton(
                          onPressed: provider.openDndAccess,
                          child: const Text('অনুমতি দিন'),
                        ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _Heading('সময়ের নিয়ন্ত্রণ', text),
          _Panel(
            color: card,
            children: [
              _NumberDropdown(
                label: 'নামাজের কত মিনিট আগে চালু হবে',
                value: s.beforeMinutes,
                values: const [0, 5, 10, 15, 20, 30],
                text: text,
                sub: sub,
                onChanged: s.enabled ? (v) => provider.update(s.copyWith(beforeMinutes: v)) : null,
              ),
              Divider(height: 1, color: sub.withValues(alpha: .16)),
              _NumberDropdown(
                label: 'নামাজের কত মিনিট পরে আগের মোড ফিরবে',
                value: s.afterMinutes,
                values: const [10, 15, 20, 30, 45, 60],
                text: text,
                sub: sub,
                onChanged: s.enabled ? (v) => provider.update(s.copyWith(afterMinutes: v)) : null,
              ),
              Divider(height: 1, color: sub.withValues(alpha: .16)),
              SwitchListTile.adaptive(
                value: s.restorePreviousMode,
                activeColor: AppColors.primary,
                title: Text('আগের ফোন মোড স্বয়ংক্রিয়ভাবে ফিরিয়ে দিন', style: TextStyle(color: text)),
                subtitle: Text('নামাজের সময় শেষ হলে আগের Normal/Vibrate/DND অবস্থায় ফিরবে', style: TextStyle(color: sub)),
                onChanged: s.enabled ? (v) => provider.update(s.copyWith(restorePreviousMode: v)) : null,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _Heading('কোন নামাজে ব্যবহার হবে', text),
          _Panel(
            color: card,
            children: [
              _PrayerSwitch('ফজর', s.fajr, text, (v) => provider.update(s.copyWith(fajr: v)), s.enabled),
              _PrayerSwitch('যোহর', s.dhuhr, text, (v) => provider.update(s.copyWith(dhuhr: v)), s.enabled),
              _PrayerSwitch('আসর', s.asr, text, (v) => provider.update(s.copyWith(asr: v)), s.enabled),
              _PrayerSwitch('মাগরিব', s.maghrib, text, (v) => provider.update(s.copyWith(maghrib: v)), s.enabled),
              _PrayerSwitch('এশা', s.isha, text, (v) => provider.update(s.copyWith(isha: v)), s.enabled),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'গোপনীয়তা: মসজিদ-aware মোডে Android geofence ব্যবহার করা হয়। Noorvia Smart Salah manager raw live location সংরক্ষণ করে না; শুধু আপনি কোনো নিবন্ধিত mosque zone-এ আছেন কি না সেই status ব্যবহার করে।',
            style: TextStyle(color: sub, fontSize: 12, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.color, required this.children});
  final Color color;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 8)],
        ),
        child: Column(children: children),
      );
}

class _Heading extends StatelessWidget {
  const _Heading(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.color, required this.textColor, required this.subColor, required this.icon, required this.title, required this.body});
  final Color color, textColor, subColor;
  final IconData icon;
  final String title, body;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withValues(alpha: .18))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .1), shape: BoxShape.circle), child: Icon(icon, color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 5),
            Text(body, style: TextStyle(color: subColor, height: 1.45)),
          ])),
        ]),
      );
}

class _PhoneModeTile extends StatelessWidget {
  const _PhoneModeTile({required this.value, required this.group, required this.icon, required this.title, required this.text, required this.sub, required this.onChanged});
  final SmartSalahPhoneMode value, group;
  final IconData icon;
  final String title;
  final Color text, sub;
  final ValueChanged<SmartSalahPhoneMode?>? onChanged;
  @override
  Widget build(BuildContext context) => RadioListTile<SmartSalahPhoneMode>(
        value: value,
        groupValue: group,
        activeColor: AppColors.primary,
        secondary: Icon(icon, color: AppColors.primary),
        title: Text(title, style: TextStyle(color: text)),
        onChanged: onChanged,
      );
}

class _NumberDropdown extends StatelessWidget {
  const _NumberDropdown({required this.label, required this.value, required this.values, required this.text, required this.sub, required this.onChanged});
  final String label;
  final int value;
  final List<int> values;
  final Color text, sub;
  final ValueChanged<int>? onChanged;
  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(label, style: TextStyle(color: text)),
        trailing: DropdownButton<int>(
          value: values.contains(value) ? value : values.first,
          underline: const SizedBox.shrink(),
          items: values.map((v) => DropdownMenuItem(value: v, child: Text('$v মিনিট'))).toList(),
          onChanged: onChanged == null ? null : (v) { if (v != null) onChanged!(v); },
        ),
      );
}

Widget _PrayerSwitch(String label, bool value, Color text, ValueChanged<bool> onChanged, bool enabled) =>
    SwitchListTile.adaptive(
      value: value,
      activeColor: AppColors.primary,
      title: Text(label, style: TextStyle(color: text)),
      onChanged: enabled ? onChanged : null,
    );
