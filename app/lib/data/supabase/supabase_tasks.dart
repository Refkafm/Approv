part of 'supabase_repository.dart';

mixin _SupabaseTasks on _SupabaseBase implements TaskRepository {
  static const _taskColumns = '*, task_assignments(member_id)';

  @override
  Future<List<Task>> listTasks(String familyId, {bool archived = false}) => _guard(() async {
    final rows = await _client
        .from('tasks')
        .select(_taskColumns)
        .eq('family_id', familyId)
        .eq('is_archived', archived)
        .order('created_at');
    return rows.map(Task.fromRow).toList();
  });

  Future<Task> _fetchTask(String taskId) async {
    final row = await _client.from('tasks').select(_taskColumns).eq('id', taskId).single();
    return Task.fromRow(row);
  }

  // Dua langkah (tugas lalu penugasan), tidak atomik. Bila langkah kedua gagal, tugas tetap ada
  // tanpa penugasan (= untuk semua anak) dan admin bisa menyimpan ulang.
  Future<void> _replaceAssignments(String taskId, List<String> memberIds) async {
    await _client.from('task_assignments').delete().eq('task_id', taskId);
    if (memberIds.isEmpty) return;
    await _client.from('task_assignments').insert([
      for (final id in memberIds) {'task_id': taskId, 'member_id': id},
    ]);
  }

  @override
  Future<Task> createTask(String familyId, TaskInput input) => _guard(() async {
    final row = await _client.from('tasks').insert({...input.toRow(), 'family_id': familyId}).select('id').single();
    final id = row['id'] as String;
    await _replaceAssignments(id, input.assigneeIds);
    return _fetchTask(id);
  });

  @override
  Future<Task> updateTask(String taskId, TaskInput input) => _guard(() async {
    await _client.from('tasks').update(input.toRow()).eq('id', taskId);
    await _replaceAssignments(taskId, input.assigneeIds);
    return _fetchTask(taskId);
  });

  @override
  Future<void> setTaskArchived(String taskId, {required bool archived}) =>
      _guard(() => _client.from('tasks').update({'is_archived': archived}).eq('id', taskId));

  @override
  Future<List<TodayTask>> todayTasks(Member member) => _guard(() async {
    final family = await _client.from('families').select('timezone').eq('id', member.familyId).single();
    final today = familyToday(family['timezone'] as String);
    final monday = weekStart(today);
    final tasks = await listTasks(member.familyId);

    const columns = 'id, task_id, status, for_date, created_at, reversed_at, reject_reason';
    final rows = [
      ...await _client
          .from('task_submissions')
          .select(columns)
          .eq('member_id', member.id)
          .gte('for_date', _isoDate(monday)),
    ];
    // Tugas "sekali" dihitung sepanjang masa
    final onceIds = [
      for (final t in tasks)
        if (t.frequency == TaskFrequency.once) t.id,
    ];
    if (onceIds.isNotEmpty) {
      rows.addAll(
        await _client
            .from('task_submissions')
            .select(columns)
            .eq('member_id', member.id)
            .inFilter('task_id', onceIds)
            .lt('for_date', _isoDate(monday)),
      );
    }

    return buildTodayTasks(
      tasks: tasks,
      submissions: rows.map(SubmissionSummary.fromRow).toList(),
      memberId: member.id,
      today: today,
    );
  });
}
