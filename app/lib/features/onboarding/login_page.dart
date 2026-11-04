import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/indonesia.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/app_exception.dart';
import '../../data/fake/fake_repository.dart';
import '../shell/session.dart';
import 'onboarding_scaffold.dart';
import '../../l10n/strings.dart';

/// Apple dan nomor HP + OTP disembunyikan sementara.
const _showAppleAndPhone = false;

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String _validEmail(TextEditingController controller) {
  final email = controller.text.trim();
  if (!_emailPattern.hasMatch(email)) throw const AppException('invalid_email');
  return email;
}

/// Status tombol & pesan galat bersama untuk halaman masuk dan daftar.
mixin _AuthForm<T extends StatefulWidget> on State<T> {
  bool busy = false;
  String? error;

  Future<void> run(Future<void> Function() action) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } on AppException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

/// Masuk orang tua (PRD A-01, layar O-1): email + kata sandi sebagai cara utama, atau Google.
/// Belum punya akun → [RegisterPage]. Setelah berhasil, router membawa ke onboarding atau beranda.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with _AuthForm {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  bool _phoneMode = false;
  String? _sentTo;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _signIn() => run(() async {
    final email = _validEmail(_email);
    if (_password.text.isEmpty) throw const AppException('invalid_login');
    await SessionScope.read(context).repository.signInWithEmail(email, _password.text);
  });

  Future<void> _sendOtp() => run(() async {
    final phone = normalizeIndonesianPhone(_phone.text);
    if (phone == null) throw const AppException('invalid_phone');
    await SessionScope.read(context).repository.sendPhoneOtp(phone);
    if (mounted) setState(() => _sentTo = phone);
  });

  Future<void> _verifyOtp() =>
      run(() => SessionScope.read(context).repository.verifyPhoneOtp(_sentTo!, _otp.text.trim()));

  @override
  Widget build(BuildContext context) {
    if (_phoneMode) return _buildPhone(context);
    final repo = SessionScope.of(context).repository;

    return OnboardingScaffold(
      title: context.s.signIn,
      subtitle: context.s.loginSubtitle,
      onBack: () => context.go('/'),
      children: [
        AppTextField(
          label: context.s.emailLabel,
          controller: _email,
          hint: context.s.emailHint,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: context.s.passwordLabel,
          controller: _password,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _signIn(),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: busy ? null : () => context.push('/login/forgot', extra: _email.text.trim()),
            style: TextButton.styleFrom(foregroundColor: AppColors.ink, minimumSize: const Size(48, 48)),
            child: Text(
              context.s.forgotPassword,
              style: AppText.bodySm.copyWith(fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AppButton(label: busy ? context.s.checking : context.s.signIn, onPressed: busy ? null : _signIn),
        FormError(error),
        const SizedBox(height: 20),
        const _OrDivider(),
        const SizedBox(height: 20),
        AppButton(
          label: context.s.continueGoogle,
          icon: AppIcons.googleLogo,
          variant: AppButtonVariant.secondary,
          onPressed: busy ? null : () => run(repo.signInWithGoogle),
        ),
        if (_showAppleAndPhone) ...[
          const SizedBox(height: 12),
          AppButton(
            label: context.s.continueApple,
            icon: AppIcons.appleLogo,
            variant: AppButtonVariant.secondary,
            onPressed: busy ? null : () => run(repo.signInWithApple),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: context.s.usePhone,
            icon: AppIcons.phone,
            variant: AppButtonVariant.secondary,
            onPressed: busy ? null : () => setState(() => _phoneMode = true),
          ),
        ],
        const SizedBox(height: 32),
        Text(context.s.noAccount, textAlign: TextAlign.center, style: AppText.body),
        const SizedBox(height: 10),
        AppButton(
          label: context.s.createAccount,
          variant: AppButtonVariant.secondary,
          onPressed: busy ? null : () => context.push('/login/register'),
        ),
      ],
    );
  }

  Widget _buildPhone(BuildContext context) {
    final otpStep = _sentTo != null;
    return OnboardingScaffold(
      title: otpStep ? context.s.otpTitle : context.s.phoneTitle,
      subtitle: otpStep ? context.s.otpSubtitle(_sentTo!) : context.s.phoneSubtitle,
      onBack: () => setState(() {
        if (otpStep) {
          _sentTo = null;
        } else {
          _phoneMode = false;
        }
        error = null;
      }),
      children: [
        if (!otpStep) ...[
          AppTextField(
            label: context.s.phoneLabel,
            controller: _phone,
            hint: '0812 3456 7890',
            keyboardType: TextInputType.phone,
            autofocus: true,
            onSubmitted: (_) => _sendOtp(),
          ),
          const SizedBox(height: 20),
          AppButton(label: busy ? context.s.sending : context.s.sendCode, onPressed: busy ? null : _sendOtp),
        ] else ...[
          AppTextField(
            label: context.s.otpLabel,
            controller: _otp,
            hint: '••••••',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            large: true,
            autofocus: true,
            onSubmitted: (_) => _verifyOtp(),
          ),
          const SizedBox(height: 20),
          AppButton(label: busy ? context.s.checking : context.s.signIn, onPressed: busy ? null : _verifyOtp),
          const SizedBox(height: 12),
          AppButton(
            label: context.s.resendCode,
            variant: AppButtonVariant.secondary,
            onPressed: busy ? null : _sendOtp,
          ),
        ],
        FormError(error),
        if (otpStep && SessionScope.of(context).repository is FakeRepository)
          DemoNote(context.s.demoOtp(FakeRepository.demoOtp)),
      ],
    );
  }
}

/// Daftar akun orang tua baru dengan email + kata sandi, atau langsung dengan Google.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with _AuthForm {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();

  /// Pendaftaran berhasil tetapi server meminta konfirmasi email dulu.
  bool _confirmSent = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  void _back() => context.canPop() ? context.pop() : context.go('/login');

  Future<void> _signUp() => run(() async {
    final email = _validEmail(_email);
    if (_password.text.length < 6) throw const AppException('weak_password');
    if (_repeat.text != _password.text) throw const AppException('password_mismatch');
    final signedIn = await SessionScope.read(context).repository.signUpWithEmail(email, _password.text);
    if (!signedIn && mounted) setState(() => _confirmSent = true);
  });

  @override
  Widget build(BuildContext context) {
    final repo = SessionScope.of(context).repository;

    return OnboardingScaffold(
      title: context.s.registerTitle,
      subtitle: context.s.registerSubtitle,
      onBack: _back,
      children: [
        AppTextField(
          label: context.s.emailLabel,
          controller: _email,
          hint: context.s.emailHint,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: context.s.passwordLabel,
          controller: _password,
          hint: context.s.passwordHint,
          obscureText: true,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: context.s.repeatPassword,
          controller: _repeat,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _signUp(),
        ),
        const SizedBox(height: 20),
        AppButton(label: busy ? context.s.registering : context.s.register, onPressed: busy ? null : _signUp),
        FormError(error),
        if (_confirmSent) DemoNote(context.s.confirmEmailSent),
        const SizedBox(height: 20),
        const _OrDivider(),
        const SizedBox(height: 20),
        AppButton(
          label: context.s.registerGoogle,
          icon: AppIcons.googleLogo,
          variant: AppButtonVariant.secondary,
          onPressed: busy ? null : () => run(repo.signInWithGoogle),
        ),
        const SizedBox(height: 32),
        Text(context.s.haveAccount, textAlign: TextAlign.center, style: AppText.body),
        const SizedBox(height: 10),
        AppButton(label: context.s.signIn, variant: AppButtonVariant.secondary, onPressed: busy ? null : _back),
      ],
    );
  }
}

/// Lupa kata sandi: kirim kode ke email, lalu masukkan kode + kata sandi baru. Berhasil = langsung masuk.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> with _AuthForm {
  late final _email = TextEditingController(text: widget.initialEmail);
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();

  /// Email tujuan tautan/kode; terisi = langkah kedua.
  String? _sentTo;

  /// Template email bawaan Supabase hanya berisi tautan; kode dipakai bila templatenya memuat {{ .Token }}.
  bool _codeMode = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  void _back() {
    if (_sentTo != null) {
      setState(() {
        _sentTo = null;
        _codeMode = false;
        error = null;
      });
    } else {
      context.canPop() ? context.pop() : context.go('/login');
    }
  }

  Future<void> _send() => run(() async {
    final email = _sentTo ?? _validEmail(_email);
    await SessionScope.read(context).repository.sendPasswordReset(email);
    if (mounted) setState(() => _sentTo = email);
  });

  Future<void> _reset() => run(() async {
    final code = _code.text.trim();
    if (code.length < 6) throw const AppException('invalid_otp');
    if (_password.text.length < 6) throw const AppException('weak_password');
    if (_repeat.text != _password.text) throw const AppException('password_mismatch');
    final session = SessionScope.read(context);
    // Tahan redirect sampai kata sandi baru tersimpan (sesi sudah masuk setelah kode benar)
    session.beginFlow();
    try {
      await session.repository.resetPassword(email: _sentTo!, code: code, newPassword: _password.text);
    } finally {
      await session.finishFlow();
    }
  });

  @override
  Widget build(BuildContext context) {
    final codeStep = _sentTo != null;
    final repo = SessionScope.of(context).repository;
    return OnboardingScaffold(
      title: codeStep ? context.s.resetCodeTitle : context.s.resetTitle,
      subtitle: codeStep ? context.s.resetCodeSubtitle(_sentTo!) : context.s.resetSubtitle,
      onBack: _back,
      children: [
        if (!codeStep) ...[
          AppTextField(
            label: context.s.emailLabel,
            controller: _email,
            hint: context.s.emailHint,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _send(),
          ),
          const SizedBox(height: 20),
          AppButton(label: busy ? context.s.sending : context.s.sendCode, onPressed: busy ? null : _send),
        ] else if (!_codeMode) ...[
          AppButton(
            label: busy ? context.s.sending : context.s.resendEmail,
            variant: AppButtonVariant.secondary,
            onPressed: busy ? null : _send,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: busy ? null : () => setState(() => _codeMode = true),
              style: TextButton.styleFrom(foregroundColor: AppColors.ink, minimumSize: const Size(48, 48)),
              child: Text(
                context.s.haveResetCode,
                style: AppText.bodySm.copyWith(fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
              ),
            ),
          ),
          if (repo is FakeRepository) ...[
            const SizedBox(height: 8),
            AppButton(
              label: context.s.demoOpenResetLink,
              variant: AppButtonVariant.secondary,
              onPressed: () => repo.debugOpenRecoveryLink(_sentTo!),
            ),
          ],
        ] else ...[
          AppTextField(
            label: context.s.resetCodeLabel,
            controller: _code,
            hint: '••••••',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 8,
            large: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: context.s.newPassword,
            controller: _password,
            hint: context.s.passwordHint,
            obscureText: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: context.s.repeatPassword,
            controller: _repeat,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _reset(),
          ),
          const SizedBox(height: 20),
          AppButton(label: busy ? context.s.saving : context.s.saveNewPassword, onPressed: busy ? null : _reset),
          const SizedBox(height: 12),
          AppButton(label: context.s.resendCode, variant: AppButtonVariant.secondary, onPressed: busy ? null : _send),
        ],
        FormError(error),
        if (_codeMode && repo is FakeRepository) DemoNote(context.s.demoResetCode(FakeRepository.demoOtp)),
      ],
    );
  }
}

