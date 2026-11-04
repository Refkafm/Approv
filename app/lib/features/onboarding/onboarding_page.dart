import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/invite_code_card.dart';
import '../../core/widgets/list_row_pill.dart';
import '../../core/widgets/member_avatar.dart';
import '../../core/widgets/selectable_card.dart';
import '../../data/app_exception.dart';
import '../../data/models.dart';
import '../../data/reward_models.dart';
import '../../data/task_models.dart';
import '../family/child_form.dart';
import '../shell/session.dart';
import 'onboarding_scaffold.dart';
import '../../l10n/strings.dart';

/// Setup awal orang tua (PRD Flow 1, layar O-2, A-02, A-03, M-01):
/// keluarga → anak → template usia → review → kode untuk HP anak. Target ≤ 10 menit.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

enum _Step { family, children, template, review, connect }

class _OnboardingPageState extends State<OnboardingPage> {
  _Step _step = _Step.family;
  final _familyName = TextEditingController();
  final _ownerName = TextEditingController();
  String? _familyId;
  final _children = <Member>[];
  AgeBand? _band;
  List<Task> _tasks = const [];
  List<Reward> _rewards = const [];
  final _codes = <String, String>{};
  bool _busy = false;
  String? _error;

  SessionController get _session => SessionScope.read(context);

