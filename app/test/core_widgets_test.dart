import 'package:family_points/core/format.dart';
import 'package:family_points/core/theme/app_theme.dart';
import 'package:family_points/core/widgets/app_button.dart';
import 'package:family_points/core/widgets/app_text_field.dart';
import 'package:family_points/core/widgets/goal_progress_bar.dart';
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

  group('GoalProgressBar', () {
    test('persen dibulatkan ke bawah; 100% hanya saat poin benar-benar cukup', () {
      expect(GoalProgressBar.percent(0, 5000), 0);
      expect(GoalProgressBar.percent(3200, 5000), 64);
      expect(GoalProgressBar.percent(4999, 5000), 99);
      expect(GoalProgressBar.percent(5000, 5000), 100);
      expect(GoalProgressBar.percent(9000, 5000), 100);
    });

    test('aman untuk saldo negatif dan target nol', () {
      expect(GoalProgressBar.fraction(-10, 5000), 0);
      expect(GoalProgressBar.fraction(100, 0), 0);
      expect(GoalProgressBar.fraction(9000, 5000), 1);
    });

    testWidgets('dibacakan sebagai teks oleh pembaca layar', (tester) async {
      await tester.pumpWidget(_wrap(const GoalProgressBar(saved: 3200, target: 5000, goalTitle: 'Sepatu')));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Goal Sepatu, 3.200 dari 5.000 poin, 64 persen'), findsOneWidget);
    });

    testWidgets('bar memenuhi lebar yang tersedia dan isiannya sesuai persen', (tester) async {
      await tester.pumpWidget(
        _wrap(const SizedBox(width: 300, child: GoalProgressBar(saved: 2500, target: 5000, goalTitle: 'Sepatu'))),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(GoalProgressBar)).width, 300);
      final fill = tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox));
      expect(fill.widthFactor, 0.5);
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

  group('AppTextField', () {
    testWidgets('kata sandi tersembunyi; tombol mata menampilkan & menyembunyikan lagi', (tester) async {
      final controller = TextEditingController(text: 'rahasia1');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_wrap(AppTextField(label: 'Kata sandi', controller: controller, obscureText: true)));
      bool obscured() => tester.widget<TextField>(find.byType(TextField)).obscureText;

      expect(obscured(), isTrue);
      await tester.tap(find.byTooltip('Tampilkan kata sandi'));
      await tester.pump();
      expect(obscured(), isFalse);
      await tester.tap(find.byTooltip('Sembunyikan kata sandi'));
      await tester.pump();
      expect(obscured(), isTrue);
    });

    testWidgets('kolom biasa tidak punya tombol mata', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_wrap(AppTextField(label: 'Email', controller: controller)));
      expect(find.byTooltip('Tampilkan kata sandi'), findsNothing);
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
