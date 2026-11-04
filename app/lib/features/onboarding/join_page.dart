import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/app_exception.dart';
import '../../data/models.dart';
import '../shell/session.dart';
import 'onboarding_scaffold.dart';
import '../../l10n/strings.dart';

/// Gabung keluarga dengan kode undangan (PRD A-04, M-02, Flow 2, layar A-1).
/// Anak: sesi anonim dibuat otomatis, lalu buat PIN (opsional). Pengasuh: wajib sudah login.
class JoinPage extends StatefulWidget {
  const JoinPage({super.key});

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _pin = TextEditingController();
  Member? _joined;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final session = SessionScope.read(context);
    final code = _code.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = context.s.joinCodeLength);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    session.beginFlow();
    try {
      if (session.user == null) await session.repository.signInAnonymously();
      final member = await session.repository.joinFamily(code: code, name: _name.text);
      if (member.role == MemberRole.member) {
        session.track(AnalyticsEvent.childJoined);
        if (mounted) setState(() => _joined = member);
      } else {
        await session.finishFlow();
      }
    } on AppException catch (e) {
      await session.finishFlow();
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _savePin() async {
    final session = SessionScope.read(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await session.repository.setPin(memberId: _joined!.id, pin: _pin.text);
      await session.finishFlow();
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final joined = _joined;

    if (joined != null) {
      return OnboardingScaffold(
        title: context.s.joinHello(joined.name),
        subtitle: context.s.pinSubtitle,
        step: 1,
        stepCount: 2,
        children: [
          AppTextField(
            label: context.s.pinLabel,
            controller: _pin,
            hint: '••••',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 4,
            obscureText: true,
            large: true,
            autofocus: true,
            onSubmitted: (_) => _savePin(),
          ),
          const SizedBox(height: 20),
          AppButton(label: _busy ? context.s.saving : context.s.savePin, onPressed: _busy ? null : _savePin),
          const SizedBox(height: 12),
          AppButton(
            label: context.s.skipForNow,
            variant: AppButtonVariant.secondary,
            onPressed: _busy ? null : session.finishFlow,
          ),
          FormError(_error),
        ],
      );
    }

    final isAdult = session.user != null && !session.user!.isAnonymous;
    return OnboardingScaffold(
      title: context.s.joinTitle,
      subtitle: isAdult ? context.s.joinSubtitleAdult : context.s.joinSubtitleChild,
      showLanguage: true,
      step: isAdult ? null : 0,
      stepCount: isAdult ? null : 2,
      onBack: () => context.go(isAdult ? '/onboarding' : '/'),
      children: [
        AppTextField(
          label: context.s.inviteCodeLabel,
          controller: _code,
          hint: 'K7M2QX',
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
            TextInputFormatter.withFunction((_, value) => value.copyWith(text: value.text.toUpperCase())),
          ],
          maxLength: 6,
          large: true,
          autofocus: true,
          textInputAction: isAdult ? TextInputAction.next : TextInputAction.done,
          onSubmitted: isAdult ? null : (_) => _join(),
        ),
        if (isAdult) ...[
          const SizedBox(height: 16),
          AppTextField(
            label: context.s.nicknameLabel,
            controller: _name,
            hint: context.s.nicknameHintAdult,
            textCapitalization: TextCapitalization.words,
            maxLength: 40,
          ),
        ],
        const SizedBox(height: 20),
        AppButton(label: _busy ? context.s.checking : context.s.joinButton, onPressed: _busy ? null : _join),
        FormError(_error),
      ],
    );
  }
}
