part of 'fake_repository.dart';

/// Akun & keluarga: meniru create_family, create_invite, join_family, set_member_pin, RLS members.
mixin _FakeFamily on _FakeState implements FamilyRepository {
  @override
  Stream<void> get authChanges => _auth.stream;

  @override
  Future<AuthUser?> currentUser() async => _user;

  void _signIn({required bool anonymous}) {
    _user = AuthUser(id: _id(anonymous ? 'anon' : 'user'), isAnonymous: anonymous);
    _auth.add(null);
  }

  @override
  Future<void> signInWithGoogle() async => _signIn(anonymous: false);

  @override
  Future<void> signInWithApple() async => _signIn(anonymous: false);

  @override
  Future<void> signInWithEmail(String email, String password) async {
    if (_emailAccounts[email.toLowerCase()] != password) throw const AppException('invalid_login');
    _signIn(anonymous: false);
  }

  @override
  Future<bool> signUpWithEmail(String email, String password) async {
    final key = email.toLowerCase();
    if (_emailAccounts.containsKey(key)) throw const AppException('email_taken');
    if (password.length < 6) throw const AppException('weak_password');
    _emailAccounts[key] = password;
    _signIn(anonymous: false);
    return true;
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> resetPassword({required String email, required String code, required String newPassword}) async {
    final key = email.toLowerCase();
    if (code != FakeRepository.demoOtp || !_emailAccounts.containsKey(key)) {
      throw const AppException('invalid_otp');
    }
    if (newPassword.length < 6) throw const AppException('weak_password');
    _emailAccounts[key] = newPassword;
    _signIn(anonymous: false);
  }

  @override
  Future<void> sendPhoneOtp(String phone) async {
    if (!RegExp(r'^\+62\d{8,13}$').hasMatch(phone)) throw const AppException('invalid_phone');
  }

  @override
  Future<void> verifyPhoneOtp(String phone, String code) async {
    if (code != FakeRepository.demoOtp) throw const AppException('invalid_otp');
    _signIn(anonymous: false);
  }

  @override
  Future<void> signInAnonymously() async => _signIn(anonymous: true);

  @override
  Future<void> signOut() async {
    _user = null;
    _auth.add(null);
  }

  @override
  Future<List<Member>> myMemberships() async {
    final user = _user;
    if (user == null) return const [];
    return [
      for (final m in _members.values)
        if (m.logins.contains(user.id)) m.member,
    ];
  }

  @override
  Future<String> createFamily({required String familyName, required String ownerName, String locale = 'id'}) async {
    final user = _requireUser();
    if (user.isAnonymous) throw const AppException('account_required');
    final familyId = _id('family');
    _families[familyId] = 'Asia/Jakarta';
    _settings[familyId] = FamilySettings(name: familyName, locale: locale);
    final owner = Member(
      id: _id('member'),
      familyId: familyId,
      role: MemberRole.owner,
      name: ownerName,
      canEarn: false,
    );
    _members[owner.id] = _FakeMember(owner)..logins.add(user.id);
    return familyId;
  }

  @override
  Future<Member> addChild({required String familyId, required String name, String? avatar, DateTime? birthDate}) async {
    _requireAdmin(familyId);
    final child = Member(
      id: _id('member'),
      familyId: familyId,
      role: MemberRole.member,
      name: name,
      avatar: avatar,
      birthDate: birthDate,
    );
    _members[child.id] = _FakeMember(child);
    _notifyFamily(familyId);
    return child;
  }

  @override
  Future<void> applyTemplate({required String familyId, required AgeBand band}) async {
    _requireAdmin(familyId);
    final locale = _settings[familyId]!.locale;
    for (final input in EconomyTemplate.tasks(band, locale: locale)) {
      final id = _id('task');
      _tasks[id] = Task.fromInput(input, id: id, familyId: familyId);
    }
    for (final input in EconomyTemplate.rewards(band, locale: locale)) {
      final id = _id('reward');
      _rewards[id] = Reward.fromInput(input, id: id, familyId: familyId);
    }
    _notifyFamily(familyId);
  }

  @override
  Future<List<Member>> familyMembers(String familyId) async {
    _requireFamilyMember(familyId);
    return [
      for (final m in _members.values)
        if (m.member.familyId == familyId) m.withConnection,
    ];
  }

  @override
  Future<String> createInvite({required String familyId, required MemberRole role, String? memberId}) async {
    final admin = _requireAdmin(familyId);
    if (role == MemberRole.member) {
      final child = _members[memberId];
      if (child == null || child.member.familyId != familyId || child.member.role != MemberRole.member) {
        throw const AppException('member_not_found');
      }
      _invites.removeWhere((_, invite) => invite.memberId == memberId && invite.usedBy == null);
    } else if (admin.member.role != MemberRole.owner) {
      throw const AppException('owner_only');
    }

    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    String code;
    do {
      code = String.fromCharCodes(List.generate(6, (_) => alphabet.codeUnitAt(_random.nextInt(alphabet.length))));
    } while (_invites.containsKey(code));

    _invites[code] = _FakeInvite(
      familyId: familyId,
      role: role,
      memberId: role == MemberRole.member ? memberId : null,
      expiresAt: _clock().add(const Duration(hours: 24)),
    );
    return code;
  }

  @override
  Future<Member> joinFamily({required String code, String? name}) async {
    final user = _requireUser();
    final invite = _invites[code.trim().toUpperCase()];
    if (invite == null || invite.usedBy != null || !_clock().isBefore(invite.expiresAt)) {
      throw const AppException('invalid_invite');
    }

    final _FakeMember target;
    if (invite.role == MemberRole.member) {
      target = _members[invite.memberId]!;
      target.logins.clear(); // sesi lama di HP lain dicabut
    } else {
      if (user.isAnonymous) throw const AppException('account_required');
      final admin = Member(
        id: _id('member'),
        familyId: invite.familyId,
        role: MemberRole.admin,
        name: (name?.trim().isEmpty ?? true) ? 'Admin' : name!.trim(),
        canEarn: false,
      );
      target = _members[admin.id] = _FakeMember(admin);
    }
    target.logins.add(user.id);
    invite.usedBy = user.id;
    return target.member;
  }

  @override
  Future<void> setPin({required String memberId, required String pin}) async {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) throw const AppException('invalid_pin');
    final user = _requireUser();
    final target = _members[memberId] ?? (throw const AppException('not_authorized'));
    if (!target.logins.contains(user.id)) _requireAdmin(target.member.familyId);
    target.pin = pin;
  }

  /// Untuk tes & demo: keluarga milik orang tua lain dengan satu anak (template 10–13)
  /// dan kode undangan anak. Status login saat ini tidak berubah.
  Future<String> debugSeedFamily({String parentName = 'Ibu Rina', String childName = 'Raka'}) async {
    final previous = _user;
    final owner = AuthUser(id: _id('user'), isAnonymous: false);
    debugSeedOwnerId = owner.id;
    _user = owner;
    final familyId = await createFamily(familyName: 'Keluarga $parentName', ownerName: parentName);
    final child = await addChild(familyId: familyId, name: childName, avatar: 'lime');
    await applyTemplate(familyId: familyId, band: AgeBand.middle);
    final code = await createInvite(familyId: familyId, role: MemberRole.member, memberId: child.id);
    _user = previous;
    return code;
  }

  /// Untuk tes: id login orang tua dari [debugSeedFamily] terakhir.
  String? debugSeedOwnerId;

  /// Untuk tes: PIN yang tersimpan.
  String? debugPinOf(String memberId) => _members[memberId]?.pin;

  /// Untuk tes: ganti user yang login (seperti berpindah HP), lalu umumkan perubahan login.
  void debugSetUser(String userId, {bool anonymous = false}) {
    _user = AuthUser(id: userId, isAnonymous: anonymous);
    _auth.add(null);
  }

  /// Untuk tes: jalankan [body] sebagai user lain (mis. orang tua menyetujui dari HP-nya)
  /// tanpa mengubah layar yang sedang tampil.
  Future<T> debugAs<T>(String userId, Future<T> Function() body) async {
    final previous = _user;
    _user = AuthUser(id: userId, isAnonymous: false);
    try {
      return await body();
    } finally {
      _user = previous;
    }
  }
}
