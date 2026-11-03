import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/pill_chip.dart';
import '../../data/app_exception.dart';
import '../../data/settings_models.dart';
import '../onboarding/onboarding_scaffold.dart';
import '../shell/session.dart';

/// Pengaturan keluarga (PRD R-02, layar O-14): nama, zona waktu, bahasa, jam tidur notifikasi,
/// aturan penalti & bonus streak.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _name = TextEditingController();
  FamilySettings? _settings;
  bool _busy = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_settings != null || _busy) return;
    _busy = true;
    final session = SessionScope.read(context);
    session.repository.familySettings(session.activeMember!.familyId).then((s) {
      if (!mounted) return;
      setState(() {
        _settings = s;
        _name.text = s.name;
        _busy = false;
      });
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _update(FamilySettings Function(FamilySettings s) change) => setState(() => _settings = change(_settings!));

  Future<void> _pickTime({required bool start}) async {
    final s = _settings!;
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? s.quietStart : s.quietEnd,
      helpText: start ? 'Jam tidur mulai' : 'Jam tidur selesai',
    );
    if (picked != null) _update((s) => start ? s.copyWith(quietStart: picked) : s.copyWith(quietEnd: picked));
  }

  Future<void> _save() async {
    final session = SessionScope.read(context);
    final settings = _settings!.copyWith(name: _name.text);
    final invalid = settings.validate();
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await session.repository.updateFamilySettings(session.activeMember!.familyId, settings);
      session.markDataChanged();
      if (mounted) context.pop();
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _settings;
    if (s == null) {
      return OnboardingScaffold(title: 'Pengaturan', onBack: () => context.pop(), children: const []);
    }
    return OnboardingScaffold(
      title: 'Pengaturan',
      onBack: _busy ? null : () => context.pop(),
      children: [
        AppTextField(label: 'Nama keluarga', controller: _name, maxLength: 60),
        const SizedBox(height: 24),
        const _Label('Zona waktu'),
        Wrap(
          spacing: 8,
          children: [
            for (final MapEntry(key: tz, value: label) in FamilySettings.timezones.entries)
              PillChip(
                label: label,
                selected: s.timezone == tz,
                onTap: () => _update((s) => s.copyWith(timezone: tz)),
              ),
          ],
        ),
        const _Hint('Menentukan kapan tugas harian dan batas harian berganti hari.'),
        const SizedBox(height: 24),
        const _Label('Bahasa'),
        Wrap(
          spacing: 8,
          children: [
            PillChip(
              label: 'Indonesia',
              selected: s.locale == 'id',
              onTap: () => _update((s) => s.copyWith(locale: 'id')),
            ),
            PillChip(
              label: 'English',
              selected: s.locale == 'en',
              onTap: () => _update((s) => s.copyWith(locale: 'en')),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _Label('Jam tidur anak'),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Mulai ${FamilySettings.formatTime(s.quietStart)}',
                variant: AppButtonVariant.secondary,
                onPressed: () => _pickTime(start: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: 'Selesai ${FamilySettings.formatTime(s.quietEnd)}',
                variant: AppButtonVariant.secondary,
                onPressed: () => _pickTime(start: false),
              ),
            ),
          ],
        ),
        const _Hint('Notifikasi untuk anak di jam ini ditahan dan dikirim setelah jam tidur selesai.'),
        const SizedBox(height: 24),
        const _Label('Bonus streak 7 hari'),
        Wrap(
          spacing: 8,
          children: [
            for (final pct in const [0, 5, 10, 15, 20])
              PillChip(
                label: pct == 0 ? 'Tidak ada' : '$pct%',
                selected: s.streakBonusPct == pct,
                onTap: () => _update((s) => s.copyWith(streakBonusPct: pct)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        MergeSemantics(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Penalti boleh melebihi saldo', style: AppText.body),
                    Text(
                      'Saldo anak bisa jadi minus (utang poin).',
                      style: AppText.bodySm.copyWith(color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ),
              Switch(
                value: s.allowNegativePenalty,
                onChanged: (v) => _update((s) => s.copyWith(allowNegativePenalty: v)),
                thumbColor: const WidgetStatePropertyAll(AppColors.ink),
                trackColor: WidgetStateProperty.resolveWith(
                  (st) => st.contains(WidgetState.selected) ? AppColors.sunflower : AppColors.surface,
                ),
                trackOutlineColor: const WidgetStatePropertyAll(AppColors.ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        AppButton(label: _busy ? 'Menyimpan...' : 'Simpan', onPressed: _busy ? null : _save),
        FormError(_error),
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
