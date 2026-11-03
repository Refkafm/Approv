import 'package:family_points/app.dart';
import 'package:family_points/core/widgets/app_button.dart';
import 'package:family_points/core/widgets/app_text_field.dart';
import 'package:family_points/data/fake/fake_repository.dart';
import 'package:family_points/data/models.dart';
import 'package:family_points/data/reward_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _button(String label) => find.widgetWithText(AppButton, label);

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable).first);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _reveal(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<({FakeRepository repo, String parentId, String childId, Member raka})> _family({int points = 300}) async {
  final repo = FakeRepository();
  final code = await repo.debugSeedFamily();
  final parentId = repo.debugSeedOwnerId!;
  await repo.signInAnonymously();
  final childId = (await repo.currentUser())!.id;
  final raka = await repo.joinFamily(code: code);
  await repo.debugAs(parentId, () => repo.adjustPoints(memberId: raka.id, amount: points, reason: 'Modal'));
  return (repo: repo, parentId: parentId, childId: childId, raka: raka);
}

void main() {
  testWidgets('anak menukar screen time, orang tua menyetujui dari antrean (Flow 4)', (tester) async {
    final f = await _family();
    await tester.pumpWidget(FamilyPointsApp(repository: f.repo));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Hadiah').last);
    await tester.pumpAndSettle();

    await _tap(tester, find.text('30 menit main game'));
    expect(find.text('Sisa poinmu setelah tukar: 200'), findsOneWidget);
    await _tap(tester, _button('Tukar sekarang'));
    expect(find.bySemanticsLabel('MENUNGGU'), findsOneWidget);
    await _tap(tester, _button('Oke'));
    expect(find.textContaining('Menunggu orang tua'), findsOneWidget);

    // HP orang tua
    f.repo.debugSetUser(f.parentId);
    await tester.pumpAndSettle();
    expect(find.text('1 penukaran hadiah'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Persetujuan').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Penukaran hadiah'));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('30 menit main game'));
    await _tap(tester, _button('Setujui'));
    expect(find.bySemanticsLabel('DISETUJUI'), findsOneWidget);
    expect(find.textContaining('Timer sudah berjalan di HP-nya'), findsOneWidget);

    final r = (await f.repo.debugAs(f.childId, () => f.repo.memberRedemptions(f.raka.id))).single;
    expect(r.sessionEndsAt, isNotNull);
  });

  testWidgets('menolak penukaran wajib alasan; poin kembali', (tester) async {
    final f = await _family();
    await f.repo.redeemReward(
      member: f.raka,
      rewardId: (await f.repo.listRewards(f.raka.familyId)).firstWhere((r) => r.title == 'Pilih menu makan malam').id,
    );
    f.repo.debugSetUser(f.parentId);
    await tester.pumpWidget(FamilyPointsApp(repository: f.repo));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Persetujuan').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Penukaran hadiah'));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Pilih menu makan malam'));

    await _tap(tester, _button('Tolak'));
    expect(find.textContaining('Tulis alasan menolak'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.ancestor(of: find.text('Alasan (wajib bila menolak)'), matching: find.byType(AppTextField)),
        matching: find.byType(TextField),
      ),
      'Besok saja',
    );
    await _tap(tester, _button('Tolak'));
    expect(find.bySemanticsLabel('DITOLAK'), findsOneWidget);
    expect(f.repo.debugBalance(f.raka.id), 300);
  });

  testWidgets('anak memilih goal; kartu goal di beranda menampilkan progress (A-8, G-01, G-02)', (tester) async {
    final f = await _family(points: 1000);
    await tester.pumpWidget(FamilyPointsApp(repository: f.repo));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada goal. Pilih hadiah besar yang mau kamu tabung.'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Hadiah').last);
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Makan di restoran favorit'));
    expect(_button('Kurang 4.000 poin'), findsOneWidget);
    await _tap(tester, _button('Jadikan goal'));

    await tester.tap(find.bySemanticsLabel('Beranda').last);
    await tester.pumpAndSettle();
    expect(find.text('Makan di restoran favorit'), findsOneWidget);
    expect(find.bySemanticsLabel('Goal Makan di restoran favorit, 1.000 dari 5.000 poin, 20 persen'), findsOneWidget);
  });

  testWidgets('orang tua membuat hadiah baru (O-8, O-9)', (tester) async {
    final f = await _family();
    f.repo.debugSetUser(f.parentId);
    await tester.pumpWidget(FamilyPointsApp(repository: f.repo));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Hadiah').last);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Hadiah baru'));
    await tester.pumpAndSettle();

    Finder field(String label) => find.descendant(
      of: find.ancestor(of: find.text(label), matching: find.byType(AppTextField)),
      matching: find.byType(TextField),
    );
    await tester.enterText(field('Nama hadiah'), 'Nonton bioskop');
    await tester.enterText(field('Harga (poin)'), '2000');
    await _tap(tester, find.text('Goal (ditabung)'));
    await _tap(tester, _button('Simpan hadiah'));

    await _reveal(tester, find.text('Nonton bioskop'));
    final created = (await f.repo.listRewards(f.raka.familyId)).firstWhere((r) => r.title == 'Nonton bioskop');
    expect(created.type, RewardType.goal);
    expect(created.cost, 2000);
  });
}
