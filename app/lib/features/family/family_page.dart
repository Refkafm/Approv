import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/invite_code_card.dart';
import '../../core/widgets/list_row_pill.dart';
import '../../core/widgets/member_avatar.dart';
import '../../data/app_exception.dart';
import '../../data/models.dart';
import '../shell/session.dart';
import 'child_form.dart';

/// Keluarga & anggota (PRD O-12, M-01, M-02): daftar anggota, tambah anak, kode undangan.
class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  Future<List<Member>>? _members;

  SessionController get _session => SessionScope.read(context);
  Member get _me => _session.activeMember!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _members ??= _load();
  }

  Future<List<Member>> _load() => _session.repository.familyMembers(_me.familyId);

  // Blok {} wajib: closure setState tidak boleh mengembalikan Future
  void _reload() => setState(() {
    _members = _load();
  });

  Future<void> _showInvite({required MemberRole role, Member? child}) async {
    final repo = _session.repository;
    final String code;
    try {
      code = await repo.createInvite(familyId: _me.familyId, role: role, memberId: child?.id);
    } on AppException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.cardPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InviteCodeCard(code: code, forName: child?.name ?? 'orang tua / pengasuh'),
              const SizedBox(height: 16),
              Text(
                child != null
                    ? 'Di HP ${child.name}: buka app, pilih "Saya anak", lalu masukkan kode ini.'
                    : 'Di HP mereka: masuk dengan akun sendiri, lalu pilih "Punya kode undangan?".',
                style: AppText.body,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Tutup',
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
    _reload();
  }

  Future<void> _addChild() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpace.screenX,
          24,
          AppSpace.screenX,
          24 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tambah anak', style: AppText.titleLg),
              const SizedBox(height: 16),
              ChildForm(
                submitLabel: 'Simpan',
                onSubmit: (name, avatar, birthDate) async {
                  await _session.repository.addChild(
                    familyId: _me.familyId,
                    name: name,
                    avatar: avatar,
                    birthDate: birthDate,
                  );
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _me.role == MemberRole.owner;
    return SafeArea(
      child: FutureBuilder<List<Member>>(
        future: _members,
        builder: (context, snapshot) {
          final members = snapshot.data ?? const <Member>[];
          final children = members.where((m) => m.role == MemberRole.member).toList();
          final adults = members.where((m) => m.role.isAdmin).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpace.screenX, 16, AppSpace.screenX, 32),
            children: [
              Text('Keluarga', style: AppText.displayLg),
              const SizedBox(height: 20),
              if (snapshot.hasError)
                Text(
                  snapshot.error is AppException
                      ? (snapshot.error! as AppException).message
                      : 'Gagal memuat anggota keluarga.',
                  style: AppText.body.copyWith(color: AppColors.tangerineDeep),
                ),
              Text('Anak', style: AppText.titleLg),
              const SizedBox(height: 10),
              if (snapshot.connectionState == ConnectionState.done && children.isEmpty)
                Text('Belum ada anak.', style: AppText.body.copyWith(color: AppColors.inkMuted)),
              for (final child in children) ...[
                ListRowPill(
                  title: child.name,
                  subtitle: child.isConnected ? 'Terhubung ke HP anak' : 'Belum terhubung ke HP anak',
                  leading: MemberAvatar(name: child.name, avatarKey: child.avatar),
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: AppButton(
                      label: 'Kode',
                      variant: AppButtonVariant.secondary,
                      expand: false,
                      icon: AppIcons.key,
                      onPressed: () => _showInvite(role: MemberRole.member, child: child),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 6),
              AppButton(
                label: 'Tambah anak',
                variant: AppButtonVariant.secondary,
                icon: AppIcons.userPlus,
                onPressed: _addChild,
              ),
              const SizedBox(height: 28),
              Text('Orang tua & pengasuh', style: AppText.titleLg),
              const SizedBox(height: 10),
              for (final adult in adults) ...[
                ListRowPill(
                  title: adult.name,
                  subtitle: adult.role == MemberRole.owner ? 'Pemilik' : 'Admin',
                  leading: MemberAvatar(name: adult.name, avatarKey: adult.avatar),
                ),
                const SizedBox(height: 10),
              ],
              if (isOwner) ...[
                const SizedBox(height: 6),
                AppButton(
                  label: 'Undang orang tua / pengasuh',
                  variant: AppButtonVariant.secondary,
                  icon: AppIcons.userPlus,
                  onPressed: () => _showInvite(role: MemberRole.admin),
                ),
              ],
              const SizedBox(height: 40),
              AppButton(
                label: 'Pengaturan keluarga',
                icon: AppIcons.gear,
                variant: AppButtonVariant.secondary,
                onPressed: () => context.push('/parent/family/settings'),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Keluar',
                variant: AppButtonVariant.destructive,
                icon: AppIcons.signOut,
                onPressed: () => _session.signOut(),
              ),
            ],
          );
        },
      ),
    );
  }
}
