part of 'fake_repository.dart';

/// Pengaturan keluarga: meniru RLS families_select (anggota) & families_update (admin).
mixin _FakeSettings on _FakeState implements SettingsRepository {
  @override
  Future<FamilySettings> familySettings(String familyId) async {
    _requireFamilyMember(familyId);
    return _settings[familyId]!;
  }

  @override
  Future<void> updateFamilySettings(String familyId, FamilySettings settings) async {
    _requireAdmin(familyId);
    if (settings.validate() != null) throw const AppException('invalid_settings');
    _settings[familyId] = settings;
    _families[familyId] = settings.timezone;
    _notifyFamily(familyId);
  }
}
