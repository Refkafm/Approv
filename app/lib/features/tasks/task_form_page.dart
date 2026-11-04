import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/number_stepper.dart';
import '../../core/widgets/pill_chip.dart';
import '../../core/widgets/pressable.dart';
import '../../data/app_exception.dart';
import '../../data/models.dart';
import '../../data/task_models.dart';
import '../onboarding/onboarding_scaffold.dart';
import '../shell/session.dart';
import '../../l10n/strings.dart';

/// Buat / ubah tugas (PRD layar O-7, T-01–T-05, T-08, PF-01, PF-06, PF-07).
/// Setelah menyimpan, memanggil [SessionController.markDataChanged] supaya daftar tugas dimuat ulang.
/// Tenggat & pengingat (T-06, P1) menyusul.
class TaskFormPage extends StatefulWidget {
  const TaskFormPage({super.key, this.task, this.isEdit = false});

  /// Tugas yang diubah; null untuk tugas baru.
  final Task? task;

  /// true bila dibuka dari route edit (task null berarti data hilang, mis. setelah app dipulihkan).
  final bool isEdit;

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  late final Task? _task = widget.task;
  late final _title = TextEditingController(text: _task?.title);
  late final _points = TextEditingController(text: _task?.points.toString());
  late final _description = TextEditingController(text: _task?.description);
  late String _icon = _task?.icon ?? 'bed';
  late TaskFrequency _frequency = _task?.frequency ?? TaskFrequency.daily;
  late final Set<int> _days = {...?_task?.daysOfWeek};
  late int _maxPerDay = _task?.maxPerDay ?? 1;
  late TaskVerification _verification = _task?.verification ?? TaskVerification.approve;
  late int _minPhotos = _task?.minPhotos ?? 1;
  late bool _beforeAfter = _task?.beforeAfter ?? false;
  late bool _allowGallery = _task?.allowGallery ?? false;
  late Set<String> _assignees = {...?_task?.assigneeIds};
  Future<List<Member>>? _children;
  bool _busy = false;
  String? _error;

  SessionController get _session => SessionScope.read(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _children ??= _session.repository
        .familyMembers(_session.activeMember!.familyId)
        .then((all) => all.where((m) => m.role == MemberRole.member).toList());
  }

  @override
  void dispose() {
    _title.dispose();
    _points.dispose();
    _description.dispose();
    super.dispose();
  }

  TaskInput get _input => TaskInput(
    title: _title.text,
    icon: _icon,
    description: _description.text,
    points: int.tryParse(_points.text) ?? 0,
    frequency: _frequency,
    daysOfWeek: _days.toList(),
    maxPerDay: _maxPerDay,
    verification: _verification,
    minPhotos: _minPhotos,
    beforeAfter: _beforeAfter,
    allowGallery: _allowGallery,
    assigneeIds: _assignees.toList(),
  );

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      _session.markDataChanged();
      if (mounted) context.pop();
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _save() {
    final input = _input;
    final invalid = input.validate();
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    final repo = _session.repository;
    final task = _task;
    _run(
      () => task == null ? repo.createTask(_session.activeMember!.familyId, input) : repo.updateTask(task.id, input),
    );
  }

  void _setFrequency(TaskFrequency f) => setState(() {
    // "Berulang" biasanya lebih dari sekali sehari
    if (f == TaskFrequency.repeat && _maxPerDay == 1) _maxPerDay = 2;
    _frequency = f;
  });

