import 'package:family_points/app.dart';
import 'package:family_points/core/widgets/app_button.dart';
import 'package:family_points/core/widgets/app_text_field.dart';
import 'package:family_points/data/fake/fake_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpApp(WidgetTester tester, FakeRepository repo) async {
  await tester.pumpWidget(FamilyPointsApp(repository: repo));
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(AppTextField)),
  matching: find.byType(TextField),
);

Finder _button(String label) => find.widgetWithText(AppButton, label);

/// ListView hanya membangun item yang terlihat: gulir dulu sampai [finder] ada.
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable).first);
  }
  await tester.ensureVisible(finder);
}

Future<void> _type(WidgetTester tester, String label, String text) async {
  await _reveal(tester, _field(label));
  await tester.enterText(_field(label), text);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _reveal(tester, finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('orang tua: daftar, buat keluarga, tambah anak, template, kode HP anak (Flow 1)', (tester) async {
    final repo = FakeRepository();
    await _pumpApp(tester, repo);

    await _tap(tester, _button('Saya orang tua'));
    await _tap(tester, _button('Lanjut dengan Google'));
    expect(find.text('Buat keluarga'), findsOneWidget);

    await _type(tester, 'Nama keluarga', 'Keluarga Rina');
    await _type(tester, 'Nama panggilanmu', 'Ibu Rina');
    await _tap(tester, _button('Lanjut'));

    await _type(tester, 'Nama panggilan anak', 'Raka');
    await _tap(tester, _button('Tambah anak'));
    expect(_button('Tambah anak lagi'), findsOneWidget);
    await _tap(tester, _button('Lanjut'));

    expect(find.text('Pilih template poin'), findsOneWidget);
    expect(find.text('Disarankan'), findsOneWidget);
    await _tap(tester, _button('Pakai template ini'));

    expect(find.text('Cek tugas & hadiah'), findsOneWidget);
    expect(find.text('Rapikan kasur'), findsOneWidget);
    expect(find.text('+20'), findsOneWidget);
    await _tap(tester, _button('Lanjut'));

    expect(find.text('Kode untuk Raka'), findsOneWidget);
    await _tap(tester, _button('Selesai'));

    expect(find.text('Halo, Ibu Rina'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Keluarga').last);
    await tester.pumpAndSettle();
    expect(find.text('Raka'), findsOneWidget);
    expect(find.text('Belum terhubung ke HP anak'), findsOneWidget);
  });

  testWidgets('anak: gabung dengan kode, buat PIN, masuk beranda anak (Flow 2)', (tester) async {
    final repo = FakeRepository();
    final code = await repo.debugSeedFamily(childName: 'Raka');
    await _pumpApp(tester, repo);

    await _tap(tester, _button('Saya anak'));
    await _type(tester, 'Kode undangan', code.toLowerCase());
    await _tap(tester, _button('Gabung'));

    expect(find.text('Halo, Raka!'), findsOneWidget);
    await _type(tester, 'PIN', '1234');
    await _tap(tester, _button('Simpan PIN'));

    expect(find.text('Halo, Raka!'), findsOneWidget);
    expect(find.bySemanticsLabel('Riwayat'), findsWidgets);

    final raka = (await repo.myMemberships()).single;
    expect(repo.debugPinOf(raka.id), '1234');
  });

  testWidgets('anak: kode salah menampilkan pesan yang jelas', (tester) async {
    final repo = FakeRepository();
    await _pumpApp(tester, repo);

    await _tap(tester, _button('Saya anak'));
    await _type(tester, 'Kode undangan', 'ZZZZZZ');
    await _tap(tester, _button('Gabung'));

    expect(find.text('Kode tidak berlaku atau sudah dipakai. Minta kode baru ke orang tua.'), findsOneWidget);
    expect(find.text('Gabung keluarga'), findsOneWidget);
  });

  testWidgets('orang tua: halaman Masuk dulu, daftar di halaman terpisah, lalu masuk lagi', (tester) async {
    final repo = FakeRepository();
    await _pumpApp(tester, repo);

    await _tap(tester, _button('Saya orang tua'));
    expect(find.text('Masuk'), findsWidgets);
    expect(_button('Pakai nomor HP'), findsNothing);
    expect(_button('Lanjut dengan Apple'), findsNothing);

    await _tap(tester, _button('Daftar akun baru'));
    expect(find.text('Daftar akun'), findsOneWidget);
    await _type(tester, 'Email', 'ibu@contoh');
    await _type(tester, 'Kata sandi', 'rahasia1');
    await _type(tester, 'Ulangi kata sandi', 'rahasia1');
    await _tap(tester, _button('Daftar'));
    expect(find.text('Alamat email belum benar.'), findsOneWidget);

    await _type(tester, 'Email', 'ibu@contoh.com');
    await _type(tester, 'Ulangi kata sandi', 'rahasia2');
    await _tap(tester, _button('Daftar'));
    expect(find.text('Kata sandi yang diulang tidak sama.'), findsOneWidget);

    await _type(tester, 'Ulangi kata sandi', 'rahasia1');
    await _tap(tester, _button('Daftar'));
    expect(find.text('Buat keluarga'), findsOneWidget);

    // Keluar, lalu masuk lewat halaman Masuk
    await repo.signOut();
    await tester.pumpAndSettle();
    await _tap(tester, _button('Saya orang tua'));
    await _type(tester, 'Email', 'ibu@contoh.com');
    await _type(tester, 'Kata sandi', 'salah123');
    await _tap(tester, _button('Masuk'));
    expect(find.text('Email atau kata sandi salah.'), findsOneWidget);

    await _type(tester, 'Kata sandi', 'rahasia1');
    await _tap(tester, _button('Masuk'));
    expect(find.text('Buat keluarga'), findsOneWidget);
  });

  testWidgets('orang tua: lupa kata sandi, kode dari email, kata sandi baru langsung masuk', (tester) async {
    final repo = FakeRepository();
    await repo.signUpWithEmail('ayah@contoh.com', 'lama123');
    await repo.signOut();
    await _pumpApp(tester, repo);

    await _tap(tester, _button('Saya orang tua'));
    await _type(tester, 'Email', 'ayah@contoh.com');
    await _tap(tester, find.text('Lupa kata sandi?'));
    expect(find.text('Atur ulang kata sandi'), findsOneWidget);

    // Email dari halaman Masuk sudah terisi
    await _tap(tester, _button('Kirim kode'));
    expect(find.text('Cek email kamu'), findsOneWidget);

    await _tap(tester, find.text('Emailnya berisi kode? Masukkan di sini'));
    await _type(tester, 'Kode dari email', '000000');
    await _type(tester, 'Kata sandi baru', 'baru123');
    await _type(tester, 'Ulangi kata sandi', 'baru123');
    await _tap(tester, _button('Simpan & masuk'));
    expect(find.text('Kodenya salah atau sudah kedaluwarsa.'), findsOneWidget);

    await _type(tester, 'Kode dari email', FakeRepository.demoOtp);
    await _tap(tester, _button('Simpan & masuk'));
    expect(find.text('Buat keluarga'), findsOneWidget);

    // Kata sandi lama tidak berlaku lagi
    await repo.signOut();
    await expectLater(repo.signInWithEmail('ayah@contoh.com', 'lama123'), throwsA(anything));
    await repo.signInWithEmail('ayah@contoh.com', 'baru123');
  });

  testWidgets('orang tua: tautan atur ulang dari email membuka layar kata sandi baru', (tester) async {
    final repo = FakeRepository();
    await repo.signUpWithEmail('ibu@contoh.com', 'lama123');
    await repo.signOut();
    await _pumpApp(tester, repo);

    await _tap(tester, _button('Saya orang tua'));
    await _tap(tester, find.text('Lupa kata sandi?'));
    await _type(tester, 'Email', 'ibu@contoh.com');
    await _tap(tester, _button('Kirim kode'));

    // Tautan di email diketuk di HP ini: sesi masuk, tapi router menahan di layar kata sandi baru
    repo.debugOpenRecoveryLink('ibu@contoh.com');
    await tester.pumpAndSettle();
    expect(find.text('Buat kata sandi baru'), findsOneWidget);

    await _type(tester, 'Kata sandi baru', 'baru123');
    await _type(tester, 'Ulangi kata sandi', 'beda123');
    await _tap(tester, _button('Simpan & masuk'));
    expect(find.text('Kata sandi yang diulang tidak sama.'), findsOneWidget);

    await _type(tester, 'Ulangi kata sandi', 'baru123');
    await _tap(tester, _button('Simpan & masuk'));
    expect(find.text('Buat keluarga'), findsOneWidget);

    await repo.signOut();
    await repo.signInWithEmail('ibu@contoh.com', 'baru123');
  });

  testWidgets('Keluarga hanya berisi anggota; akun & tombol keluar ada di Pengaturan', (tester) async {
    final repo = FakeRepository();
    await repo.signInWithGoogle();
    await repo.createFamily(familyName: 'Keluarga Rina', ownerName: 'Ibu Rina');
    await _pumpApp(tester, repo);

    await tester.tap(find.bySemanticsLabel('Keluarga & pengaturan'));
    await tester.pumpAndSettle();
    expect(find.text('Orang tua & pengasuh'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Ibu Rina'), 300, scrollable: find.byType(Scrollable).first);
    expect(_button('Keluar'), findsNothing);

    await _tap(tester, find.bySemanticsLabel('Pengaturan'));
    expect(find.text('demo@gmail.com'), findsOneWidget);
    expect(find.text('Masuk dengan Google'), findsOneWidget);
    await _tap(tester, _button('Keluar'));
    expect(find.text('Siapa yang pakai HP ini?'), findsOneWidget);
  });

  testWidgets('tab Keluarga: anak baru langsung muncul setelah disimpan', (tester) async {
    final repo = FakeRepository();
    await repo.signInWithGoogle();
    await repo.createFamily(familyName: 'Keluarga Rina', ownerName: 'Ibu Rina');
    await _pumpApp(tester, repo);

    await tester.tap(find.bySemanticsLabel('Keluarga & pengaturan'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada anak.'), findsOneWidget);

    await _tap(tester, _button('Tambah anak'));
    await _type(tester, 'Nama panggilan anak', 'Kiara');
    await _tap(tester, _button('Simpan'));

    expect(find.text('Kiara'), findsOneWidget);
    expect(find.text('Belum ada anak.'), findsNothing);
  });

  group('teks diperbesar 2x tidak overflow', () {
    Future<void> check(WidgetTester tester, FakeRepository repo) async {
      tester.view.physicalSize = const Size(360, 780) * tester.view.devicePixelRatio;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await _pumpApp(tester, repo);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    testWidgets('layar awal', (tester) => check(tester, FakeRepository()));

    testWidgets('beranda orang tua', (tester) async {
      final repo = FakeRepository();
      await repo.signInWithGoogle();
      await repo.createFamily(familyName: 'Keluarga Rina', ownerName: 'Ibu Rina');
      await check(tester, repo);
    });

    testWidgets('beranda anak', (tester) async {
      final repo = FakeRepository();
      final code = await repo.debugSeedFamily();
      await repo.signInAnonymously();
      await repo.joinFamily(code: code);
      await check(tester, repo);
    });
  });
}
