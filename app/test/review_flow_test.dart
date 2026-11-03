import 'package:family_points/app.dart';
import 'package:family_points/core/widgets/app_button.dart';
import 'package:family_points/core/widgets/app_text_field.dart';
import 'package:family_points/core/widgets/pill_chip.dart';
import 'package:family_points/data/fake/fake_repository.dart';
import 'package:family_points/data/models.dart';
import 'package:family_points/data/submission_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(AppTextField)),
  matching: find.byType(TextField),
);
Finder _button(String label) => find.widgetWithText(AppButton, label);
Finder _chip(String label) => find.widgetWithText(PillChip, label);

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

Finder _rowStatus(String title, String status) => find.descendant(
  of: find.ancestor(of: find.text(title), matching: find.byType(Row)).first,
  matching: find.text(status),
);

/// Keluarga contoh: orang tua (login) + Raka yang sudah melapor "Bantu cuci piring".
Future<({FakeRepository repo, String parentId, String childId, Member raka})> _familyWithReport() async {
  final repo = FakeRepository();
  final code = await repo.debugSeedFamily();
  final parentId = repo.debugSeedOwnerId!;
  await repo.signInAnonymously();
  final childId = (await repo.currentUser())!.id;
  final raka = await repo.joinFamily(code: code);
  final cuci = (await repo.listTasks(raka.familyId)).firstWhere((t) => t.title == 'Bantu cuci piring');
  await repo.submitTask(member: raka, taskId: cuci.id, note: 'Sudah bersih');
  repo.debugSetUser(parentId);
  return (repo: repo, parentId: parentId, childId: childId, raka: raka);
}

void main() {
  testWidgets('anak melapor tugas, lalu status berubah saat orang tua menyetujui (Flow 3)', (tester) async {
    final repo = FakeRepository();
    final code = await repo.debugSeedFamily();
    final parentId = repo.debugSeedOwnerId!;
    await repo.signInAnonymously();
    final raka = await repo.joinFamily(code: code);

    await tester.pumpWidget(FamilyPointsApp(repository: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Tugas').last);
    await tester.pumpAndSettle();

    await _tap(tester, find.text('Bantu cuci piring'));
    expect(find.text('Orang tua akan memeriksa dulu, lalu poinnya masuk.'), findsOneWidget);
    await tester.enterText(_field('Catatan (opsional)'), 'Sudah di rak');
    await _tap(tester, _button('Kirim laporan'));

    expect(find.bySemanticsLabel('MENUNGGU'), findsOneWidget);
    await _tap(tester, _button('Oke'));
    await _reveal(tester, find.text('Bantu cuci piring'));
    expect(_rowStatus('Bantu cuci piring', 'Menunggu persetujuan'), findsOneWidget);

    // Orang tua menyetujui dari HP-nya; HP anak ikut berubah lewat realtime
    await repo.debugAs(parentId, () async {
      final item = (await repo.pendingReviews(raka.familyId)).single;
      expect(item.note, 'Sudah di rak');
      await repo.reviewSubmission(item.id, ReviewAction.approve);
    });
    await tester.pumpAndSettle();
    await _reveal(tester, find.text('Bantu cuci piring'));
    expect(_rowStatus('Bantu cuci piring', 'Disetujui'), findsOneWidget);
  });

  testWidgets('orang tua menyetujui laporan dengan bonus dari antrean (O-4, O-5, L-06)', (tester) async {
    final f = await _familyWithReport();
    await tester.pumpWidget(FamilyPointsApp(repository: f.repo));
    await tester.pumpAndSettle();

    expect(find.text('1 laporan tugas'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Persetujuan').last);
    await tester.pumpAndSettle();
    expect(find.text('Raka · Hari ini ', findRichText: false), findsNothing);
    await _tap(tester, find.text('Bantu cuci piring'));

    expect(find.text('Sudah bersih'), findsOneWidget);
    await _tap(tester, _chip('+10'));
    await _tap(tester, _button('Setujui + bonus 10'));
    expect(find.bySemanticsLabel('DISETUJUI'), findsOneWidget);
    expect(f.repo.debugBalance(f.raka.id), 60);

    await _tap(tester, _button('Kembali ke antrean'));
    expect(find.text('Tidak ada laporan yang menunggu. Mantap!'), findsOneWidget);
  });

  testWidgets('menolak wajib alasan; anak melihat alasan penolakan', (tester) async {
    final f = await _familyWithReport();
    await tester.pumpWidget(FamilyPointsApp(repository: f.repo));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Persetujuan').last);
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Bantu cuci piring'));

    await _tap(tester, _button('Tolak'));
    await _tap(tester, _button('Kirim penolakan'));
    expect(find.text('Tulis alasannya supaya anak tahu apa yang perlu diperbaiki.'), findsOneWidget);
    await _tap(tester, _chip('Kurang rapi'));
    await _tap(tester, _button('Kirim penolakan'));
    expect(find.bySemanticsLabel('DITOLAK'), findsOneWidget);

    final status = await f.repo.debugAs(
      f.childId,
      () async => (await f.repo.todayTasks(f.raka)).firstWhere((t) => t.task.title == 'Bantu cuci piring'),
    );
    expect(status.statusLabel, 'Ditolak: Kurang rapi. Coba lagi ya');
  });

  testWidgets('admin kedua melihat pesan "sudah diproses oleh ..."', (tester) async {
    final f = await _familyWithReport();
    await tester.pumpWidget(FamilyPointsApp(repository: f.repo));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Persetujuan').last);
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Bantu cuci piring'));

    // Sementara layar terbuka, laporan sudah disetujui dari HP lain
    final id = (await f.repo.pendingReviews(f.raka.familyId)).single.id;
    await f.repo.reviewSubmission(id, ReviewAction.approve);

    await _tap(tester, _button('Setujui'));
    expect(find.text('Laporan ini sudah diproses oleh Ibu Rina.'), findsOneWidget);
  });
}