  @override
  Widget build(BuildContext context) {
    final task = _task;
    if (widget.isEdit && task == null) {
      return OnboardingScaffold(title: context.s.taskNotFound, onBack: () => context.pop(), children: const []);
    }

    return OnboardingScaffold(
      title: task == null ? context.s.newTask : context.s.editTask,
      onBack: _busy ? null : () => context.pop(),
      children: [
        AppTextField(
          label: context.s.taskNameLabel,
          controller: _title,
          hint: context.s.taskNameHint,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 60,
        ),
        const SizedBox(height: 20),
        _Label(context.s.iconLabel),
        _IconPicker(selected: _icon, onChanged: (key) => setState(() => _icon = key)),
        const SizedBox(height: 20),
        AppTextField(
          label: context.s.pointsLabel,
          controller: _points,
          hint: '50',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 6,
        ),
        if (task != null) _Hint(context.s.pointsChangeHint),
        const SizedBox(height: 20),
        AppTextField(
          label: context.s.descriptionOptional,
          controller: _description,
          hint: context.s.taskDescHint,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 500,
          maxLines: 3,
        ),
        const SizedBox(height: 28),
        _Label(context.s.howOften),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in TaskFrequency.values)
              PillChip(label: f.label, selected: _frequency == f, onTap: () => _setFrequency(f)),
          ],
        ),
        if (_frequency == TaskFrequency.daysOfWeek) ...[
          const SizedBox(height: 16),
          _Label(context.s.daysLabel),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final MapEntry(key: day, value: name) in isoDayNames.entries)
                PillChip(
                  label: name,
                  selected: _days.contains(day),
                  onTap: () => setState(() => _days.contains(day) ? _days.remove(day) : _days.add(day)),
                ),
            ],
          ),
        ],
        if (_frequency.hasDailyLimit) ...[
          const SizedBox(height: 12),
          NumberStepper(
            label: context.s.maxPerDay,
            value: _maxPerDay,
            min: 1,
            max: 20,
            unit: '×',
            onChanged: (v) => setState(() => _maxPerDay = v),
          ),
          _Hint(context.s.maxPerDayHint),
        ],
        const SizedBox(height: 28),
        _Label(context.s.verificationLabel),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in TaskVerification.values)
              PillChip(label: v.label, selected: _verification == v, onTap: () => setState(() => _verification = v)),
          ],
        ),
        _Hint(switch (_verification) {
          TaskVerification.auto => context.s.verifyAutoHint,
          TaskVerification.approve => context.s.verifyApproveHint,
          TaskVerification.photo => context.s.verifyPhotoHint,
        }),
        if (_verification == TaskVerification.photo) ...[
          const SizedBox(height: 12),
          NumberStepper(
            label: context.s.minPhotos,
            value: _minPhotos,
            min: 1,
            max: 3,
            onChanged: (v) => setState(() => _minPhotos = v),
          ),
          _SwitchRow(
            label: context.s.beforeAfterLabel,
            description: context.s.beforeAfterDesc,
            value: _beforeAfter,
            onChanged: (v) => setState(() => _beforeAfter = v),
          ),
          _SwitchRow(
            label: context.s.allowGalleryLabel,
            description: context.s.allowGalleryDesc,
            value: _allowGallery,
            onChanged: (v) => setState(() => _allowGallery = v),
          ),
        ],
        const SizedBox(height: 28),
        _Label(context.s.forWhom),
        FutureBuilder<List<Member>>(
          future: _children,
          builder: (context, snapshot) {
            final children = snapshot.data ?? const <Member>[];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PillChip(
                      label: context.s.allChildren,
                      selected: _assignees.isEmpty,
                      onTap: () => setState(() => _assignees = {}),
                    ),
                    for (final child in children)
                      PillChip(
                        label: child.name,
                        selected: _assignees.contains(child.id),
                        onTap: () => setState(
                          () => _assignees.contains(child.id) ? _assignees.remove(child.id) : _assignees.add(child.id),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),
        AppButton(label: _busy ? context.s.saving : context.s.saveTask, onPressed: _busy ? null : _save),
        FormError(_error),
        if (task != null) ...[
          const SizedBox(height: 16),
          AppButton(
            label: task.isArchived ? context.s.reactivate : context.s.archiveAction,
            icon: task.isArchived ? AppIcons.arrowCounterClockwise : AppIcons.archive,
            variant: AppButtonVariant.secondary,
            onPressed: _busy
                ? null
                : () => _run(() => _session.repository.setTaskArchived(task.id, archived: !task.isArchived)),
          ),
          if (!task.isArchived) _Hint(context.s.archiveTaskHint),
        ],
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: AppText.label),
  );
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(text, style: AppText.bodySm.copyWith(color: AppColors.inkMuted)),
  );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.label, required this.description, required this.value, required this.onChanged});

  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.body),
                  Text(description, style: AppText.bodySm.copyWith(color: AppColors.inkMuted)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              thumbColor: const WidgetStatePropertyAll(AppColors.ink),
              trackColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected) ? AppColors.sunflower : AppColors.surface,
              ),
              trackOutlineColor: const WidgetStatePropertyAll(AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final MapEntry(key: key, value: icon) in AppIcons.tasks.entries)
          Pressable(
            semanticLabel: context.s.iconSemantic(context.s.taskIconName(key)),
            selected: key == selected,
            onTap: () => onChanged(key),
            builder: (context, pressed) => Container(
              width: TapTarget.parent,
              height: TapTarget.parent,
              decoration: BoxDecoration(
                color: key == selected ? AppColors.sunflower : AppColors.surface,
                shape: BoxShape.circle,
                border: key == selected
                    ? Border.all(color: AppColors.ink, width: AppStroke.width)
                    : Border.all(color: AppColors.lineSoft, width: AppStroke.softWidth),
              ),
              child: Icon(icon, size: 22, color: key == selected ? AppColors.ink : AppColors.inkMuted),
            ),
          ),
      ],
    );
  }
}
