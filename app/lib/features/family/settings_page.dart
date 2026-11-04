import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/list_row_pill.dart';
import '../../core/widgets/pill_chip.dart';
import '../../data/app_exception.dart';
import '../../data/models.dart';
import '../../data/settings_models.dart';
import '../onboarding/onboarding_scaffold.dart';
import '../shell/session.dart';
import '../../l10n/strings.dart';

/// Pengaturan (PRD R-02, layar O-14): akun yang sedang masuk, pengaturan keluarga (nama, zona waktu,
/// bahasa, jam tidur notifikasi, aturan penalti & bonus streak), dan tombol keluar.
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
      helpText: start ? context.s.quietStartHelp : context.s.quietEndHelp,
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
      // Tutup dulu: ganti bahasa membangun ulang app dan router
      if (mounted) context.pop();
      await session.setLanguage(settings.locale);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final s = _settings;
    if (s == null) {
      return OnboardingScaffold(title: context.s.settings, onBack: () => context.pop(), children: const []);
    }
    return OnboardingScaffold(
      title: context.s.settings,
      onBack: _busy ? null : () => context.pop(),
      children: [
        Text(context.s.accountLabel, style: AppText.titleLg),
        const SizedBox(height: 10),
        _AccountRow(user: session.user),
        const SizedBox(height: 32),
        Text(context.s.navFamily, style: AppText.titleLg),
        const SizedBox(height: 14),
        AppTextField(label: context.s.familyNameLabel, controller: _name, maxLength: 60),
        const SizedBox(height: 24),
        _Label(context.s.timezoneLabel),
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
        _Hint(context.s.timezoneHint),
        const SizedBox(height: 24),
        _Label(context.s.languageLabel),
        Wrap(
          spacing: 8,
          children: [
            PillChip(
              label: 'Bahasa Indonesia',
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
        _Hint(context.s.languageHint),
        const SizedBox(height: 24),
        _Label(context.s.quietHoursLabel),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: context.s.startsAt(FamilySettings.formatTime(s.quietStart)),
                variant: AppButtonVariant.secondary,
                onPressed: () => _pickTime(start: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: context.s.endsAt(FamilySettings.formatTime(s.quietEnd)),
                variant: AppButtonVariant.secondary,
                onPressed: () => _pickTime(start: false),
              ),
            ),
          ],
        ),
        _Hint(context.s.quietHoursHint),
        const SizedBox(height: 24),
        _Label(context.s.streakBonusLabel),
        Wrap(
          spacing: 8,
          children: [
            for (final pct in const [0, 5, 10, 15, 20])
              PillChip(
                label: pct == 0 ? context.s.none : '$pct%',
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
                    Text(context.s.allowNegativeLabel, style: AppText.body),
                    Text(context.s.allowNegativeHint, style: AppText.bodySm.copyWith(color: AppColors.inkMuted)),
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
        AppButton(label: _busy ? context.s.saving : context.s.save, onPressed: _busy ? null : _save),
        FormError(_error),
        const SizedBox(height: 40),
        AppButton(
          label: context.s.signOut,
          variant: AppButtonVariant.destructive,
          icon: AppIcons.signOut,
          onPressed: _busy ? null : session.signOut,
        ),
      ],
    );
  }
}

/// Email akun yang sedang masuk dan cara masuknya.
class _AccountRow extends StatefulWidget {
  const _AccountRow({required this.user});

  final AuthUser? user;

  @override
  State<_AccountRow> createState() => _AccountRowState();
}

/// Email + cara masuk; akun email bisa dihubungkan ke Google agar keluarga yang sama terbuka lewat Google.
class _AccountRowState extends State<_AccountRow> {
  bool _busy = false;
  String? _error;

  Future<void> _linkGoogle() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await SessionScope.read(context).repository.linkGoogle();
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final google = user?.provider == 'google';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListRowPill(
          title: user?.email ?? '-',
          subtitle: google
              ? context.s.signedInWithGoogle
              : (user?.hasGoogle ?? false)
              ? context.s.googleLinked
              : context.s.signedInWithEmail,
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ink, width: AppStroke.width),
            ),
            child: Icon(google ? AppIcons.googleLogo : AppIcons.envelope, size: 20, color: AppColors.ink),
          ),
        ),
        if (user != null && !user.hasGoogle) ...[
          const SizedBox(height: 12),
          AppButton(
            label: _busy ? context.s.saving : context.s.linkGoogle,
            icon: AppIcons.googleLogo,
            variant: AppButtonVariant.secondary,
            onPressed: _busy ? null : _linkGoogle,
          ),
          _Hint(context.s.linkGoogleHint),
          FormError(_error),
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
