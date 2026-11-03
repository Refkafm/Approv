import 'package:family_points/data/app_exception.dart';
import 'package:family_points/data/fake/fake_repository.dart';
import 'package:family_points/data/models.dart';
import 'package:family_points/data/photo_models.dart';
import 'package:family_points/data/submission_repository.dart';
import 'package:family_points/data/task_models.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_photo_picker.dart';

Matcher _throwsCode(String code) => throwsA(isA<AppException>().having((e) => e.code, 'code', code));

PhotoCapture _photo([PhotoKind kind = PhotoKind.single, PhotoOrigin origin = PhotoOrigin.camera]) =>
    PhotoCapture(bytes: FakePhotoPicker.jpeg, kind: kind, origin: origin, takenAt: DateTime(2026, 11, 5, 10));

/// Aturan foto di repository palsu harus sama dengan _insert_photos & resubmit_photos di SQL.
void main() {
  late FakeRepository repo;
  late String parentId;
  late Member raka;
  late Map<String, Task> tasks;

  setUp(() async {
    repo = FakeRepository(clock: () => DateTime.utc(2026, 11, 5, 3));
    final code = await repo.debugSeedFamily();
    parentId = repo.debugSeedOwnerId!;
    await repo.signInAnonymously();
    raka = await repo.joinFamily(code: code);
    tasks = {for (final t in await repo.listTasks(raka.familyId)) t.title: t};
  });

  Future<Task> photoTask({bool beforeAfter = false, int minPhotos = 1}) => repo.debugAs(
    parentId,
    () => repo.createTask(
      raka.familyId,
      TaskInput(
        title: 'Siram tanaman',
        points: 30,
        frequency: TaskFrequency.daily,
        verification: TaskVerification.photo,
        minPhotos: minPhotos,
        beforeAfter: beforeAfter,
      ),
    ),
  );

  test('tugas berfoto: foto tersimpan & bisa dibuka anggota keluarga', () async {
    final pr = tasks['PR selesai tanpa disuruh']!;
    await repo.submitTask(member: raka, taskId: pr.id, photos: [_photo()]);

    final id = (await repo.debugAs(parentId, () => repo.pendingReviews(raka.familyId))).single.id;
    final photos = await repo.debugAs(parentId, () => repo.submissionPhotos(id));
    expect(photos.single.path, startsWith('${raka.familyId}/${raka.id}/'));
    expect(await repo.proofImage(photos.single), isA<MemoryImage>());
  });

  test('jumlah minimal & sebelum-sesudah', () async {
    final two = await photoTask(minPhotos: 2);
    await expectLater(
      repo.submitTask(member: raka, taskId: two.id, photos: [_photo()]),
      _throwsCode('photos_required'),
    );

    final ba = await photoTask(beforeAfter: true);
    await expectLater(
      repo.submitTask(member: raka, taskId: ba.id, photos: [_photo(PhotoKind.before)]),
      _throwsCode('photos_required'),
    );
    await repo.submitTask(member: raka, taskId: ba.id, photos: [_photo(PhotoKind.before), _photo(PhotoKind.after)]);
  });

  test('galeri hanya untuk tugas yang mengizinkan (PF-07)', () async {
    await expectLater(
      repo.submitTask(
        member: raka,
        taskId: tasks['PR selesai tanpa disuruh']!.id,
        photos: [_photo(PhotoKind.single, PhotoOrigin.gallery)],
      ),
      _throwsCode('invalid_photo'),
    );
    // "Nilai ujian ≥ 85" di template mengizinkan galeri
    await repo.submitTask(
      member: raka,
      taskId: tasks['Nilai ujian ≥ 85']!.id,
      photos: [_photo(PhotoKind.single, PhotoOrigin.gallery)],
    );
  });

  test('tugas tanpa foto menolak foto', () async {
    await expectLater(
      repo.submitTask(member: raka, taskId: tasks['Bantu cuci piring']!.id, photos: [_photo()]),
      _throwsCode('photos_not_allowed'),
    );
  });

  test('minta foto ulang → anak kirim foto baru ke laporan yang sama (PF-05)', () async {
    final pr = tasks['PR selesai tanpa disuruh']!;
    await repo.submitTask(member: raka, taskId: pr.id, photos: [_photo()]);
    final id = (await repo.debugAs(parentId, () => repo.pendingReviews(raka.familyId))).single.id;
    final first = (await repo.debugAs(parentId, () => repo.submissionPhotos(id))).single;

    await repo.debugAs(parentId, () => repo.reviewSubmission(id, ReviewAction.retake, reason: 'Fotonya buram'));
    final today = (await repo.todayTasks(raka)).firstWhere((t) => t.task.id == pr.id);
    expect(today.needsRetake, isTrue);
    expect(today.latest!.id, id);
    expect(today.latest!.reason, 'Fotonya buram');

    await repo.resubmitPhotos(member: raka, submissionId: id, photos: [_photo()]);
    final queue = await repo.debugAs(parentId, () => repo.pendingReviews(raka.familyId));
    expect(queue.single.id, id, reason: 'tetap laporan yang sama');
    final photos = await repo.debugAs(parentId, () => repo.submissionPhotos(id));
    expect(photos.single.id, isNot(first.id), reason: 'foto lama diganti');

    await expectLater(
      repo.resubmitPhotos(member: raka, submissionId: id, photos: [_photo()]),
      _throwsCode('not_awaiting_retake'),
    );
  });
}
