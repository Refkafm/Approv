part of 'supabase_repository.dart';

mixin _SupabaseSettings on _SupabaseBase implements SettingsRepository {
  @override
  Future<FamilySettings> familySettings(String familyId) => _guard(() async {
    final row = await _client
        .from('families')
        .select('name, timezone, locale, quiet_start, quiet_end, allow_negative_penalty, streak_bonus_pct')
        .eq('id', familyId)
        .single();
    return FamilySettings.fromRow(row);
  });

  @override
  Future<void> updateFamilySettings(String familyId, FamilySettings settings) =>
      _guard(() => _client.from('families').update(settings.toRow()).eq('id', familyId));
}