/// Dibuka dari tautan atur ulang di email: sesi sudah masuk, tinggal membuat kata sandi baru.
class NewPasswordPage extends StatefulWidget {
  const NewPasswordPage({super.key});

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> with _AuthForm {
  final _password = TextEditingController();
  final _repeat = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _save() => run(() async {
    if (_password.text.length < 6) throw const AppException('weak_password');
    if (_repeat.text != _password.text) throw const AppException('password_mismatch');
    final session = SessionScope.read(context);
    await session.repository.updatePassword(_password.text);
    await session.finishPasswordRecovery();
  });

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: context.s.newPasswordTitle,
      subtitle: context.s.newPasswordSubtitle,
      children: [
        AppTextField(
          label: context.s.newPassword,
          controller: _password,
          hint: context.s.passwordHint,
          obscureText: true,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: context.s.repeatPassword,
          controller: _repeat,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 20),
        AppButton(label: busy ? context.s.saving : context.s.saveNewPassword, onPressed: busy ? null : _save),
        FormError(error),
      ],
    );
  }
}

/// Garis "atau" di antara email dan Google.
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    const line = Expanded(child: Divider(color: AppColors.lineSoft, thickness: 2));
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(context.s.or, style: AppText.bodySm.copyWith(color: AppColors.inkMuted)),
        ),
        line,
      ],
    );
  }
}
