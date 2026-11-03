part of 'fake_repository.dart';

/// Tugas: meniru RLS tasks & task_assignments (admin menulis, semua anggota keluarga membaca)
/// dan CHECK constraint tabel tasks.
mixin _FakeTasks on _FakeState implements TaskRepository {
  @override
  Future<List<Task>> listTasks(String familyId, {bool archived = false}) async {
    _requireFamilyMember(familyId);
    return [
      for (final t in _tasks.values)
        if (t.familyId == familyId && t.isArchived == archived) t,
    ];
  }

  void _checkInput(String familyId, TaskInput input) {
    if (input.validate() != null) throw const AppException('invalid_task');
    for (final id in input.assigneeIds) {
      final m = _members[id]?.member;
      if (m == null || m.familyId != familyId) throw const AppException('not_authorized');
    }
  }

  @override
  Future<Task> createTask(String familyId, TaskInput input) async {
    _requireAdmin(familyId);
    _checkInput(familyId, input);
    final id = _id('task');
    _tasks[id] = Task.fromInput(input, id: id, familyId: familyId);
    _notifyFamily(familyId);
    return _tasks[id]!;
  }

  Task _requireTask(String taskId) => _tasks[taskId] ?? (throw const AppException('not_found'));

  @override
  Future<Task> updateTask(String taskId, TaskInput input) async {
    final task = _requireTask(taskId);
    _requireAdmin(task.familyId);
    _checkInput(task.familyId, input);
    _tasks[taskId] = Task.fromInput(input, id: taskId, familyId: task.familyId, isArchived: task.isArchived);
    _notifyFamily(task.familyId);
    return _tasks[taskId]!;
  }

  @override
  Future<void> setTaskArchived(String taskId, {required bool archived}) async {
    final task = _requireTask(taskId);
    _requireAdmin(task.familyId);
    _tasks[taskId] = Task.fromInput(task, id: taskId, familyId: task.familyId, isArchived: archived);
    _notifyFamily(task.familyId);
  }

  @override
  Future<List<TodayTask>> todayTasks(Member member) async {
    final tasks = await listTasks(member.familyId);
    return buildTodayTasks(
      tasks: tasks,
      submissions: [
        for (final s in _submissions)
          if (s.memberId == member.id) s.summary,
      ],
      memberId: member.id,
      today: familyToday(_families[member.familyId] ?? 'Asia/Jakarta', now: _clock()),
    );
  }

  /// Untuk tes: laporan dengan status & tanggal tertentu, tanpa melewati aturan submitTask.
  void debugAddSubmission({
    required String taskId,
    required String memberId,
    required SubmissionStatus status,
    required DateTime forDate,
    bool reversed = false,
  }) {
    final task = _tasks[taskId]!;
    _submissions.add(
      _FakeSubmission(
        id: _id('submission'),
        familyId: task.familyId,
        memberId: memberId,
        taskId: taskId,
        status: status,
        pointsSnapshot: task.points,
        forDate: dateOnly(forDate),
        createdAt: _clock(),
      )..reversed = reversed,
    );
  }
}
