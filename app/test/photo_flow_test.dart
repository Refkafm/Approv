import 'package:family_points/app.dart';
import 'package:family_points/core/widgets/app_button.dart';
import 'package:family_points/core/widgets/pill_chip.dart';
import 'package:family_points/data/fake/fake_repository.dart';
import 'package:family_points/data/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_photo_picker.dart';

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

AppButton _buttonWidget(WidgetTester tester, String label) => tester.widget<AppButton>(_button(label));

void main() {
  testWidgets('foto bukti: lapor dengan foto, foto ulang, kirim ulang (Flow 3, PF-01–PF-05)', (tester) async {
    final repo = FakeRepository();
    final picker = FakePhotoPicker();
    final code = await repo.debugSeedFamily();
    final parentId = repo.debugSeedOwnerId!;
    await repo.signInAnonymously();
    final childId = (await repo.currentUser())!.id;
    final raka = await repo.joinFamily(code: code);

    // --- HP anak: lapor tugas berfoto ---
    await tester.pumpWidget(FamilyPointsApp(repository: repo, photoPicker: picker));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Tugas').last);
    await tester.pumpAndSettle();
    await _tap(tester, find.text('PR selesai tanpa disuruh'));

    expect(_buttonWidget(tester, 'Butuh 1 foto lagi').onPressed, isNull, reason: 'Kirim aktif bila foto cukup');
    expect(_button('Dari galeri'), findsNothing, reason: 'galeri dimatikan secara default');
    await _tap(tester, _button('Ambil foto'));
    expect(picker.requests.single.fromGallery, isFalse);
    expect(picker.requests.single.stamp, endsWith(' - Raka - PR selesai tanpa disuruh'));

    // Pratinjau layar penuh, lalu tutup
    await _tap(tester, find.bySemanticsLabel(RegExp('^Foto 1, ketuk untuk melihat')));
    expect(find.bySemanticsLabel('Tutup foto'), findsOneWidget);
    await _tap(tester, find.bySemanticsLabel('Tutup foto'));

    await _tap(tester, _button('Kirim laporan'));
    expect(find.bySemanticsLabel('MENUNGGU'), findsOneWidget);
    await _tap(tester, _button('Oke'));

    // --- HP orang tua: lihat foto, minta foto ulang ---
    repo.debugSetUser(parentId);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Persetujuan').last);
    await tester.pumpAndSettle();
    await _tap(tester, find.text('PR selesai tanpa disuruh'));
    expect(find.bySemanticsLabel(RegExp('^Foto bukti 1 dari 1')), findsOneWidget);

    await _tap(tester, find.bySemanticsLabel(RegExp('^Foto bukti 1 dari 1')));
    expect(find.bySemanticsLabel('Tutup foto'), findsOneWidget, reason: 'layar penuh dengan zoom (PF-04)');
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await _tap(tester, find.bySemanticsLabel('Tutup foto'));

    await _tap(tester, _button('Minta foto ulang'));
    await _tap(tester, find.widgetWithText(PillChip, 'Fotonya buram'));
    await _tap(tester, _button('Minta foto ulang').last);
    expect(find.bySemanticsLabel('FOTO ULANG'), findsOneWidget);

    // --- kembali ke HP anak: kirim foto ulang ---
    repo.debugSetUser(childId, anonymous: true);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Tugas').last);
    await tester.pumpAndSettle();
    await _reveal(tester, find.text('Perlu foto ulang'));
    await _tap(tester, find.text('PR selesai tanpa disuruh'));
    expect(find.textContaining('Orang tua minta foto ulang: Fotonya buram.'), findsOneWidget);
    await _tap(tester, _button('Ambil foto'));
    await _tap(tester, _button('Kirim foto ulang'));
    expect(find.text('Foto baru terkirim! Tunggu orang tua memeriksa ya.'), findsOneWidget);

    final queue = await repo.debugAs(parentId, () => repo.pendingReviews(raka.familyId));
    expect(queue.single.taskTitle, 'PR selesai tanpa disuruh');
  });

  testWidgets('tugas dengan izin galeri menampilkan tombol "Dari galeri" (PF-07)', (tester) async {
    final repo = FakeRepository();
    final picker = FakePhotoPicker();
    final code = await repo.debugSeedFamily();
    await repo.signInAnonymously();
    await repo.joinFamily(code: code);

    await tester.pumpWidget(FamilyPointsApp(repository: repo, photoPicker: picker));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Tugas').last);
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Nilai ujian ≥ 85'));

    await _tap(tester, _button('Dari galeri'));
    expect(picker.requests.single.fromGallery, isTrue);
    expect(_buttonWidget(tester, 'Kirim laporan').onPressed, isNotNull);
  });

  testWidgets('kamera dibatalkan: tidak ada foto yang ditambahkan', (tester) async {
    final repo = FakeRepository();
    final picker = FakePhotoPicker()..cancel = true;
    final code = await repo.debugSeedFamily();
    await repo.signInAnonymously();
    final Member raka = await repo.joinFamily(code: code);
    expect(raka.name, 'Raka');

    await tester.pumpWidget(FamilyPointsApp(repository: repo, photoPicker: picker));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Tugas').last);
    await tester.pumpAndSettle();
    await _tap(tester, find.text('PR selesai tanpa disuruh'));
    await _tap(tester, _button('Ambil foto'));
    expect(_button('Butuh 1 foto lagi'), findsOneWidget);
  });
}
