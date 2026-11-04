import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/widgets/list_row_pill.dart';
import '../../core/widgets/pill_chip.dart';
import '../../data/app_exception.dart';
import '../../data/models.dart';
import '../../data/task_models.dart';
import '../shell/session.dart';
import '../../core/widgets/motion.dart';
import '../../l10n/strings.dart';

/// Daftar tugas orang tua (PRD layar O-6): filter aktif/arsip, per anak, per frekuensi.
class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  bool _archived = false;
  String? _childId;
  TaskFrequency? _frequency;
  Future<(List<Task>, List<Member>)>? _data;
  ValueNotifier<int>? _revision;

  SessionController get _session => SessionScope.read(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _data ??= _load();
    // Muat ulang saat form tugas menyimpan perubahan
    _revision ??= _session.dataRevision..addListener(_reload);
  }

  @override
  void dispose() {
    _revision?.removeListener(_reload);
    super.dispose();
  }

  Future<(List<Task>, List<Member>)> _load() async {
    final repo = _session.repository;
    final familyId = _session.activeMember!.familyId;
    final tasks = await repo.listTasks(familyId, archived: _archived);
    final members = await repo.familyMembers(familyId);
    return (tasks, members.where((m) => m.role == MemberRole.member).toList());
  }

  // Blok {} wajib: closure setState tidak boleh mengembalikan Future
  void _reload() => setState(() {
    _data = _load();
  });

  void _openForm([Task? task]) => context.push(task == null ? '/parent/tasks/new' : '/parent/tasks/edit', extra: task);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<(List<Task>, List<Member>)>(
        future: _data,
        builder: (context, snapshot) {
          final (tasks, children) = snapshot.data ?? (const <Task>[], const <Member>[]);
          final names = {for (final c in children) c.id: c.name};
          final visible = tasks
              .where((t) => _childId == null || t.isFor(_childId!))
              .where((t) => _frequency == null || t.frequency == _frequency)
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpace.screenX, 16, AppSpace.screenX, 32),
            children: staggered([
              Row(
                children: [
                  Expanded(child: Text(context.s.tasks, style: AppText.displayLg)),
                  IconCircleButton(icon: AppIcons.plus, semanticLabel: context.s.newTask, onPressed: () => _openForm()),
                ],
              ),
              const SizedBox(height: 16),
              ChipScroller(
                children: [
                  PillChip(
                    label: context.s.activeFilter,
                    selected: !_archived,
                    onTap: () {
                      _archived = false;
                      _reload();
                    },
                  ),
                  PillChip(
                    label: context.s.archivedFilter,
                    selected: _archived,
                    onTap: () {
                      _archived = true;
                      _reload();
                    },
                  ),
                ],
              ),
              if (children.length > 1) ...[
                const SizedBox(height: 8),
                ChipScroller(
                  children: [
                    PillChip(
                      label: context.s.allChildren,
                      selected: _childId == null,
                      onTap: () => setState(() => _childId = null),
                    ),
                    for (final child in children)
                      PillChip(
                        label: child.name,
                        selected: _childId == child.id,
                        onTap: () => setState(() => _childId = child.id),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              ChipScroller(
                children: [
                  PillChip(
                    label: context.s.allFrequencies,
                    selected: _frequency == null,
                    onTap: () => setState(() => _frequency = null),
                  ),
                  for (final f in TaskFrequency.values)
                    PillChip(label: f.label, selected: _frequency == f, onTap: () => setState(() => _frequency = f)),
                ],
              ),
              const SizedBox(height: 20),
              if (snapshot.hasError)
                Text(
                  snapshot.error is AppException
                      ? (snapshot.error! as AppException).message
                      : context.s.loadTasksFailed,
                  style: AppText.body.copyWith(color: AppColors.tangerineDeep),
                )
              else if (snapshot.connectionState == ConnectionState.done && visible.isEmpty)
                Text(
                  _archived
                      ? context.s.noArchivedTasks
                      : (tasks.isEmpty ? context.s.noTasksYet : context.s.noMatchingTasks),
                  style: AppText.body.copyWith(color: AppColors.inkMuted),
                ),
              for (final task in visible) ...[
                ListRowPill(
                  title: task.title,
                  subtitle: [
                    task.assigneeIds.isEmpty
                        ? context.s.allChildren
                        : task.assigneeIds.map((id) => names[id] ?? '?').join(', '),
                    task.scheduleLabel,
                  ].join(' · '),
                  leading: CircleBadge(color: AppColors.pastelPeach, icon: AppIcons.task(task.icon)),
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text('+${formatPoints(task.points)}', style: AppText.titleMd),
                  ),
                  onTap: () => _openForm(task),
                ),
                const SizedBox(height: 10),
              ],
            ]),
          );
        },
      ),
    );
  }
}
