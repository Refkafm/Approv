import 'package:family_points/data/app_exception.dart';
import 'package:family_points/data/fake/fake_repository.dart';
import 'package:family_points/data/models.dart';
import 'package:family_points/data/submission_repository.dart';
import 'package:family_points/data/task_models.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher _throwsCode(String code) => throwsA(isA<AppException>().having((e) => e.code, 'code', code));

/// Laporan & persetujuan di repository palsu harus sama dengan RPC submit_task / review_submission.
void main() {
  late FakeRepository repo;
  late String parentId;
  late Member raka;
  late Map<String, Task> tasks;

  setUp(() async {
    repo = FakeRepository(clock: () => DateTime.utc(2026, 11, 5, 3)); // Kamis 10:00 WIB
    final code = await repo.debugSeedFamily();
    parentId = repo.debugSeedOwnerId!;
    await repo.signInAnonymously();
    raka = await repo.joinFamily(code: code);
    tasks = {for (final t in await repo.listTasks(raka.familyId)) t.title: t};
  });

  Future<String> pendingId() async =>
      (await repo.debugAs(parentId, () => repo.pendingReviews(raka.familyId))).single.id;

  test('lapor tugas persetujuan → menunggu; disetujui + bonus → poin masuk', () async {
    await repo.submitTask(member: raka, taskId: tasks['Bantu cuci piring']!.id, note: ' Sudah bersih ');
    expect(repo.debugBalance(raka.id), 0);

    final queue = await repo.debugAs(parentId, () => repo.pendingReviews(raka.familyId));
    expect(queue.single.memberName, 'Raka');
    expect(queue.single.note, 'Sudah bersih');
    expect(queue.single.points, 50);

    await repo.debugAs(parentId, () => repo.reviewSubmission(queue.single.id, ReviewAction.approve, bonus: 10));
    expect(repo.debugBalance(raka.id), 60);
    expect(
      (await repo.todayTasks(raka)).firstWhere((t) => t.task.title == 'Bantu cuci piring').statusLabel,
      'Disetujui',
    );
  });

  test('tugas otomatis langsung disetujui dan memberi poin', () async {
    await repo.submitTask(member: raka, taskId: tasks['Rapikan kasur']!.id);
    expect(repo.debugBalance(raka.id), 20);
    expect(await repo.debugAs(parentId, () => repo.pendingReviews(raka.familyId)), isEmpty);
  });

  test('batas harian & tugas berfoto', () async {
    await repo.submitTask(member: raka, taskId: tasks['Bantu cuci piring']!.id);
    await expectLater(
      repo.submitTask(member: raka, taskId: tasks['Bantu cuci piring']!.id),
      _throwsCode('task_limit_reached'),
    );
    await expectLater(
      repo.submitTask(member: raka, taskId: tasks['PR selesai tanpa disuruh']!.id),
      _throwsCode('photos_required'),
    );
  });

  test('tolak wajib alasan; setelah ditolak anak bisa lapor ulang', () async {
    await repo.submitTask(member: raka, taskId: tasks['Bantu cuci piring']!.id);
    final id = await pendingId();
    await expectLater(
      repo.debugAs(parentId, () => repo.reviewSubmission(id, ReviewAction.reject)),
      _throwsCode('reason_required'),
    );

    await repo.debugAs(parentId, () => repo.reviewSubmission(id, ReviewAction.reject, reason: 'Masih ada yang kotor'));
    final status = (await repo.todayTasks(raka)).firstWhere((t) => t.task.title == 'Bantu cuci piring');
    expect(status.statusLabel, 'Ditolak: Masih ada yang kotor. Coba lagi ya');
    expect(status.canReport, isTrue);
    await repo.submitTask(member: raka, taskId: tasks['Bantu cuci piring']!.id);
  });

  test('laporan yang sudah diproses tidak bisa diproses lagi (nama admin disebut)', () async {
    await repo.submitTask(member: raka, taskId: tasks['Bantu cuci piring']!.id);
    final id = await pendingId();
    await repo.debugAs(parentId, () => repo.reviewSubmission(id, ReviewAction.approve));
    await expectLater(
      repo.debugAs(parentId, () => repo.reviewSubmission(id, ReviewAction.approve)),
      throwsA(isA<AppException>().having((e) => e.message, 'message', 'Laporan ini sudah diproses oleh Ibu Rina.')),
    );
  });

  test('anak tidak bisa menyetujui; foto ulang hanya untuk tugas berfoto', () async {
    await repo.submitTask(member: raka, taskId: tasks['Bantu cuci piring']!.id);
    final id = await pendingId();
    await expectLater(repo.reviewSubmission(id, ReviewAction.approve), _throwsCode('not_authorized'));
    await expectLater(
      repo.debugAs(parentId, () => repo.reviewSubmission(id, ReviewAction.retake)),
      _throwsCode('retake_requires_photo'),
    );
  });

  test('watchFamily berbunyi saat ada laporan dan persetujuan', () async {
    var events = 0;
    final sub = repo.watchFamily(raka.familyId).listen((_) => events++);
    await repo.submitTask(member: raka, taskId: tasks['Bantu cuci piring']!.id);
    final id = await pendingId();
    await repo.debugAs(parentId, () => repo.reviewSubmission(id, ReviewAction.approve));
    await Future<void>.delayed(Duration.zero);
    expect(events, 2);
    await sub.cancel();
  });
}
