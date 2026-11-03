import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/pill_chip.dart';
import '../../data/app_exception.dart';
import '../../data/models.dart';
import '../onboarding/onboarding_scaffold.dart';
import '../shell/session.dart';

Future<bool?> _sheet(BuildContext context, Widget child) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppColors.paper,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card))),
  builder: (_) => child,
);

/// Bonus / penalti manual (PRD P-03, layar O-11, Flow 6): jumlah + alasan wajib yang terlihat anak.
Future<bool?> showAdjustSheet(
  BuildContext context, {
  required Member member,
  required bool penalty,
  required int available,
}) => _sheet(context, _AdjustSheet(member: member, penalty: penalty, available: available));

/// Batalkan tugas verifikasi otomatis (aturan bisnis 3): alasan wajib, saldo boleh jadi negatif.
Future<bool?> showReverseSheet(BuildContext context, {required String submissionId, required String taskTitle}) =>
    _sheet(context, _ReverseSheet(submissionId: submissionId, taskTitle: taskTitle));

class _AdjustSheet extends StatefulWidget {
  const _AdjustSheet({required this.member, required this.penalty, required this.available});

  final Member member;
  final bool penalty;
  final int available;

  @override
  State<_AdjustSheet> createState() => _AdjustSheetState();
}

class _AdjustSheetState extends State<_AdjustSheet> {
  static const _amounts = [10, 20, 50, 100];

  final _amount = TextEditingController();
  final _reason = TextEditingController();
  bool _busy = false;
  String? _error;

  List<String> get _quickReasons => widget.penalty
      ? const ['Tidak menepati janji', 'Main melebihi waktu', 'Lupa tugas penting']
      : const ['Bantu tanpa disuruh', 'Nilai bagus', 'Sikap baik hari ini'];

  int get _value => int.tryParse(_amount.text) ?? 0;

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_value <= 0) {
      setState(() => _error = 'Isi jumlah poin dulu.');
      return;
    }
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = 'Tulis alasannya. ${widget.member.name} akan melihat alasan ini.');
      return;
    }
    final session = SessionScope.read(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await session.repository.adjustPoints(
        memberId: widget.member.id,
        amount: widget.penalty ? -_value : _value,
        reason: _reason.text.trim(),
      );
      session.markDataChanged();
      if (mounted) Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.code == 'insufficient_points'
              ? 'Penalti melebihi saldo ${widget.member.name} (${formatPoints(widget.available)} poin).'
              : e.message,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final after = widget.available + (widget.penalty ? -_value : _value);
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
            Text(
              widget.penalty ? 'Penalti untuk ${widget.member.name}' : 'Bonus untuk ${widget.member.name}',
              style: AppText.titleLg,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Jumlah poin',
              controller: _amount,
              hint: '50',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in _amounts)
                  PillChip(
                    label: '${widget.penalty ? '−' : '+'}$a',
                    selected: _value == a,
                    onTap: () => setState(() => _amount.text = '$a'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Alasan',
              controller: _reason,
              hint: widget.penalty ? 'mis. Main game lewat dari jatah' : 'mis. Bantu cuci mobil tanpa disuruh',
              textCapitalization: TextCapitalization.sentences,
              maxLength: 200,
              maxLines: 2,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in _quickReasons)
                  PillChip(label: r, selected: _reason.text == r, onTap: () => setState(() => _reason.text = r)),
              ],
            ),
            if (_value > 0) ...[
              const SizedBox(height: 16),
              Text(
                'Saldo ${widget.member.name} jadi ${formatPoints(after)} poin.',
                style: AppText.body.copyWith(color: after < 0 ? AppColors.tangerineDeep : AppColors.inkMuted),
              ),
            ],
            const SizedBox(height: 20),
            AppButton(
              label: _busy ? 'Menyimpan...' : (widget.penalty ? 'Beri penalti' : 'Beri bonus'),
              variant: widget.penalty ? AppButtonVariant.destructive : AppButtonVariant.primary,
              onPressed: _busy ? null : _submit,
            ),
            FormError(_error),
          ],
        ),
      ),
    );
  }
}

class _ReverseSheet extends StatefulWidget {
  const _ReverseSheet({required this.submissionId, required this.taskTitle});

  final String submissionId;
  final String taskTitle;

  @override
  State<_ReverseSheet> createState() => _ReverseSheetState();
}

class _ReverseSheetState extends State<_ReverseSheet> {
  final _reason = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = 'Tulis alasannya supaya anak tahu kenapa dibatalkan.');
      return;
    }
    final session = SessionScope.read(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await session.repository.reverseAutoTask(submissionId: widget.submissionId, reason: _reason.text.trim());
      session.markDataChanged();
      if (mounted) Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Batalkan "${widget.taskTitle}"?', style: AppText.titleLg),
            const SizedBox(height: 8),
            Text(
              'Poin tugas ini ditarik kembali. Kalau poinnya sudah terpakai, saldo bisa jadi minus '
              '(utang poin) dan lunas otomatis dari poin berikutnya.',
              style: AppText.body.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Alasan',
              controller: _reason,
              hint: 'mis. Kasurnya belum dirapikan',
              textCapitalization: TextCapitalization.sentences,
              maxLength: 200,
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            AppButton(
              label: _busy ? 'Menyimpan...' : 'Batalkan tugas',
              variant: AppButtonVariant.destructive,
              onPressed: _busy ? null : _submit,
            ),
            FormError(_error),
          ],
        ),
      ),
    );
  }
}
