enum SmartSalahTriggerMode { prayerTimeOnly, mosqueAware }
enum SmartSalahPhoneMode { vibrate, silent, dnd }

class SmartSalahSettings {
  const SmartSalahSettings({
    this.enabled = false,
    this.triggerMode = SmartSalahTriggerMode.prayerTimeOnly,
    this.phoneMode = SmartSalahPhoneMode.vibrate,
    this.beforeMinutes = 0,
    this.afterMinutes = 20,
    this.mosqueRadius = 150,
    this.restorePreviousMode = true,
    this.fajr = true,
    this.dhuhr = true,
    this.asr = true,
    this.maghrib = true,
    this.isha = true,
  });

  final bool enabled;
  final SmartSalahTriggerMode triggerMode;
  final SmartSalahPhoneMode phoneMode;
  final int beforeMinutes;
  final int afterMinutes;
  final int mosqueRadius;
  final bool restorePreviousMode;
  final bool fajr;
  final bool dhuhr;
  final bool asr;
  final bool maghrib;
  final bool isha;

  bool get mosqueAware => triggerMode == SmartSalahTriggerMode.mosqueAware;
  bool get needsDndAccess => phoneMode != SmartSalahPhoneMode.vibrate;

  SmartSalahSettings copyWith({
    bool? enabled,
    SmartSalahTriggerMode? triggerMode,
    SmartSalahPhoneMode? phoneMode,
    int? beforeMinutes,
    int? afterMinutes,
    int? mosqueRadius,
    bool? restorePreviousMode,
    bool? fajr,
    bool? dhuhr,
    bool? asr,
    bool? maghrib,
    bool? isha,
  }) =>
      SmartSalahSettings(
        enabled: enabled ?? this.enabled,
        triggerMode: triggerMode ?? this.triggerMode,
        phoneMode: phoneMode ?? this.phoneMode,
        beforeMinutes: beforeMinutes ?? this.beforeMinutes,
        afterMinutes: afterMinutes ?? this.afterMinutes,
        mosqueRadius: mosqueRadius ?? this.mosqueRadius,
        restorePreviousMode: restorePreviousMode ?? this.restorePreviousMode,
        fajr: fajr ?? this.fajr,
        dhuhr: dhuhr ?? this.dhuhr,
        asr: asr ?? this.asr,
        maghrib: maghrib ?? this.maghrib,
        isha: isha ?? this.isha,
      );

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'triggerMode': mosqueAware ? 'mosque_aware' : 'time_only',
        'phoneMode': switch (phoneMode) {
          SmartSalahPhoneMode.silent => 'silent',
          SmartSalahPhoneMode.dnd => 'dnd',
          _ => 'vibrate',
        },
        'beforeMinutes': beforeMinutes,
        'afterMinutes': afterMinutes,
        'mosqueRadius': mosqueRadius,
        'restorePreviousMode': restorePreviousMode,
        'prayers': {
          'fajr': fajr,
          'dhuhr': dhuhr,
          'asr': asr,
          'maghrib': maghrib,
          'isha': isha,
        },
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

  factory SmartSalahSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const SmartSalahSettings();
    final prayers = Map<String, dynamic>.from(
      (map['prayers'] as Map?) ?? const <String, dynamic>{},
    );
    final trigger = map['triggerMode']?.toString();
    final phone = map['phoneMode']?.toString();
    return SmartSalahSettings(
      enabled: map['enabled'] == true,
      triggerMode: trigger == 'mosque_aware'
          ? SmartSalahTriggerMode.mosqueAware
          : SmartSalahTriggerMode.prayerTimeOnly,
      phoneMode: switch (phone) {
        'silent' => SmartSalahPhoneMode.silent,
        'dnd' => SmartSalahPhoneMode.dnd,
        _ => SmartSalahPhoneMode.vibrate,
      },
      beforeMinutes: ((map['beforeMinutes'] as num?)?.toInt() ?? 0).clamp(0, 60).toInt(),
      afterMinutes: ((map['afterMinutes'] as num?)?.toInt() ?? 20).clamp(5, 120).toInt(),
      mosqueRadius: ((map['mosqueRadius'] as num?)?.toInt() ?? 150).clamp(100, 1000).toInt(),
      restorePreviousMode: map['restorePreviousMode'] != false,
      fajr: prayers['fajr'] != false,
      dhuhr: prayers['dhuhr'] != false,
      asr: prayers['asr'] != false,
      maghrib: prayers['maghrib'] != false,
      isha: prayers['isha'] != false,
    );
  }
}
