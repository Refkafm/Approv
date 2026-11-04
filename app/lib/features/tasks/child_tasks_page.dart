import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/list_row_pill.dart';
import '../../data/app_exception.dart';
import '../../data/task_rules.dart';
import '../shell/reload_on_changes.dart';
import '../shell/session.dart';
import 'report_sheet.dart';
import '../../core/widgets/motion.dart';
import '../../l10n/strings.dart';

/// Daftar tugas anak (PRD layar A-3): tugas hari ini & statusnya. Ketuk tugas untuk melapor (A-4).
/// Status ikut berubah saat orang tua menyetujui/menolak (realtime).
class ChildTasksPage extends StatefulWidget {
  const ChildTasksPage({super.key});

  @override
  State<ChildTasksPage> createState() => _ChildTasksPageState();
}

class _ChildTasksPageState extends State<ChildTasksPage> with ReloadOnChanges {
  Future<List<TodayTask>>? _tasks;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tasks ??= _load();
    listenForChanges();
  }

  Future<List<TodayTask>> _load() {
    final session = SessionScope.read(context);
    return session.repository.todayTasks(session.activeMember!);
  }

  @override
  void reload() => setState(() {
    _tasks = _load();
  });

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _tasks = next;
    });
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    return SafeArea(
      child: ListenableBuilder(listenable: session.reports, builder: (context, _) => _buildList(session)),
    );
  }

  Widget _buildList(SessionController session) {
    final memberId = session.activeMember!.id;
    final queued = {for (final r in session.reports.pendingFor(memberId)) r.taskId};
    final dropped = session.reports.droppedMessage;
    return FutureBuilder<List<TodayTask>>(
      future: _tasks,
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <TodayTask>[];
        final today = all.where((t) => t.scheduledToday).toList();
        final otherDays = all.where((t) => !t.scheduledToday).toList();
        final remaining = today.where((t) => t.canReport && !queued.contains(t.task.id)).length;

        return RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.ink,
          backgroundColor: AppColors.sunflower,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpace.screenX, 16, AppSpace.screenX, 32),
            children: staggered([
              Text(context.s.todayTasks, style: AppText.displayLg),
              const SizedBox(height: 8),
              if (snapshot.connectionState == ConnectionState.done && !snapshot.hasError)
                Text(
                  today.isEmpty
                      ? context.s.noTasksForYou
                      : (remaining == 0 ? context.s.allTodayDone : context.s.tasksLeft(remaining)),
                  style: AppText.body.copyWith(color: AppColors.inkMuted),
                ),
              if (snapshot.hasError)
                Text(
                  snapshot.error is AppException
                      ? (snapshot.error! as AppException).message
                      : context.s.loadTasksFailed,
                  style: AppText.body.copyWith(color: AppColors.tangerineDeep),
                ),
              if (queued.isNotEmpty) ...[
                const SizedBox(height: 12),
                _Notice(context.s.queuedReports(queued.length), onRetry: session.flushReports),
              ],
              if (dropped != null) ...[
                const SizedBox(height: 12),
                _Notice(
                  dropped,
                  onClose: () {
                    session.reports.droppedMessage = null;
                    setState(() {});
                  },
                ),
              ],
              const SizedBox(height: 20),
              for (final item in today) ...[
                _TaskRow(item, queued: queued.contains(item.task.id)),
                const SizedBox(height: 10),
              ],
              if (otherDays.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(context.s.otherDays, style: AppText.titleLg),
                const SizedBox(height: 10),
                for (final item in otherDays) ...[
                  _TaskRow(item, queued: queued.contains(item.task.id)),
                  const SizedBox(height: 10),
                ],
              ],
            ]),
          ),
        );
      },
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text, {this.onRetry, this.onClose});

  final String text;
  final Future<void> Function()? onRetry;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.pastelPeach,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Row(
        children: [
          Expanded(child: Text(text, style: AppText.body)),
          if (onRetry != null) TextButton(onPressed: onRetry, child: Text(context.s.tryToSend)),
          if (onClose != null) TextButton(onPressed: onClose, child: Text(context.s.close)),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow(this.item, {this.queued = false});

  final TodayTask item;

  /// Sudah dilapor tapi masih di antrean offline.
  final bool queued;

  @override
  Widget build(BuildContext context) {
    final task = item.task;
    return ListRowPill(
      title: task.title,
      subtitle: queued ? context.s.waitingSignal : item.statusLabel,
      leading: CircleBadge(
        color: item.canReport && !queued ? AppColors.pastelPeach : AppColors.pastelLime,
        icon: AppIcons.task(task.icon),
      ),
      trailing: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Text('+${formatPoints(task.points)}', style: AppText.titleMd),
      ),
      onTap: !queued && (item.canReport || item.needsRetake) ? () => showReportSheet(context, item) : null,
    );
  }
}
