import 'package:family_points/app.dart';
import 'package:family_points/core/widgets/app_button.dart';
import 'package:family_points/core/widgets/app_text_field.dart';
import 'package:family_points/data/app_exception.dart';
import 'package:family_points/data/fake/fake_repository.dart';
import 'package:family_points/data/settings_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher _throwsCode(String code) => throwsA(isA<AppException>().having((e) => e.code, 'code', code));

Finder _button(String label) => find.widgetWithText(AppButton, label);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable).first);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Pengaturan keluarga (R-02): hanya admin yang boleh mengubah (RLS families_update).
void main() {
  late FakeRepository repo;
  late String parentId;
  late String familyId;

  setUp(() async {
    repo = FakeRepository();
    final code = await repo.debugSeedFamily();
    parentId = repo.debugSeedOwnerId!;
    await repo.signInAnonymously();
    familyId = (await repo.joinFamily(code: code)).familyId;
  });

  test('admin mengubah pengaturan; anak hanya bisa membaca', () async {
    final current = await repo.familySettings(familyId);
    expect(current.timezone, 'Asia/Jakarta');

    await expectLater(
      repo.updateFamilySettings(familyId, current.copyWith(streakBonusPct: 20)),
      _throwsCode('not_authorized'),
    );
    await repo.debugAs(
      parentId,
      () => repo.updateFamilySettings(
        familyId,
        current.copyWith(timezone: 'Asia/Makassar', quietStart: const TimeOfDay(hour: 20, minute: 30)),
      ),
    );
    final updated = await repo.familySettings(familyId);
    expect(updated.timezone, 'Asia/Makassar');
    expect(FamilySettings.formatTime(updated.quietStart), '20:30');
  });

  test('nama kosong ditolak', () async {
    final current = await repo.familySettings(familyId);
    await expectLater(
      repo.debugAs(parentId, () => repo.updateFamilySettings(familyId, current.copyWith(name: '  '))),
      _throwsCode('invalid_settings'),
    );
  });

  test('toRow/fromRow bolak-balik (kolom time Postgres berformat HH:MM:SS)', () {
    const s = FamilySettings(name: 'Keluarga Budi', timezone: 'Asia/Jayapura', streakBonusPct: 5);
    final back = FamilySettings.fromRow({...s.toRow(), 'quiet_start': '21:00:00', 'quiet_end': '06:00:00'});
    expect(back.toRow(), s.toRow());
  });

  testWidgets('orang tua mengganti nama, zona waktu & bonus streak dari layar Keluarga', (tester) async {
    repo.debugSetUser(parentId);
    await tester.pumpWidget(FamilyPointsApp(repository: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Keluarga').last);
    await tester.pumpAndSettle();
    await _tap(tester, _button('Pengaturan keluarga'));

    await tester.enterText(
      find.descendant(
        of: find.ancestor(of: find.text('Nama keluarga'), matching: find.byType(AppTextField)),
        matching: find.byType(TextField),
      ),
      'Keluarga Baru',
    );
    await _tap(tester, find.text('WITA'));
    await _tap(tester, find.text('20%'));
    await _tap(tester, _button('Simpan'));

    final saved = await repo.familySettings(familyId);
    expect(saved.name, 'Keluarga Baru');
    expect(saved.timezone, 'Asia/Makassar');
    expect(saved.streakBonusPct, 20);
    expect(_button('Pengaturan keluarga'), findsOneWidget);
  });
}
