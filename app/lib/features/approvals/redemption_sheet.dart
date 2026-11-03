import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_stamp.dart';
import '../../data/app_exception.dart';
import '../../data/reward_models.dart';
import '../onboarding/onboarding_scaffold.dart';
import '../shell/session.dart';

/// Proses penukaran (PRD H-04, H-05, Flow 4 & 5): setujui, tolak dengan alasan (poin kembali),
/// atau tandai "sudah diberikan".
Future<void> showRedemptionSheet(BuildContext context, Redemption redemption) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppColors.paper,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card))),
  builder: (_) => _RedemptionSheet(redemption),
);

class _RedemptionSheet extends StatefulWidget {
  const _RedemptionSheet(this.redemption);

  final Redemption redemption;

  @override
  State<_RedemptionSheet> createState() => _RedemptionSheetState();
}

class _RedemptionSheetState extends State<_RedemptionSheet> {
  final _reason = TextEditingController();
  bool _busy = false;
  String? _error;
  StampStatus? _result;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _review(RedemptionAction action) async {
    if (action == RedemptionAction.reject && _reason.text.trim().isEmpty) {
      setState(() => _error = 'Tulis alasan menolak, ${widget.redemption.memberName} akan melihatnya.');
      return;
    }
    final session = SessionScope.read(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await session.repository.reviewRedemption(widget.redemption.id, action, reason: _reason.text.trim());
      session.markDataChanged();
      if (mounted) {
        setState(
          () => _result = switch (action) {
            RedemptionAction.approve => StampStatus.approved,
            RedemptionAction.reject => StampStatus.rejected,
            RedemptionAction.fulfill => StampStatus.fulfilled,
          },
        );
      }
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.redemption;
    final requested = r.status == RedemptionStatus.requested;
    final result = _result;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.screenX,
        24,
        AppSpace.screenX,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.rewardTitle, style: AppText.titleLg),
            const SizedBox(height: 4),
            Text(
              '${r.memberName} · ${formatPoints(r.cost)} poin · ${formatReportTime(r.createdAt).toLowerCase()}',
              style: AppText.body.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 16),
            if (result != null) ...[
              Center(child: StatusStamp(status: result, animate: true)),
              const SizedBox(height: 16),
              if (result == StampStatus.approved && r.durationMinutes != null)
                Text(
                  'Buka akses untuk ${r.memberName} secara manual (Screen Time / Family Link) selama '
                  '${r.durationMinutes} menit. Timer sudah berjalan di HP-nya.',
                  style: AppText.body,
                ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Tutup',
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ] else if (requested) ...[
              Text(
                r.durationMinutes != null
                    ? 'Setelah disetujui, timer ${r.durationMinutes} menit berjalan di HP ${r.memberName}.'
                    : 'Poin sudah ditahan. Kalau ditolak, poin kembali penuh.',
                style: AppText.body,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Alasan (wajib bila menolak)',
                controller: _reason,
                hint: 'mis. Besok saja, sudah malam',
                textCapitalization: TextCapitalization.sentences,
                maxLength: 200,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: _busy ? 'Menyimpan...' : 'Setujui',
                onPressed: _busy ? null : () => _review(RedemptionAction.approve),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Tolak',
                variant: AppButtonVariant.destructive,
                onPressed: _busy ? null : () => _review(RedemptionAction.reject),
              ),
            ] else ...[
              Text('Sudah disetujui. Tandai bila hadiahnya sudah diberikan.', style: AppText.body),
              const SizedBox(height: 16),
              AppButton(
                label: _busy ? 'Menyimpan...' : 'Sudah diberikan',
                onPressed: _busy ? null : () => _review(RedemptionAction.fulfill),
              ),
            ],
            FormError(_error),
          ],
        ),
      ),
    );
  }
}
