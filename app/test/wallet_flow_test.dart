import 'package:family_points/app.dart';
import 'package:family_points/core/widgets/app_button.dart';
import 'package:family_points/core/widgets/app_text_field.dart';
import 'package:family_points/core/widgets/pill_chip.dart';
import 'package:family_points/data/fake/fake_repository.dart';
import 'package:family_points/data/models.dart';
import 'package:family_points/data/submission_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _button(String label) => find.widgetWithText(AppButton, label);
Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(AppTextField)),
  matching: find.byType(TextField),
);

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable).first);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _scrollTop(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable).first, const Offset(0, 5000));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _reveal(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Raka melapor "Rapikan kasur" (otomatis, +20) dan "Bantu cuci piring" (+50, disetujui orang tua).
Future<({FakeRepository repo, String parentId, String childId, Member raka})> _family() async {
  final repo = FakeRepository();
  final code = await repo.debugSeedFamily();
  final parentId = repo.debugSeedOwnerId!;
  await repo.signInAnonymously();
  final childId = (await repo.currentUser())!.id;
  final raka = await repo.joinFamily(code: code);
  final tasks = {for (final t in await repo.listTasks(raka.familyId)) t.title: t};
  await repo.submitTask(member: raka, taskId: tasks['Rapikan kasur']!.id);
  await repo.submitTask(member: raka, taskId: tasks['Bantu cuci piring']!.id);
  await repo.debugAs(parentId, () async {
    final id = (await repo.pendingReviews(raka.familyId)).single.id;
    await repo.reviewSubmission(id, ReviewAction.approve);
  });
  return (repo: repo, parentId: parentId, childId: childId, raka: raka);
}

void main() {
  testWidgets('orang tua: kartu anak → detail → bonus, penalti, batalkan tugas otomatis (O-3, O-10, O-11)', (
    tester,
  ) async {
    final f = await _family();
    f.repo.debugSetUser(f.parentId);
    await tester.pumpWidget(FamilyPointsApp(repository: f.repo));
    await tester.pumpAndSettle();

    expect(find.text('70 poin · streak 1 hari'), findsOneWidget);
    await _tap(tester, find.text('Raka'));
    expect(find.bySemanticsLabel('Saldo 70 poin'), findsOneWidget);
    await _reveal(tester, find.text('Rapikan kasur'));

    // Bonus
    await _tap(tester, _button('Bonus'));
    await tester.enterText(_field('Jumlah poin'), '30');
    await _tap(tester, find.widgetWithText(PillChip, 'Nilai bagus'));
    expect(find.text('Saldo Raka jadi 100 poin.'), findsOneWidget);
    await _tap(tester, _button('Beri bonus'));
    await _scrollTop(tester);
    expect(find.bySemanticsLabel('Saldo 100 poin'), findsOneWidget);
    await _reveal(tester, find.text('Bonus: Nilai bagus'));

    // Penalti melebihi saldo ditolak dengan pesan jelas
    await _tap(tester, _button('Penalti'));
    await tester.enterText(_field('Jumlah poin'), '500');
    await tester.enterText(_field('Alasan'), 'Main melebihi waktu');
    await tester.pumpAndSettle();
    await _tap(tester, _button('Beri penalti'));
    expect(find.text('Penalti melebihi saldo Raka (100 poin).'), findsOneWidget);
    await tester.tapAt(const Offset(20, 20)); // tutup lembar
    await tester.pumpAndSettle();

    // Batalkan tugas otomatis
    await _tap(tester, find.textContaining('ketuk untuk membatalkan'));
    await tester.enterText(_field('Alasan'), 'Kasur belum rapi');
    await _tap(tester, _button('Batalkan tugas'));
    await _scrollTop(tester);
    expect(find.bySemanticsLabel('Saldo 80 poin'), findsOneWidget);
    await _reveal(tester, find.text('Dibatalkan: Kasur belum rapi'));
  });

  testWidgets('anak: saldo & riwayat; utang poin tampil dengan alasan (A-2, A-9)', (tester) async {
    final f = await _family();
    final kasur = (await f.repo.debugAs(f.parentId, () => f.repo.reversibleSubmissions(f.raka.id))).single;
    await f.repo.debugAs(f.parentId, () async {
      await f.repo.adjustPoints(memberId: f.raka.id, amount: -70, reason: 'Tes');
      await f.repo.reverseAutoTask(submissionId: kasur, reason: 'Kasur belum rapi');
    });
    f.repo.debugSetUser(f.childId, anonymous: true);

    await tester.pumpWidget(FamilyPointsApp(repository: f.repo));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Utang poin 20'), findsOneWidget);
    expect(find.text('Kasur belum rapi'), findsOneWidget);
    expect(find.text('Akan lunas otomatis dari poin berikutnya.'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Riwayat').last);
    await tester.pumpAndSettle();
    expect(find.text('Dibatalkan: Kasur belum rapi'), findsOneWidget);
    expect(find.text('Penalti: Tes'), findsOneWidget);
    await _reveal(tester, find.text('Bantu cuci piring'));
  });

  testWidgets('bonus dari orang tua langsung terlihat di HP anak (realtime)', (tester) async {
    final f = await _family();
    f.repo.debugSetUser(f.childId, anonymous: true);
    await tester.pumpWidget(FamilyPointsApp(repository: f.repo));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Saldo 70 poin'), findsOneWidget);

    await f.repo.debugAs(f.parentId, () => f.repo.adjustPoints(memberId: f.raka.id, amount: 30, reason: 'Hebat'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Saldo 100 poin'), findsOneWidget);
  });
}
