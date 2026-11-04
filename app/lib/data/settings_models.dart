import 'package:flutter/material.dart' show TimeOfDay;

import '../l10n/strings.dart';

/// Pengaturan keluarga (PRD R-02, layar O-14). Kolom mengikuti tabel families.
class FamilySettings {
  const FamilySettings({
    required this.name,
    this.timezone = 'Asia/Jakarta',
    this.locale = 'id',
    this.quietStart = const TimeOfDay(hour: 21, minute: 0),
    this.quietEnd = const TimeOfDay(hour: 6, minute: 0),
    this.allowNegativePenalty = false,
    this.streakBonusPct = 10,
  });

  factory FamilySettings.fromRow(Map<String, dynamic> row) => FamilySettings(
    name: row['name'] as String,
    timezone: row['timezone'] as String,
    locale: row['locale'] as String,
    quietStart: _parseTime(row['quiet_start'] as String),
    quietEnd: _parseTime(row['quiet_end'] as String),
    allowNegativePenalty: row['allow_negative_penalty'] as bool,
    streakBonusPct: row['streak_bonus_pct'] as int,
  );

  final String name;
  final String timezone;
  final String locale;

  /// Jam tidur: notifikasi untuk anak ditahan sampai jam tidur selesai.
  final TimeOfDay quietStart;
  final TimeOfDay quietEnd;
  final bool allowNegativePenalty;
  final int streakBonusPct;

  static const timezones = {'Asia/Jakarta': 'WIB', 'Asia/Makassar': 'WITA', 'Asia/Jayapura': 'WIT'};

  static TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String? validate() {
    final n = name.trim();
    if (n.isEmpty) return S.current.familyNameRequired;
    if (n.length > 60) return S.current.familyNameTooLong;
    if (streakBonusPct < 0 || streakBonusPct > 100) return S.current.streakBonusRange;
    return null;
  }

  Map<String, dynamic> toRow() => {
    'name': name.trim(),
    'timezone': timezone,
    'locale': locale,
    'quiet_start': formatTime(quietStart),
    'quiet_end': formatTime(quietEnd),
    'allow_negative_penalty': allowNegativePenalty,
    'streak_bonus_pct': streakBonusPct,
  };

  FamilySettings copyWith({
    String? name,
    String? timezone,
    String? locale,
    TimeOfDay? quietStart,
    TimeOfDay? quietEnd,
    bool? allowNegativePenalty,
    int? streakBonusPct,
  }) => FamilySettings(
    name: name ?? this.name,
    timezone: timezone ?? this.timezone,
    locale: locale ?? this.locale,
    quietStart: quietStart ?? this.quietStart,
    quietEnd: quietEnd ?? this.quietEnd,
    allowNegativePenalty: allowNegativePenalty ?? this.allowNegativePenalty,
    streakBonusPct: streakBonusPct ?? this.streakBonusPct,
  );
}

abstract interface class SettingsRepository {
  Future<FamilySettings> familySettings(String familyId);

  /// Hanya admin (RLS families_update).
  Future<void> updateFamilySettings(String familyId, FamilySettings settings);
}
