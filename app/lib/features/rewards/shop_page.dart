import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/analytics.dart';
import '../../core/format.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/list_row_pill.dart';
import '../../core/widgets/pill_chip.dart';
import '../../core/widgets/status_stamp.dart';
import '../../data/app_exception.dart';
import '../../data/reward_models.dart';
import '../../data/wallet_models.dart';
import '../onboarding/onboarding_scaffold.dart';
import '../shell/reload_on_changes.dart';
import '../shell/session.dart';
import '../wallet/wallet_views.dart';
import 'goal_card.dart';
import '../../core/widgets/motion.dart';
import '../../l10n/strings.dart';

typedef _ShopData = ({WalletSummary wallet, List<Reward> rewards, GoalProgress? goal, List<Redemption> mine});

/// Toko hadiah anak (PRD layar A-5–A-8, Flow 4 & 5): saldo, penukaran yang berjalan + timer sesi,
/// goal, dan daftar hadiah dengan tanda "cukup" / "kurang X poin".
class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> with ReloadOnChanges {
  Future<_ShopData>? _data;

  Future<_ShopData> _load() async {
    final session = SessionScope.read(context);
    final me = session.activeMember!;
    final repo = session.repository;
    return (
      wallet: await repo.wallet(me),
      rewards: await repo.listRewards(me.familyId),
      goal: await repo.activeGoal(me),
      mine: await repo.memberRedemptions(me.id),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _data ??= _load();
    listenForChanges();
  }

  @override
  void reload() => setState(() {
    _data = _load();
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<_ShopData>(
        future: _data,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final now = DateTime.now();
          final open = data?.mine.where((r) => r.status.isOpen).toList() ?? const <Redemption>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpace.screenX, 16, AppSpace.screenX, 32),
            children: staggered([
              Text(context.s.rewardShop, style: AppText.displayLg),
              const SizedBox(height: 16),
              if (snapshot.hasError)
                Text(
                  snapshot.error is AppException
                      ? (snapshot.error! as AppException).message
                      : context.s.loadRewardsFailed,
                  style: AppText.body.copyWith(color: AppColors.tangerineDeep),
                ),
              BalanceView(data?.wallet),
              if (open.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(context.s.inProgressRedemptions, style: AppText.titleLg),
                const SizedBox(height: 10),
                for (final r in open) ...[
                  r.sessionActive(now) ? _SessionTimer(r, onEnded: reload) : _OpenRedemptionRow(r),
                  const SizedBox(height: 10),
                ],
              ],
              if (data != null) ...[
                const SizedBox(height: 24),
                GoalCard(
                  goal: data.goal,
                  onAction: data.goal == null || data.wallet.balance.available <= 0
                      ? null
                      : () => _showSaveSheet(context, data.wallet.balance.available),
                  actionLabel: context.s.setAsideForGoal,
                ),
                for (final type in RewardType.values)
                  if (data.rewards.any((r) => r.type == type)) ...[
                    const SizedBox(height: 24),
                    Text(
                      type == RewardType.instant ? context.s.instantRewards : context.s.goalRewards,
                      style: AppText.titleLg,
                    ),
                    const SizedBox(height: 10),
                    for (final reward in data.rewards.where((r) => r.type == type)) ...[
                      _RewardRow(reward: reward, data: data),
                      const SizedBox(height: 10),
                    ],
                  ],
              ],
            ]),
          );
        },
      ),
    );
  }

  Future<void> _showSaveSheet(BuildContext context, int available) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card))),
    builder: (_) => _SaveSheet(available: available),
  );
}