  @override
  void dispose() {
    _familyName.dispose();
    _ownerName.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _go(_Step step) => setState(() {
    _step = step;
    _error = null;
  });

  Future<void> _createFamily() => _run(() async {
    final familyName = _familyName.text.trim();
    final ownerName = _ownerName.text.trim();
    if (familyName.isEmpty || ownerName.isEmpty) {
      throw _FormMessage(context.s.onbNamesRequired);
    }
    // Tahan redirect: setelah keluarga dibuat, akun ini sudah "punya keluarga" tapi setup belum selesai
    _session.beginFlow();
    try {
      _familyId = await _session.repository.createFamily(
        familyName: familyName,
        ownerName: ownerName,
        locale: _session.language,
      );
    } on AppException {
      await _session.finishFlow();
      rethrow;
    }
    _session.track(AnalyticsEvent.familyCreated);
    _go(_Step.children);
  });

  Future<void> _addChild(String name, String avatar, DateTime? birthDate) async {
    final child = await _session.repository.addChild(
      familyId: _familyId!,
      name: name,
      avatar: avatar,
      birthDate: birthDate,
    );
    setState(() => _children.add(child));
  }

  AgeBand get _suggestedBand {
    final today = DateTime.now();
    final age = _children.map((c) => c.ageOn(today)).whereType<int>().firstOrNull;
    return age == null ? AgeBand.middle : AgeBand.forAge(age);
  }

  Future<void> _applyTemplate() => _run(() async {
    final repo = _session.repository;
    await repo.applyTemplate(familyId: _familyId!, band: _band ?? _suggestedBand);
    _tasks = await repo.listTasks(_familyId!);
    _rewards = await repo.listRewards(_familyId!);
    if (_tasks.length >= 3 && _rewards.length >= 2 && _children.isNotEmpty) {
      _session.track(AnalyticsEvent.setupCompleted, {
        'tasks': _tasks.length,
        'rewards': _rewards.length,
        'children': _children.length,
      });
    }
    _go(_Step.review);
  });

  Future<void> _openConnect() => _run(() async {
    for (final child in _children) {
      _codes[child.id] ??= await _session.repository.createInvite(
        familyId: _familyId!,
        role: MemberRole.member,
        memberId: child.id,
      );
    }
    _go(_Step.connect);
  });

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return switch (_step) {
      _Step.family => OnboardingScaffold(
        title: context.s.onbCreateTitle,
        subtitle: context.s.onbCreateSubtitle,
        step: 0,
        stepCount: 5,
        children: [
          AppTextField(
            label: context.s.familyNameLabel,
            controller: _familyName,
            hint: context.s.familyNameHint,
            textCapitalization: TextCapitalization.words,
            maxLength: 60,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: context.s.nicknameLabel,
            controller: _ownerName,
            hint: context.s.nicknameHintOwner,
            textCapitalization: TextCapitalization.words,
            maxLength: 40,
            onSubmitted: (_) => _createFamily(),
          ),
          const SizedBox(height: 24),
          AppButton(label: _busy ? context.s.saving : context.s.continueLabel, onPressed: _busy ? null : _createFamily),
          FormError(error),
          const SizedBox(height: 32),
          AppButton(
            label: context.s.onbHaveInvite,
            variant: AppButtonVariant.secondary,
            onPressed: _busy ? null : () => context.go('/join'),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: context.s.signOut,
            variant: AppButtonVariant.secondary,
            onPressed: _busy ? null : _session.signOut,
          ),
        ],
      ),
      _Step.children => OnboardingScaffold(
        title: context.s.onbAddChildTitle,
        subtitle: context.s.onbAddChildSubtitle,
        step: 1,
        stepCount: 5,
        children: [
          for (final child in _children) ...[
            ListRowPill(
              title: child.name,
              subtitle: child.birthDate == null ? context.s.birthDateEmpty : formatDateShort(child.birthDate!),
              leading: MemberAvatar(name: child.name, avatarKey: child.avatar),
            ),
            const SizedBox(height: 10),
          ],
          if (_children.isNotEmpty) const SizedBox(height: 14),
          ChildForm(
            submitLabel: _children.isEmpty ? context.s.addChild : context.s.addAnotherChild,
            onSubmit: _addChild,
          ),
          const SizedBox(height: 28),
          AppButton(label: context.s.continueLabel, onPressed: _children.isEmpty ? null : () => _go(_Step.template)),
        ],
      ),
      _Step.template => OnboardingScaffold(
        title: context.s.onbTemplateTitle,
        subtitle: context.s.onbTemplateSubtitle,
        step: 2,
        stepCount: 5,
        onBack: _busy ? null : () => _go(_Step.children),
        children: [
          for (final band in AgeBand.values) ...[
            SelectableCard(
              title: band.label,
              subtitle: context.s.templateSummary(formatPoints(band.dailyPoints), formatPoints(band.screenTimePrice)),
              badge: band == _suggestedBand ? context.s.suggested : null,
              selected: band == (_band ?? _suggestedBand),
              onTap: _busy ? null : () => setState(() => _band = band),
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 10),
          AppButton(
            label: _busy ? context.s.preparing : context.s.useTemplate,
            onPressed: _busy ? null : _applyTemplate,
          ),
          const SizedBox(height: 12),
          AppButton(
            label: context.s.skipTemplate,
            variant: AppButtonVariant.secondary,
            onPressed: _busy ? null : _openConnect,
          ),
          FormError(error),
        ],
      ),
      _Step.review => OnboardingScaffold(
        title: context.s.onbReviewTitle,
        subtitle: context.s.onbReviewSubtitle,
        step: 3,
        stepCount: 5,
        children: [
          Text(context.s.tasks, style: AppText.titleLg),
          const SizedBox(height: 10),
          for (final task in _tasks) ...[
            ListRowPill(
              title: task.title,
              subtitle: task.scheduleLabel,
              trailing: _PointsTag('+${formatPoints(task.points)}'),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 18),
          Text(context.s.rewards, style: AppText.titleLg),
          const SizedBox(height: 10),
          for (final reward in _rewards) ...[
            ListRowPill(
              title: reward.title,
              subtitle: reward.type == RewardType.goal ? context.s.rewardGoalSaved : context.s.rewardInstant,
              trailing: _PointsTag(formatPoints(reward.cost)),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 18),
          AppButton(
            label: _busy ? context.s.preparing : context.s.continueLabel,
            onPressed: _busy ? null : _openConnect,
          ),
          FormError(error),
        ],
      ),
      _Step.connect => OnboardingScaffold(
        title: context.s.onbConnectTitle,
        subtitle: context.s.onbConnectSubtitle,
        step: 4,
        stepCount: 5,
        children: [
          for (final child in _children) ...[
            InviteCodeCard(code: _codes[child.id]!, forName: child.name),
            const SizedBox(height: AppSpace.cardGap),
          ],
          Text(context.s.onbConnectNote, style: AppText.bodySm.copyWith(color: AppColors.inkMuted)),
          const SizedBox(height: 24),
          AppButton(label: context.s.done, onPressed: _busy ? null : () => _run(_session.finishFlow)),
          FormError(error),
        ],
      ),
    };
  }
}

/// Pesan validasi form yang ditampilkan apa adanya.
class _FormMessage extends AppException {
  const _FormMessage(this._text) : super('form');

  final String _text;

  @override
  String get message => _text;
}

class _PointsTag extends StatelessWidget {
  const _PointsTag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Text(text, style: AppText.titleMd),
    );
  }
}
