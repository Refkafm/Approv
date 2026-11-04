/// Model data minggu 2 (akun & keluarga). Kolom mengikuti supabase/migrations/20261102000100_schema.sql.
library;

import '../l10n/strings.dart';

class AuthUser {
  const AuthUser({required this.id, required this.isAnonymous, this.email, this.provider});

  final String id;

  /// Untuk bagian Akun di Pengaturan. [provider]: 'email' / 'google' (Supabase app_metadata).
  final String? email;
  final String? provider;

  /// Anak masuk dengan sesi anonim (tanpa email/nomor HP), PRD A-04.
  final bool isAnonymous;
}

enum MemberRole {
  owner,
  admin,
  member;

  bool get isAdmin => this != member;
}

class Member {
  const Member({
    required this.id,
    required this.familyId,
    required this.role,
    required this.name,
    this.avatar,
    this.canEarn = true,
    this.birthDate,
    this.isConnected = false,
  });

  factory Member.fromRow(Map<String, dynamic> row) => Member(
    id: row['id'] as String,
    familyId: row['family_id'] as String,
    role: MemberRole.values.byName(row['role'] as String),
    name: row['name'] as String,
    avatar: row['avatar'] as String?,
    canEarn: row['can_earn'] as bool? ?? true,
    birthDate: row['birth_date'] == null ? null : DateTime.parse(row['birth_date'] as String),
    isConnected: (row['member_logins'] as List?)?.isNotEmpty ?? false,
  );

  final String id;
  final String familyId;
  final MemberRole role;
  final String name;

  /// Kunci warna avatar, lihat core/widgets/member_avatar.dart.
  final String? avatar;
  final bool canEarn;
  final DateTime? birthDate;

  /// Sudah ada HP yang login sebagai anggota ini (hanya terlihat oleh admin).
  final bool isConnected;

  int? ageOn(DateTime today) {
    final b = birthDate;
    if (b == null) return null;
    final hadBirthday = today.month > b.month || (today.month == b.month && today.day >= b.day);
    return today.year - b.year - (hadBirthday ? 0 : 1);
  }
}

/// Kelompok usia template ekonomi (PRD "Template ekonomi bawaan").
enum AgeBand {
  young('6-9', 150, 50),
  middle('10-13', 300, 100),
  teen('14-17', 400, 150);

  const AgeBand(this.key, this.dailyPoints, this.screenTimePrice);

  /// Nilai p_age_band untuk RPC apply_economy_template.
  final String key;

  String get label => S.current.ageBandLabel(key.replaceAll('-', '–'));
  final int dailyPoints;
  final int screenTimePrice;

  static AgeBand forAge(int age) => age <= 9 ? young : (age <= 13 ? middle : teen);
}
