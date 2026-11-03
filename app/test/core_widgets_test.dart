import 'package:family_points/core/format.dart';
import 'package:family_points/core/theme/app_theme.dart';
import 'package:family_points/core/widgets/app_button.dart';
import 'package:family_points/core/widgets/dot_progress.dart';
import 'package:family_points/core/widgets/points_balance.dart';
import 'package:family_points/core/widgets/status_stamp.dart';
import 'package:family_points/core/widgets/streak_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('id')}) {
  return MaterialApp(
    theme: AppTheme.light(),
    locale: locale,
    supportedLocales: const [Locale('id'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('formatPoints', () {
    test('memakai titik sebagai pemisah ribuan', () {
      expect(formatPoints(0), '0');
      expect(formatPoints(999), '999');
      expect(formatPoints(3200), '3.200');
      expect(formatPoints(1250000), '1.250.000');
    });

    test('angka negatif (utang poin)', () {
      expect(formatPoints(-10), '-10');
      expect(formatPoints(-4950), '-4.950');
    });
  });

  group('DotProgress.filledDots', () {
    test('20 titik, masing-masing 5%, dibulatkan ke bawah', () {
      expect(DotProgress.filledDots(0, 5000), 0);
      expect(DotProgress.filledDots(3200, 5000), 12); // 64%
      expect(DotProgress.filledDots(249, 5000), 0); // belum genap 5%
    });

    test('titik terakhir hanya terisi saat poin benar-benar cukup', () {
      expect(DotProgress.filledDots(4999, 5000), 19);
      expect(DotProgress.filledDots(5000, 5000), 20);
      expect(DotProgress.filledDots(9000, 5000), 20);
    });

    test('aman untuk saldo negatif dan target nol', () {
      expect(DotProgress.filledDots(-10, 5000), 0);
      expect(DotProgress.filledDots(100, 0), 0);
      expect(DotProgress.percent(3200, 5000), 64);
    });

    test('jumlah kolom tangga = 20 titik', () {
      expect(DotProgress.columns.fold<int>(0, (a, b) => a + b), DotProgress.total);
    });

    testWidgets('dibacakan sebagai teks oleh pembaca layar', (tester) async {
      await tester.pumpWidget(_wrap(const DotProgress(saved: 3200, target: 5000, goalTitle: 'Sepatu')));
      expect(find.bySemanticsLabel('Goal Sepatu, 3.200 dari 5.000 poin, 64 persen'), findsOneWidget);
    });
  });

  group('StatusStamp', () {
    testWidgets('label Indonesia', (tester) async {
      await tester.pumpWidget(_wrap(const StatusStamp(status: StampStatus.retake)));
      expect(find.bySemanticsLabel('FOTO ULANG'), findsOneWidget);
    });

    testWidgets('label Inggris', (tester) async {
      await tester.pumpWidget(_wrap(const StatusStamp(status: StampStatus.retake), locale: const Locale('en')));
      expect(find.bySemanticsLabel('RETAKE'), findsOneWidget);
    });

    testWidgets('ukuran sama di kedua bahasa', (tester) async {
      await tester.pumpWidget(_wrap(const StatusStamp(status: StampStatus.cancelled)));
      final idSize = tester.getSize(find.byType(StatusStamp));
      await tester.pumpWidget(_wrap(const StatusStamp(status: StampStatus.cancelled), locale: const Locale('en')));
      expect(tester.getSize(find.byType(StatusStamp)), idSize);
    });

    test('semua status punya label ID & EN', () {
      for (final s in StampStatus.values) {
        expect(s.labelId, isNotEmpty);
        expect(s.labelEn, isNotEmpty);
      }
    });
  });

  group('PointsBalance', () {
    testWidgets('saldo normal dengan tabungan goal & poin ditahan', (tester) async {
      await tester.pumpWidget(_wrap(const PointsBalance(available: 3250, goalSaved: 1200, onHold: 100)));
      expect(find.text('3.250'), findsOneWidget);
      expect(find.text('+ 1.200 di tabungan goal'), findsOneWidget);
      expect(find.text('100 sedang ditukar'), findsOneWidget);
    });

    testWidgets('utang poin ditampilkan dengan alasan', (tester) async {
      await tester.pumpWidget(_wrap(const PointsBalance(available: -10, debtReason: 'Tugas dibatalkan')));
      expect(find.text('Utang poin'), findsOneWidget);
      expect(find.text('-10'), findsOneWidget);
      expect(find.text('Tugas dibatalkan'), findsOneWidget);
      expect(find.text('Akan lunas otomatis dari poin berikutnya.'), findsOneWidget);
    });
  });

  group('AppButton', () {
    testWidgets('memanggil onPressed saat ditekan', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_wrap(AppButton(label: 'Kirim laporan', onPressed: () => taps++)));
      await tester.tap(find.text('Kirim laporan'));
      expect(taps, 1);
    });

    testWidgets('tombol non-aktif tidak bisa ditekan', (tester) async {
      await tester.pumpWidget(_wrap(const AppButton(label: 'Butuh 1 foto lagi', onPressed: null)));
      await tester.tap(find.text('Butuh 1 foto lagi'));
      expect(
        tester.getSemantics(find.byType(AppButton)),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
      );
    });
  });

  testWidgets('StreakRow menandai hari tertunda', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const StreakRow(
          count: 3,
          days: [
            StreakDay.success,
            StreakDay.success,
            StreakDay.pending,
            StreakDay.today,
            StreakDay.empty,
            StreakDay.empty,
            StreakDay.empty,
          ],
        ),
      ),
    );
    expect(find.text('Menunggu persetujuan, streak aman dulu.'), findsOneWidget);
    expect(find.bySemanticsLabel('Rabu: menunggu persetujuan'), findsOneWidget);
  });
}
