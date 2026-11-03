import 'package:family_points/app.dart';
import 'package:family_points/core/indonesia.dart';
import 'package:family_points/core/widgets/app_button.dart';
import 'package:family_points/core/widgets/app_text_field.dart';
import 'package:family_points/core/widgets/pill_chip.dart';
import 'package:family_points/data/fake/fake_repository.dart';
import 'package:family_points/data/task_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(AppTextField)),
  matching: find.byType(TextField),
);

Finder _chip(String label) => find.widgetWithText(PillChip, label);
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

Future<void> _type(WidgetTester tester, String label, String text) async {
  await _reveal(tester, _field(label));
  await tester.enterText(_field(label), text);
}

void main() {
  testWidgets('orang tua membuat, mengubah, dan mengarsipkan tugas (O-6, O-7, T-08)', (tester) async {
    final repo = FakeRepository();
    await repo.signInWithGoogle();
    final familyId = await repo.createFamily(familyName: 'Keluarga Rina', ownerName: 'Ibu Rina');
    final raka = await repo.addChild(familyId: familyId, name: 'Raka');
    await repo.addChild(familyId: familyId, name: 'Kiara');

    await tester.pumpWidget(FamilyPointsApp(repository: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Tugas').last);
    await tester.pumpAndSettle();
    expect(find.text('Belum ada tugas. Tekan + untuk membuat.'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Tugas baru'));
    await tester.pumpAndSettle();
    expect(find.text('Tugas baru'), findsOneWidget);

    await _type(tester, 'Nama tugas', 'Siram tanaman');
    await _tap(tester, find.bySemanticsLabel('Ikon tanaman'));
    await _type(tester, 'Poin', '30');
    await _tap(tester, _chip('Hari tertentu'));
    await _tap(tester, _chip('Sen'));
    await _tap(tester, _chip('Rab'));
    await _tap(tester, _chip('Persetujuan + foto'));
    expect(find.text('Minimal foto'), findsOneWidget);
    await _tap(tester, _chip('Raka'));
    await _tap(tester, _button('Simpan tugas'));

    expect(find.text('Siram tanaman'), findsOneWidget);
    expect(find.text('Raka · Sen, Rab · Persetujuan + foto'), findsOneWidget);
    final saved = (await repo.listTasks(familyId)).single;
    expect(saved.icon, 'plant');
    expect(saved.daysOfWeek, [1, 3]);
    expect(saved.verification, TaskVerification.photo);
    expect(saved.assigneeIds, [raka.id]);

    await _tap(tester, find.text('Siram tanaman'));
    expect(find.text('Ubah tugas'), findsOneWidget);
    expect(find.text('Mengubah poin tidak mengubah poin yang sudah pernah diberikan.'), findsOneWidget);
    await _tap(tester, _button('Arsipkan'));

    expect(find.text('Belum ada tugas. Tekan + untuk membuat.'), findsOneWidget);
    await _tap(tester, _chip('Arsip'));
    expect(find.text('Siram tanaman'), findsOneWidget);
  });

  testWidgets('form menolak "Hari tertentu" tanpa hari', (tester) async {
    final repo = FakeRepository();
    await repo.signInWithGoogle();
    await repo.createFamily(familyName: 'Keluarga Rina', ownerName: 'Ibu Rina');

    await tester.pumpWidget(FamilyPointsApp(repository: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Tugas').last);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Tugas baru'));
    await tester.pumpAndSettle();

    await _type(tester, 'Nama tugas', 'Siram tanaman');
    await _type(tester, 'Poin', '30');
    await _tap(tester, _chip('Hari tertentu'));
    await _tap(tester, _button('Simpan tugas'));
    await _reveal(tester, find.text('Pilih minimal satu hari.'));
    expect(find.text('Pilih minimal satu hari.'), findsOneWidget);
  });

  testWidgets('anak melihat tugas hari ini beserta statusnya (A-3)', (tester) async {
    final repo = FakeRepository();
    final code = await repo.debugSeedFamily();
    await repo.signInAnonymously();
    final raka = await repo.joinFamily(code: code);
    final kasur = (await repo.listTasks(raka.familyId)).firstWhere((t) => t.title == 'Rapikan kasur');
    repo.debugAddSubmission(
      taskId: kasur.id,
      memberId: raka.id,
      status: SubmissionStatus.approved,
      forDate: familyToday('Asia/Jakarta'),
    );

    await tester.pumpWidget(FamilyPointsApp(repository: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Tugas').last);
    await tester.pumpAndSettle();

    expect(find.text('Tinggal 5 tugas lagi, semangat!'), findsOneWidget);
    await _reveal(tester, find.text('Rapikan kasur'));
    expect(
      find.descendant(
        of: find.ancestor(of: find.text('Rapikan kasur'), matching: find.byType(Row)).first,
        matching: find.text('Disetujui'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('beranda anak: tugas yang sudah beres hilang dari kartu Tugas hari ini', (tester) async {
    final repo = FakeRepository();
    final code = await repo.debugSeedFamily();
    await repo.signInAnonymously();
    final raka = await repo.joinFamily(code: code);
    final today = familyToday('Asia/Jakarta');
    for (final item in await repo.todayTasks(raka)) {
      if (item.task.title == 'Rapikan kasur' || !item.scheduledToday) continue;
      for (var i = 0; i < item.limit; i++) {
        repo.debugAddSubmission(
          taskId: item.task.id,
          memberId: raka.id,
          status: SubmissionStatus.approved,
          forDate: today,
        );
      }
    }

    await tester.pumpWidget(FamilyPointsApp(repository: repo));
    await tester.pumpAndSettle();
    await _reveal(tester, find.text('Tinggal 1 tugas lagi, semangat!'));
    expect(find.text('Tinggal 1 tugas lagi, semangat!'), findsOneWidget);
    expect(find.text('Rapikan kasur'), findsOneWidget);

    final kasur = (await repo.listTasks(raka.familyId)).firstWhere((t) => t.title == 'Rapikan kasur');
    repo.debugAddSubmission(taskId: kasur.id, memberId: raka.id, status: SubmissionStatus.pending, forDate: today);
    await tester.pumpWidget(FamilyPointsApp(key: UniqueKey(), repository: repo));
    await tester.pumpAndSettle();
    await _reveal(tester, find.text('Semua tugas beres. Keren!'));
    expect(find.text('Semua tugas beres. Keren!'), findsOneWidget);
    expect(find.text('Rapikan kasur'), findsNothing);
  });
}
