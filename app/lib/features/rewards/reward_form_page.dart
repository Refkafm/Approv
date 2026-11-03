import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/pill_chip.dart';
import '../../core/widgets/pressable.dart';
import '../../data/app_exception.dart';
import '../../data/reward_models.dart';
import '../onboarding/onboarding_scaffold.dart';
import '../shell/session.dart';

/// Buat / ubah hadiah (PRD layar O-9, H-01, H-02, H-04, aturan bisnis 6).
class RewardFormPage extends StatefulWidget {
  const RewardFormPage({super.key, this.reward, this.isEdit = false});

  final Reward? reward;
  final bool isEdit;

  @override
  State<RewardFormPage> createState() => _RewardFormPageState();
}

class _RewardFormPageState extends State<RewardFormPage> {
  late final Reward? _reward = widget.reward;
  late final _title = TextEditingController(text: _reward?.title);
  late final _cost = TextEditingController(text: _reward?.cost.toString());
  late final _duration = TextEditingController(text: _reward?.durationMinutes?.toString());
  late final _stock = TextEditingController(text: _reward?.stock?.toString());
  late String _icon = _reward?.icon ?? 'gift';
  late RewardType _type = _reward?.type ?? RewardType.instant;
  late int? _maxPerDay = _reward?.maxPerDay;
  late bool _needsApproval = _reward?.needsApproval ?? true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _cost.dispose();
    _duration.dispose();
    _stock.dispose();
    super.dispose();
  }

  RewardInput get _input => RewardInput(
    title: _title.text,
    cost: int.tryParse(_cost.text) ?? 0,
    type: _type,
    icon: _icon,
    durationMinutes: _type == RewardType.instant ? int.tryParse(_duration.text) : null,
    maxPerDay: _maxPerDay,
    stock: int.tryParse(_stock.text),
    needsApproval: _needsApproval,
  );

  Future<void> _run(Future<void> Function() action) async {
    final session = SessionScope.read(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      session.markDataChanged();
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
    final session = SessionScope.read(context);
    final repo = session.repository;
    final reward = _reward;
    _run(() async {
      if (reward == null) {
        await repo.createReward(session.activeMember!.familyId, input);
        return;
      }
      await repo.updateReward(reward.id, input);
      if (input.cost != reward.cost && await repo.updateRewardPrice(reward.id, input.cost) && mounted) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppColors.paper,
            title: Text('Harga naik 7 hari lagi', style: AppText.titleLg),
            content: Text(
              'Hadiah ini sedang ditabung anak sebagai goal. Supaya adil, harga baru '
              '${formatPoints(input.cost)} poin berlaku 7 hari lagi dan anak diberi tahu.',
              style: AppText.body,
            ),
            actions: [AppButton(label: 'Oke', onPressed: () => Navigator.of(dialogContext).pop())],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reward = _reward;
    if (widget.isEdit && reward == null) {
      return OnboardingScaffold(title: 'Hadiah tidak ditemukan', onBack: () => context.pop(), children: const []);
    }
    return OnboardingScaffold(
      title: reward == null ? 'Hadiah baru' : 'Ubah hadiah',
      onBack: _busy ? null : () => context.pop(),
      children: [
        AppTextField(
          label: 'Nama hadiah',
          controller: _title,
          hint: 'mis. 30 menit main game',
          textCapitalization: TextCapitalization.sentences,
          maxLength: 60,
        ),
        const SizedBox(height: 20),
        Text('Ikon', style: AppText.label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final MapEntry(key: key, value: icon) in AppIcons.rewards.entries)
              Pressable(
                semanticLabel: 'Ikon $key',
                selected: key == _icon,
                onTap: () => setState(() => _icon = key),
                builder: (context, pressed) => Container(
                  width: TapTarget.parent,
                  height: TapTarget.parent,
                  decoration: BoxDecoration(
                    color: key == _icon ? AppColors.sunflower : AppColors.surface,
                    shape: BoxShape.circle,
                    border: key == _icon
                        ? Border.all(color: AppColors.ink, width: AppStroke.width)
                        : Border.all(color: AppColors.lineSoft, width: AppStroke.softWidth),
                  ),
                  child: Icon(icon, size: 22, color: key == _icon ? AppColors.ink : AppColors.inkMuted),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Harga (poin)',
          controller: _cost,
          hint: '100',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 8,
        ),
        if (reward?.pendingCost != null && reward?.costEffectiveAt != null)
          _Hint(
            'Kenaikan ke ${formatPoints(reward!.pendingCost!)} poin berlaku '
            '${formatDateShort(reward.costEffectiveAt!)}.',
          ),
        if (reward == null) ...[
          const SizedBox(height: 24),
          Text('Jenis', style: AppText.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final t in RewardType.values)
                PillChip(
                  label: t == RewardType.instant ? 'Instan (screen time & hal kecil)' : 'Goal (ditabung)',
                  selected: _type == t,
                  onTap: () => setState(() => _type = t),
                ),
            ],
          ),
          _Hint(
            _type == RewardType.instant
                ? 'Anak menukar kapan saja poinnya cukup, sesuai batas harian.'
                : 'Anak menabung dan melihat progressnya sampai poinnya cukup.',
          ),
        ],
        if (_type == RewardType.instant) ...[
          const SizedBox(height: 20),
          AppTextField(
            label: 'Durasi screen time (menit, opsional)',
            controller: _duration,
            hint: '30',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 4,
          ),
          const _Hint('Bila diisi, timer sesi berjalan di HP anak setelah disetujui.'),
          const SizedBox(height: 20),
          Text('Maks per hari', style: AppText.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final n in const [null, 1, 2, 3])
                PillChip(
                  label: n == null ? 'Tanpa batas' : '$n×',
                  selected: _maxPerDay == n,
                  onTap: () => setState(() => _maxPerDay = n),
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        AppTextField(
          label: 'Stok (opsional)',
          controller: _stock,
          hint: 'Kosongkan bila tanpa batas',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 4,
        ),
        const SizedBox(height: 12),
        MergeSemantics(
          child: Row(
            children: [
              Expanded(child: Text('Perlu persetujuan orang tua', style: AppText.body)),
              Switch(
                value: _needsApproval,
                onChanged: (v) => setState(() => _needsApproval = v),
                thumbColor: const WidgetStatePropertyAll(AppColors.ink),
                trackColor: WidgetStateProperty.resolveWith(
                  (s) => s.contains(WidgetState.selected) ? AppColors.sunflower : AppColors.surface,
                ),
                trackOutlineColor: const WidgetStatePropertyAll(AppColors.ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        AppButton(label: _busy ? 'Menyimpan...' : 'Simpan hadiah', onPressed: _busy ? null : _save),
        FormError(_error),
        if (reward != null) ...[
          const SizedBox(height: 16),
          AppButton(
            label: reward.isArchived ? 'Aktifkan lagi' : 'Arsipkan',
            icon: reward.isArchived ? AppIcons.arrowCounterClockwise : AppIcons.archive,
            variant: AppButtonVariant.secondary,
            onPressed: _busy
                ? null
                : () => _run(
                    () =>
                        SessionScope.read(context).repository
                            .setRewardArchived(reward.id, archived: !reward.isArchived),
                  ),
          ),
        ],
      ],
    );
  }
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