/// Poin yang bisa dipakai untuk hadiah ini: hadiah goal yang sedang dituju juga memakai tabungan goal.
int _spendable(Reward reward, _ShopData data) {
  final available = data.wallet.balance.available;
  final fromGoal = reward.type == RewardType.goal && data.goal?.reward.id == reward.id ? data.goal!.saved : 0;
  return fromGoal + (available > 0 ? available : 0);
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.reward, required this.data});

  final Reward reward;
  final _ShopData data;

  @override
  Widget build(BuildContext context) {
    final short = reward.cost - _spendable(reward, data);
    return ListRowPill(
      title: reward.title,
      subtitle: [
        context.s.pointsAmount(formatPoints(reward.cost)),
        if (reward.durationMinutes != null) context.s.minutesAmount(reward.durationMinutes!),
        short <= 0 ? context.s.enough : context.s.shortBy(formatPoints(short)),
      ].join(' · '),
      leading: CircleBadge(
        color: short <= 0 ? AppColors.pastelLime : AppColors.pastelLilac,
        icon: AppIcons.reward(reward.icon),
      ),
      onTap: () => _showConfirm(context, reward, data),
    );
  }
}

/// Konfirmasi tukar (A-6) atau jadikan goal (A-8).
Future<void> _showConfirm(BuildContext context, Reward reward, _ShopData data) async {
  final result = await showModalBottomSheet<StampStatus>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card))),
    builder: (_) => _ConfirmSheet(reward: reward, data: data),
  );
  if (result == null || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            StatusStamp(status: result, animate: true),
            const SizedBox(height: 24),
            Text(
              result == StampStatus.pending
                  ? context.s.requestSent
                  : (reward.isScreenTime ? context.s.screenTimeApproved : context.s.rewardYours),
              textAlign: TextAlign.center,
              style: AppText.titleMd,
            ),
            const SizedBox(height: 20),
            AppButton(label: context.s.ok, onPressed: () => Navigator.of(dialogContext).pop()),
          ],
        ),
      ),
    ),
  );
}

class _ConfirmSheet extends StatefulWidget {
  const _ConfirmSheet({required this.reward, required this.data});

  final Reward reward;
  final _ShopData data;

  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() action, StampStatus? result) async {
    final session = SessionScope.read(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      session.markDataChanged();
      if (mounted) Navigator.of(context).pop(result);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.read(context);
    final me = session.activeMember!;
    final reward = widget.reward;
    final spendable = _spendable(reward, widget.data);
    final short = reward.cost - spendable;
    final isCurrentGoal = widget.data.goal?.reward.id == reward.id;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.screenX, 24, AppSpace.screenX, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox.square(
                dimension: 48,
                child: CircleBadge(color: AppColors.pastelLilac, icon: AppIcons.reward(reward.icon)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(reward.title, style: AppText.titleLg)),
            ],
          ),
          const SizedBox(height: 16),
          Text(context.s.priceLabel(formatPoints(reward.cost)), style: AppText.titleMd),
          Text(
            short <= 0
                ? context.s.balanceAfter(formatPoints(spendable - reward.cost))
                : context.s.pointsShortMore(formatPoints(short)),
            style: AppText.body.copyWith(color: AppColors.inkMuted),
          ),
          if (reward.needsApproval)
            Text(context.s.parentWillApprove, style: AppText.body.copyWith(color: AppColors.inkMuted)),
          const SizedBox(height: 20),
          AppButton(
            label: _busy
                ? context.s.oneMoment
                : (short <= 0 ? context.s.redeemNow : context.s.shortPoints(formatPoints(short))),
            onPressed: _busy || short > 0
                ? null
                : () => _run(() async {
                    await session.repository.redeemReward(member: me, rewardId: reward.id);
                    session.track(AnalyticsEvent.rewardRedeemed, {'type': reward.type.name});
                    // Goal tercapai = hadiah goal berhasil ditukar
                    if (reward.type == RewardType.goal) session.track(AnalyticsEvent.goalAchieved);
                  }, reward.needsApproval ? StampStatus.pending : StampStatus.approved),
          ),
          if (reward.type == RewardType.goal && !isCurrentGoal) ...[
            const SizedBox(height: 12),
            AppButton(
              label: context.s.makeGoal,
              icon: AppIcons.flag,
              variant: AppButtonVariant.secondary,
              onPressed: _busy
                  ? null
                  : () => _run(() => session.repository.setGoal(member: me, rewardId: reward.id), null),
            ),
          ],
          FormError(_error),
        ],
      ),
    );
  }
}

class _OpenRedemptionRow extends StatelessWidget {
  const _OpenRedemptionRow(this.redemption);

  final Redemption redemption;

