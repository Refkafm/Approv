import 'package:family_points/app.dart';
import 'package:family_points/core/format.dart';
import 'package:family_points/core/widgets/app_button.dart';
import 'package:family_points/data/app_exception.dart';
import 'package:family_points/data/fake/fake_repository.dart';
import 'package:family_points/l10n/language_store.dart';
import 'package:family_points/l10n/strings.dart';
import 'package:family_points/l10n/strings_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

/// Dua bahasa (Indonesia & Inggris): pilihan di layar awal sebelum login, lalu pengaturan keluarga.
void main() {
  tearDown(() => S.current = const SId());

  testWidgets('layar awal: pilih English, teks berganti dan pilihan tersimpan di HP', (tester) async {
    final store = MemoryLanguageStore();
    await tester.pumpWidget(FamilyPointsApp(repository: FakeRepository(), languageStore: store));
    await tester.pumpAndSettle();
    expect(find.text('Siapa yang pakai HP ini?'), findsOneWidget);

    await _tap(tester, find.text('English'));
    expect(find.text('Who is using this phone?'), findsOneWidget);
    expect(await store.load(), 'en');

    await _tap(tester, _button("I'm a parent"));
    expect(_button('Sign in'), findsOneWidget);
    // Tombol daftar ada di bawah layar; ListView baru membangunnya setelah digulir
    await tester.scrollUntilVisible(_button('Create a new account'), 300, scrollable: find.byType(Scrollable).first);
    expect(_button('Create a new account'), findsOneWidget);
  });

  testWidgets('bahasa keluarga berlaku setelah login, dan bisa diganti dari Pengaturan', (tester) async {
    final repo = FakeRepository();
    await repo.debugSeedFamily();
    repo.debugSetUser(repo.debugSeedOwnerId!);
    final familyId = (await repo.myMemberships()).first.familyId;
    final settings = await repo.familySettings(familyId);
    await repo.updateFamilySettings(familyId, settings.copyWith(locale: 'en'));

    await tester.pumpWidget(FamilyPointsApp(repository: repo));
    await tester.pumpAndSettle();
    expect(find.text('Approvals'), findsWidgets);
    expect(find.text('Persetujuan'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Family').last);
    await tester.pumpAndSettle();
    await _tap(tester, _button('Family settings'));
    await _tap(tester, find.text('Bahasa Indonesia'));
    await _tap(tester, _button('Save'));

    expect((await repo.familySettings(familyId)).locale, 'id');
    expect(_button('Pengaturan keluarga'), findsOneWidget);
  });

  test('pesan error & angka mengikuti bahasa aktif', () {
    S.current = S.forLanguage('en');
    expect(const AppException('insufficient_points').message, 'Not enough points.');
    expect(formatPoints(3200), '3,200');

    S.current = S.forLanguage('id');
    expect(const AppException('insufficient_points').message, 'Poinnya tidak cukup.');
    expect(formatPoints(3200), '3.200');
  });
}
