import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/indonesia.dart';
import '../../core/theme/app_icons.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/app_exception.dart';
import '../../data/fake/fake_repository.dart';
import '../shell/session.dart';
import 'onboarding_scaffold.dart';

/// Masuk / daftar orang tua (PRD A-01, layar O-1): Google atau email + kata sandi.
/// Apple dan nomor HP + OTP disembunyikan sementara lewat [_showAppleAndPhone].
/// Setelah berhasil, router membawa ke onboarding (belum punya keluarga) atau beranda.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

enum _Mode { choose, email, phone }

const _showAppleAndPhone = false;

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  _Mode _mode = _Mode.choose;
  String? _sentTo;
  bool _busy = false;
  String? _error;

  /// Pendaftaran berhasil tetapi server meminta konfirmasi email dulu.
  bool _confirmSent = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  void _setMode(_Mode mode) => setState(() {
    _mode = mode;
    _error = null;
    _confirmSent = false;
  });

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

  Future<void> _sendOtp() => _run(() async {
    final phone = normalizeIndonesianPhone(_phone.text);
    if (phone == null) throw const AppException('invalid_phone');
    await SessionScope.read(context).repository.sendPhoneOtp(phone);
    if (mounted) setState(() => _sentTo = phone);
  });

  Future<void> _verifyOtp() =>
      _run(() => SessionScope.read(context).repository.verifyPhoneOtp(_sentTo!, _otp.text.trim()));

  ({String email, String password}) _credentials() {
    final email = _email.text.trim();
    if (!_emailPattern.hasMatch(email)) throw const AppException('invalid_email');
    if (_password.text.length < 6) throw const AppException('weak_password');
    return (email: email, password: _password.text);
  }

  Future<void> _signInEmail() => _run(() async {
    final c = _credentials();
    await SessionScope.read(context).repository.signInWithEmail(c.email, c.password);
  });

  Future<void> _signUpEmail() => _run(() async {
    final c = _credentials();
    final signedIn = await SessionScope.read(context).repository.signUpWithEmail(c.email, c.password);
    if (!signedIn && mounted) setState(() => _confirmSent = true);
  });

  @override
  Widget build(BuildContext context) {
    final repo = SessionScope.of(context).repository;

    if (_mode == _Mode.choose) {
      return OnboardingScaffold(
        title: 'Masuk sebagai orang tua',
        subtitle: 'Akun dipakai untuk menyimpan data keluarga. Anak tidak perlu akun.',
        onBack: () => context.go('/'),
        children: [
          AppButton(
            label: 'Lanjut dengan Google',
            icon: AppIcons.googleLogo,
            variant: AppButtonVariant.secondary,
            onPressed: _busy ? null : () => _run(repo.signInWithGoogle),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Pakai email',
            icon: AppIcons.envelope,
            variant: AppButtonVariant.secondary,
            onPressed: _busy ? null : () => _setMode(_Mode.email),
          ),
          if (_showAppleAndPhone) ...[
            const SizedBox(height: 16),
            AppButton(
              label: 'Lanjut dengan Apple',
              icon: AppIcons.appleLogo,
              variant: AppButtonVariant.secondary,
              onPressed: _busy ? null : () => _run(repo.signInWithApple),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Pakai nomor HP',
              icon: AppIcons.phone,
              variant: AppButtonVariant.secondary,
              onPressed: _busy ? null : () => _setMode(_Mode.phone),
            ),
          ],
          FormError(_error),
        ],
      );
    }

    if (_mode == _Mode.email) {
      return OnboardingScaffold(
        title: 'Masuk dengan email',
        subtitle: 'Belum punya akun? Isi email & kata sandi baru, lalu pilih Daftar.',
        onBack: () => _setMode(_Mode.choose),
        children: [
          AppTextField(
            label: 'Email',
            controller: _email,
            hint: 'nama@email.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Kata sandi',
            controller: _password,
            hint: 'Minimal 6 karakter',
            obscureText: true,
            onSubmitted: (_) => _signInEmail(),
          ),
          const SizedBox(height: 20),
          AppButton(label: _busy ? 'Memeriksa...' : 'Masuk', onPressed: _busy ? null : _signInEmail),
          const SizedBox(height: 12),
          AppButton(label: 'Daftar', variant: AppButtonVariant.secondary, onPressed: _busy ? null : _signUpEmail),
          FormError(_error),
          if (_confirmSent)
            const DemoNote('Akun dibuat. Buka tautan konfirmasi di email kamu, lalu kembali ke sini dan pilih Masuk.'),
        ],
      );
    }

    final otpStep = _sentTo != null;
    return OnboardingScaffold(
      title: otpStep ? 'Masukkan kode OTP' : 'Nomor HP kamu',
      subtitle: otpStep ? 'Kode 6 angka dikirim lewat SMS ke $_sentTo.' : 'Kami kirim kode OTP lewat SMS.',
      onBack: () => setState(() {
        if (otpStep) {
          _sentTo = null;
        } else {
          _mode = _Mode.choose;
        }
        _error = null;
      }),
      children: [
        if (!otpStep) ...[
          AppTextField(
            label: 'Nomor HP',
            controller: _phone,
            hint: '0812 3456 7890',
            keyboardType: TextInputType.phone,
            autofocus: true,
            onSubmitted: (_) => _sendOtp(),
          ),
          const SizedBox(height: 20),
          AppButton(label: _busy ? 'Mengirim...' : 'Kirim kode', onPressed: _busy ? null : _sendOtp),
        ] else ...[
          AppTextField(
            label: 'Kode OTP',
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
          AppButton(label: _busy ? 'Memeriksa...' : 'Masuk', onPressed: _busy ? null : _verifyOtp),
          const SizedBox(height: 12),
          AppButton(label: 'Kirim ulang kode', variant: AppButtonVariant.secondary, onPressed: _busy ? null : _sendOtp),
        ],
        FormError(_error),
        if (otpStep && repo is FakeRepository) const DemoNote('Mode demo: kode OTP selalu ${FakeRepository.demoOtp}.'),
      ],
    );
  }
}
