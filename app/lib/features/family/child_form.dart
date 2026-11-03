import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/member_avatar.dart';
import '../../data/app_exception.dart';

typedef ChildSubmit = Future<void> Function(String name, String avatar, DateTime? birthDate);

/// Form tambah anak (PRD M-01): nama, avatar, tanggal lahir (opsional).
/// Dipakai di onboarding dan tab Keluarga. Form dikosongkan setelah berhasil.
class ChildForm extends StatefulWidget {
  const ChildForm({super.key, required this.onSubmit, this.submitLabel = 'Tambah anak'});

  final ChildSubmit onSubmit;
  final String submitLabel;

  @override
  State<ChildForm> createState() => _ChildFormState();
}

class _ChildFormState extends State<ChildForm> {
  final _name = TextEditingController();
  String _avatar = 'lime';
  DateTime? _birthDate;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 10, now.month, now.day),
      firstDate: DateTime(now.year - 18),
      lastDate: now,
      helpText: 'Tanggal lahir',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Isi nama panggilan anak dulu ya.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(name, _avatar, _birthDate);
      if (!mounted) return;
      _name.clear();
      setState(() => _birthDate = null);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'Nama panggilan anak',
          controller: _name,
          hint: 'mis. Raka',
          textCapitalization: TextCapitalization.words,
          maxLength: 40,
          errorText: _error,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Text('Warna avatar', style: AppText.label),
        const SizedBox(height: 8),
        AvatarPicker(name: _name.text, selected: _avatar, onChanged: (key) => setState(() => _avatar = key)),
        const SizedBox(height: 16),
        Text('Tanggal lahir (opsional)', style: AppText.label),
        const SizedBox(height: 4),
        Text(
          'Dipakai untuk menyarankan template poin sesuai usia.',
          style: AppText.bodySm.copyWith(color: AppColors.inkMuted),
        ),
        const SizedBox(height: 8),
        AppButton(
          label: _birthDate == null ? 'Pilih tanggal' : formatDateShort(_birthDate!),
          variant: AppButtonVariant.secondary,
          expand: false,
          onPressed: _pickDate,
        ),
        const SizedBox(height: 20),
        AppButton(
          label: _busy ? 'Menyimpan...' : widget.submitLabel,
          variant: AppButtonVariant.secondary,
          onPressed: _busy ? null : _submit,
        ),
      ],
    );
  }
}
