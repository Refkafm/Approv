import 'package:family_points/data/app_exception.dart';
import 'package:family_points/data/fake/fake_repository.dart';
import 'package:family_points/data/models.dart';
import 'package:family_points/data/task_models.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher _throwsCode(String code) => throwsA(isA<AppException>().having((e) => e.code, 'code', code));

const _siram = TaskInput(
  title: 'Siram tanaman',
  icon: 'plant',
  points: 30,
  frequency: TaskFrequency.daily,
  verification: TaskVerification.approve,
);

/// Hak akses tugas di repository palsu harus sama dengan RLS tasks / task_assignments.
void main() {
  late FakeRepository repo;
  late String familyId;
  late Member raka;
  late Member kiara;

  setUp(() async {
    // 10:00 WIB, Kamis 5 November 2026
    repo = FakeRepository(clock: () => DateTime.utc(2026, 11, 5, 3));
    await repo.signInWithGoogle();
    familyId = await repo.createFamily(familyName: 'Keluarga Rina', ownerName: 'Ibu Rina');
    raka = await repo.addChild(familyId: familyId, name: 'Raka');
    kiara = await repo.addChild(familyId: familyId, name: 'Kiara');
  });

  test('admin membuat, mengubah, dan mengarsipkan tugas', () async {
    final task = await repo.createTask(familyId, _siram);
    expect((await repo.listTasks(familyId)).single.title, 'Siram tanaman');

    final updated = await repo.updateTask(
      task.id,
      TaskInput(
        title: 'Siram tanaman depan',
        points: 40,
        frequency: TaskFrequency.repeat,
        maxPerDay: 2,
        verification: TaskVerification.auto,
        assigneeIds: [raka.id],
      ),
    );
    expect(updated.points, 40);
    expect(updated.assigneeIds, [raka.id]);

    await repo.setTaskArchived(task.id, archived: true);
    expect(await repo.listTasks(familyId), isEmpty);
    expect((await repo.listTasks(familyId, archived: true)).single.id, task.id);
  });

  test('isian tidak valid ditolak', () async {
    await expectLater(
      repo.createTask(
        familyId,
        const TaskInput(title: 'x', points: 0, frequency: TaskFrequency.daily, verification: TaskVerification.auto),
      ),
      _throwsCode('invalid_task'),
    );
  });

  test('anak tidak bisa membuat atau mengubah tugas', () async {
    final task = await repo.createTask(familyId, _siram);
    final code = await repo.createInvite(familyId: familyId, role: MemberRole.member, memberId: raka.id);
    await repo.signInAnonymously();
    await repo.joinFamily(code: code);

    expect((await repo.listTasks(familyId)).single.id, task.id);
    await expectLater(repo.createTask(familyId, _siram), _throwsCode('not_authorized'));
    await expectLater(repo.updateTask(task.id, _siram), _throwsCode('not_authorized'));
    await expectLater(repo.setTaskArchived(task.id, archived: true), _throwsCode('not_authorized'));
  });

  test('tidak bisa menugaskan anggota keluarga lain', () async {
    final otherCode = await repo.debugSeedFamily(childName: 'Orang lain');
    expect(otherCode, isNotEmpty);
    final other = (await repo.familyMembers(familyId)).length;
    expect(other, 3);

    final stranger = Member(id: 'member-asing', familyId: 'family-asing', role: MemberRole.member, name: 'X');
    await expectLater(
      repo.createTask(
        familyId,
        TaskInput(
          title: 'x',
          points: 5,
          frequency: TaskFrequency.daily,
          verification: TaskVerification.auto,
          assigneeIds: [stranger.id],
        ),
      ),
      _throwsCode('not_authorized'),
    );
  });

  test('todayTasks: hanya tugas anak ini, dengan status laporan hari ini', () async {
    final siram = await repo.createTask(familyId, _siram);
    await repo.createTask(
      familyId,
      TaskInput(
        title: 'Khusus Kiara',
        points: 10,
        frequency: TaskFrequency.daily,
        verification: TaskVerification.approve,
        assigneeIds: [kiara.id],
      ),
    );
    repo.debugAddSubmission(
      taskId: siram.id,
      memberId: raka.id,
      status: SubmissionStatus.approved,
      forDate: DateTime(2026, 11, 5),
    );

    final today = await repo.todayTasks(raka);
    expect(today.single.task.title, 'Siram tanaman');
    expect(today.single.statusLabel, 'Disetujui');

    final forKiara = await repo.todayTasks(kiara);
    expect(forKiara.map((t) => t.task.title), unorderedEquals(['Siram tanaman', 'Khusus Kiara']));
    expect(forKiara.every((t) => t.canReport), isTrue);
  });
}
