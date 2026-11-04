part of 'supabase_repository.dart';

mixin _SupabaseFamily on _SupabaseBase implements FamilyRepository {
  static const _memberColumns = 'id, family_id, role, can_earn, name, avatar, birth_date';

  @override
  Stream<void> get authChanges => _client.auth.onAuthStateChange.map((_) {});

  @override
  Future<AuthUser?> currentUser() async {
    final user = _client.auth.currentUser;
    return user == null ? null : AuthUser(id: user.id, isAnonymous: user.isAnonymous);
  }

  // Google & Apple lewat OAuth di browser; sesi masuk lewat deep link [AppConfig.authRedirectUrl]
  // dan diumumkan oleh [authChanges]. Login native (google_sign_in / sign_in_with_apple) menyusul.
  @override
  Future<void> signInWithGoogle() =>
      _guard(() => _client.auth.signInWithOAuth(OAuthProvider.google, redirectTo: AppConfig.authRedirectUrl));

  @override
  Future<void> signInWithApple() =>
      _guard(() => _client.auth.signInWithOAuth(OAuthProvider.apple, redirectTo: AppConfig.authRedirectUrl));

  @override
  Future<void> signInWithEmail(String email, String password) =>
      _guard(() => _emailAuth(() => _client.auth.signInWithPassword(email: email, password: password)));

  @override
  Future<bool> signUpWithEmail(String email, String password) => _guard(() async {
    final res = await _emailAuth(
      () => _client.auth.signUp(email: email, password: password, emailRedirectTo: AppConfig.authRedirectUrl),
    );
    return res.session != null;
  });

  // Kode ada di email "Reset Password" lewat {{ .Token }} (Supabase Auth > Email Templates).
  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _emailAuth(() => _client.auth.resetPasswordForEmail(email, redirectTo: AppConfig.authRedirectUrl)));

  // Tautan di email membuka app lewat deep link; supabase_flutter menukarnya jadi sesi dan
  // mengumumkan passwordRecovery.
  @override
  Stream<void> get passwordRecovery =>
      _client.auth.onAuthStateChange.where((state) => state.event == AuthChangeEvent.passwordRecovery).map((_) {});

  @override
  Future<void> updatePassword(String newPassword) => _guard(() async {
    try {
      await _emailAuth(() => _client.auth.updateUser(UserAttributes(password: newPassword)));
    } on AppException catch (e) {
      // Sama dengan kata sandi lama: tidak ada yang perlu diubah
      if (e.code != 'same_password') rethrow;
    }
  });

  @override
  Future<void> resetPassword({required String email, required String code, required String newPassword}) =>
      _guard(() async {
        try {
          await _client.auth.verifyOTP(type: OtpType.recovery, email: email, token: code);
        } on AuthException {
          throw const AppException('invalid_otp');
        }
        await updatePassword(newPassword);
      });

  Future<T> _emailAuth<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on AuthException catch (e) {
      throw AppException(switch (e.code) {
        'invalid_credentials' => 'invalid_login',
        'email_not_confirmed' => 'email_not_confirmed',
        'user_already_exists' || 'email_exists' => 'email_taken',
        'weak_password' => 'weak_password',
        'same_password' => 'same_password',
        'over_email_send_rate_limit' || 'over_request_rate_limit' => 'rate_limited',
        'validation_failed' || 'email_address_invalid' => 'invalid_email',
        _ => 'auth_failed',
      });
    }
  }

  @override
  Future<void> sendPhoneOtp(String phone) => _guard(() => _client.auth.signInWithOtp(phone: phone));

  @override
  Future<void> verifyPhoneOtp(String phone, String code) async {
    try {
      await _client.auth.verifyOTP(type: OtpType.sms, phone: phone, token: code);
    } on AuthException {
      throw const AppException('invalid_otp');
    }
  }

  @override
  Future<void> signInAnonymously() => _guard(() => _client.auth.signInAnonymously());

  @override
  Future<void> signOut() => _guard(() async {
    for (final controller in _familyChanges.values) {
      unawaited(controller.close());
    }
    _familyChanges.clear();
    await _client.removeAllChannels();
    await _client.auth.signOut();
  });

  @override
  Future<List<Member>> myMemberships() => _guard(() async {
    final user = _client.auth.currentUser;
    if (user == null) return const <Member>[];
    final rows = await _client
        .from('members')
        .select('$_memberColumns, member_logins!inner(user_id)')
        .eq('member_logins.user_id', user.id)
        .eq('is_active', true)
        .order('created_at');
    return rows.map(Member.fromRow).toList();
  });

  @override
  Future<String> createFamily({required String familyName, required String ownerName, String locale = 'id'}) =>
      _guard(() async {
        final id = await _client.rpc(
          'create_family',
          params: {
            'p_family_name': familyName,
            'p_owner_name': ownerName,
            'p_timezone': indonesianTimezoneFor(DateTime.now().timeZoneOffset),
            'p_locale': locale,
          },
        );
        return id as String;
      });

  @override
  Future<Member> addChild({required String familyId, required String name, String? avatar, DateTime? birthDate}) =>
      _guard(() async {
        final row = await _client
            .from('members')
            .insert({
              'family_id': familyId,
              'role': 'member',
              'name': name,
              'avatar': avatar,
              'birth_date': birthDate == null ? null : _isoDate(birthDate),
            })
            .select(_memberColumns)
            .single();
        return Member.fromRow(row);
      });

  @override
  Future<void> applyTemplate({required String familyId, required AgeBand band}) =>
      _guard(() => _client.rpc('apply_economy_template', params: {'p_family_id': familyId, 'p_age_band': band.key}));

  @override
  Future<List<Member>> familyMembers(String familyId) => _guard(() async {
    final rows = await _client
        .from('members')
        .select('$_memberColumns, member_logins(user_id)')
        .eq('family_id', familyId)
        .eq('is_active', true)
        .order('created_at');
    return rows.map(Member.fromRow).toList();
  });

  @override
  Future<String> createInvite({required String familyId, required MemberRole role, String? memberId}) =>
      _guard(() async {
        final code = await _client.rpc(
          'create_invite',
          params: {'p_family_id': familyId, 'p_role': role.name, 'p_member_id': memberId},
        );
        return code as String;
      });

  @override
  Future<Member> joinFamily({required String code, String? name}) => _guard(() async {
    final id = await _client.rpc('join_family', params: {'p_code': code, 'p_name': name}) as String;
    final mine = await myMemberships();
    return mine.firstWhere((m) => m.id == id);
  });

  @override
  Future<void> setPin({required String memberId, required String pin}) =>
      _guard(() => _client.rpc('set_member_pin', params: {'p_member_id': memberId, 'p_pin': pin}));
}
