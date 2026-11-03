import 'dart:io';
import 'dart:typed_data';

import 'package:family_points/app.dart';
import 'package:family_points/core/widgets/app_button.dart';
import 'package:family_points/data/fake/fake_repository.dart';
import 'package:family_points/data/models.dart';
import 'package:family_points/data/photo_models.dart';
import 'package:family_points/data/report_queue.dart';
import 'package:family_points/data/task_models.dart';
import 'package:family_points/data/task_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// Antrean offline laporan (Rencana minggu 8): laporan tanpa sinyal disimpan, lalu dikirim ulang
/// dengan waktu lapor aslinya (submit_task p_reported_at, maks 24 jam).
void main() {
  late DateTime now;
  late FakeRepository repo;
  late Member raka;
  late String parentId;
  late Map<String, Task> tasks;
  late ReportQueue queue;

  setUp(() async {
    now = DateTime.utc(2026, 11, 5, 16, 30); // Kamis 23:30 WIB
    repo = FakeRepository(clock: () => now);
    final code = await repo.debugSeedFamily();
    parentId = repo.debugSeedOwnerId!;
    await repo.signInAnonymously();
    raka = await repo.joinFamily(code: code);
    tasks = {for (final t in await repo.listTasks(raka.familyId)) t.title: t};
    queue = ReportQueue(repo, clock: () => now);
  });

  String piring() => tasks['Bantu cuci piring']!.id;
  Future<TodayTask> piringToday() async =>
      (await repo.todayTasks(raka)).firstWhere((t) => t.task.title == 'Bantu cuci piring');

  test('tanpa sinyal → disimpan; online lagi → terkirim untuk hari aslinya', () async {
    repo.debugOffline = true;
    expect(await queue.submit(member: raka, taskId: piring(), note: 'Bersih'), isFalse);
    expect(queue.isQueued(raka.id, piring()), isTrue);

    // Sinyal kembali besok paginya (Jumat 07:00 WIB)
    now = DateTime.utc(2026, 11, 6, 0);
    repo.debugOffline = false;
    expect(await queue.flush(raka), 1);
    expect(queue.pendingFor(raka.id), isEmpty);

    // Laporan dihitung untuk Kamis, jadi jatah Jumat masih utuh
    expect((await piringToday()).canReport, isTrue);
  });

  test('masih tanpa sinyal: antrean tetap utuh', () async {
    repo.debugOffline = true;
    await queue.submit(member: raka, taskId: piring());
    expect(await queue.flush(raka), 0);
    expect(queue.pendingFor(raka.id), hasLength(1));
  });

  test('lebih dari 24 jam dibuang dengan pesan', () async {
    repo.debugOffline = true;
    await queue.submit(member: raka, taskId: piring());
    now = now.add(const Duration(hours: 25));
    repo.debugOffline = false;
    expect(await queue.flush(raka), 0);
    expect(queue.pendingFor(raka.id), isEmpty);
    expect(queue.droppedMessage, contains('24 jam'));
  });

  test('ditolak server (mis. jatah sudah terpakai) dibuang, tidak dicoba terus', () async {
    repo.debugOffline = true;
    await queue.submit(member: raka, taskId: piring());
    repo.debugOffline = false;
    await repo.submitTask(member: raka, taskId: piring());
    expect(await queue.flush(raka), 0);
    expect(queue.pendingFor(raka.id), isEmpty);
    expect(queue.droppedMessage, startsWith('Satu laporan tidak terkirim'));
  });

  test('file antrean bertahan setelah app ditutup (termasuk foto)', () async {
    final dir = await Directory.systemTemp.createTemp('report_queue');
    addTearDown(() => dir.delete(recursive: true));
    final store = FileReportQueueStore(File('${dir.path}/queue.json'));
    final photo = PhotoCapture(
      bytes: Uint8List.fromList([1, 2, 3]),
      kind: PhotoKind.after,
      origin: PhotoOrigin.camera,
      takenAt: DateTime.utc(2026, 11, 5, 16),
    );
    repo.debugOffline = true;
    await ReportQueue(repo, store: store, clock: () => now).submit(member: raka, taskId: piring(), photos: [photo]);

    final reopened = ReportQueue(repo, store: store, clock: () => now);
    await reopened.load();
    final saved = reopened.pendingFor(raka.id).single;
    expect(saved.reportedAt, now);
    expect(saved.photos.single.bytes, [1, 2, 3]);
    expect(saved.photos.single.kind, PhotoKind.after);
  });

  testWidgets('anak melapor tanpa sinyal: tugas "Menunggu sinyal", lalu terkirim', (tester) async {
    repo.debugOffline = true;
    await tester.pumpWidget(FamilyPointsApp(repository: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Tugas').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bantu cuci piring'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Kirim laporan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Laporan disimpan'), findsOneWidget);
    expect(find.text('Menunggu sinyal'), findsOneWidget);
    expect(find.textContaining('1 laporan menunggu sinyal'), findsOneWidget);

    repo.debugOffline = false;
    await tester.tap(find.text('Coba kirim'));
    await tester.pumpAndSettle();
    expect(find.text('Menunggu sinyal'), findsNothing);
    // Antrean app memakai jam asli, bukan jam tes; cukup pastikan laporannya sampai ke orang tua
    final pending = await repo.debugAs(parentId, () => repo.pendingReviews(raka.familyId));
    expect(pending.single.taskTitle, 'Bantu cuci piring');
  });
}