  @override
  Widget build(BuildContext context) {
    final requested = redemption.status == RedemptionStatus.requested;
    return ListRowPill(
      title: redemption.rewardTitle,
      subtitle: requested ? context.s.waitingParentHeld(formatPoints(redemption.cost)) : context.s.approvedWaitGiven,
      leading: CircleBadge(color: AppColors.pastelButter, icon: AppIcons.reward(redemption.rewardIcon)),
      trailing: requested
          ? Padding(
              padding: const EdgeInsets.only(right: 4),
              child: AppButton(
                label: context.s.cancelAction,
                variant: AppButtonVariant.secondary,
                expand: false,
                onPressed: () async {
                  final session = SessionScope.read(context);
                  try {
                    await session.repository.cancelRedemption(redemption.id);
                    session.markDataChanged();
                  } on AppException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  }
                },
              ),
            )
          : null,
    );
  }
}

/// Timer sesi screen time (PRD H-06, layar A-7): hitung mundur, peringatan 5 menit terakhir.
class _SessionTimer extends StatefulWidget {
  const _SessionTimer(this.redemption, {required this.onEnded});

  final Redemption redemption;
  final VoidCallback onEnded;

  @override
  State<_SessionTimer> createState() => _SessionTimerState();
}

class _SessionTimerState extends State<_SessionTimer> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!DateTime.now().isBefore(widget.redemption.sessionEndsAt!)) {
        _ticker?.cancel();
        widget.onEnded();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.redemption.sessionEndsAt!.difference(DateTime.now());
    final safe = left.isNegative ? Duration.zero : left;
    final mm = safe.inMinutes.toString().padLeft(2, '0');
    final ss = (safe.inSeconds % 60).toString().padLeft(2, '0');
    final end = widget.redemption.sessionEndsAt!;
    final soon = safe <= const Duration(minutes: 5);
    return Container(
      padding: const EdgeInsets.all(AppSpace.cardPadding),
      decoration: BoxDecoration(
        color: soon ? AppColors.tangerine : AppColors.matcha,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Semantics(
        container: true,
        liveRegion: soon,
        label: context.s.timerSemantic(widget.redemption.rewardTitle, safe.inMinutes),
        child: ExcludeSemantics(
          child: Row(
            children: [
              const Icon(AppIcons.timer, size: 32, color: AppColors.ink),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.redemption.rewardTitle, style: AppText.titleMd),
                    Text(
                      soon
                          ? context.s.fiveMinutesLeft
                          : context.s.untilTime(
                              '${end.hour.toString().padLeft(2, '0')}.${end.minute.toString().padLeft(2, '0')}',
                            ),
                      style: AppText.body,
                    ),
                  ],
                ),
              ),
              Text('$mm:$ss', style: AppText.displayLg),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sisihkan poin ke tabungan goal (G-03), supaya tidak terpakai untuk screen time.
class _SaveSheet extends StatefulWidget {
  const _SaveSheet({required this.available});

  final int available;

  @override
  State<_SaveSheet> createState() => _SaveSheetState();
}

class _SaveSheetState extends State<_SaveSheet> {
  int? _amount;
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    final session = SessionScope.read(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await session.repository.saveToGoal(member: session.activeMember!, amount: _amount!);
      session.markDataChanged();
      if (mounted) Navigator.of(context).pop();
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = {
      for (final a in const [10, 50, 100])
        if (a < widget.available) a,
      widget.available,
    }.toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.screenX, 24, AppSpace.screenX, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.s.setAsideTitle, style: AppText.titleLg),
          const SizedBox(height: 8),
          Text(context.s.setAsideNote, style: AppText.body.copyWith(color: AppColors.inkMuted)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in options)
                PillChip(
                  label: a == widget.available ? context.s.allAmount(formatPoints(a)) : formatPoints(a),
                  selected: _amount == a,
                  onTap: () => setState(() => _amount = a),
                ),
            ],
          ),
          const SizedBox(height: 20),
          AppButton(
            label: _busy ? context.s.saving : context.s.setAside,
            onPressed: _busy || _amount == null ? null : _save,
          ),
          FormError(_error),
        ],
      ),
    );
  }
}
