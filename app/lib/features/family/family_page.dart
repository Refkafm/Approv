import 'package:flutter/material.dart';

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
import '../../core/widgets/motion.dart';
import '../../l10n/strings.dart';

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
              InviteCodeCard(code: code, forName: child?.name ?? context.s.parentOrCaregiver),
              const SizedBox(height: 16),
              Text(
                child != null ? context.s.inviteChildHint(child.name) : context.s.inviteAdultHint,
                style: AppText.body,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: context.s.close,
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
              Text(context.s.onbAddChildTitle, style: AppText.titleLg),
              const SizedBox(height: 16),
              ChildForm(
                submitLabel: context.s.save,
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
            children: staggered([
              Text(context.s.navFamily, style: AppText.displayLg),
              const SizedBox(height: 20),
              if (snapshot.hasError)
                Text(
                  snapshot.error is AppException
                      ? (snapshot.error! as AppException).message
                      : context.s.loadMembersFailed,
                  style: AppText.body.copyWith(color: AppColors.tangerineDeep),
                ),
              Text(context.s.children, style: AppText.titleLg),
              const SizedBox(height: 10),
              if (snapshot.connectionState == ConnectionState.done && children.isEmpty)
                Text(context.s.noChildren, style: AppText.body.copyWith(color: AppColors.inkMuted)),
              for (final child in children) ...[
                ListRowPill(
                  title: child.name,
                  subtitle: child.isConnected ? context.s.connectedToChildPhone : context.s.notConnectedToChildPhone,
                  leading: MemberAvatar(name: child.name, avatarKey: child.avatar),
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: AppButton(
                      label: context.s.codeButton,
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
                label: context.s.addChild,
                variant: AppButtonVariant.secondary,
                icon: AppIcons.userPlus,
                onPressed: _addChild,
              ),
              const SizedBox(height: 28),
              Text(context.s.parentsAndCaregivers, style: AppText.titleLg),
              const SizedBox(height: 10),
              for (final adult in adults) ...[
                ListRowPill(
                  title: adult.name,
                  subtitle: adult.role == MemberRole.owner ? context.s.roleOwner : context.s.roleAdmin,
                  leading: MemberAvatar(name: adult.name, avatarKey: adult.avatar),
                ),
                const SizedBox(height: 10),
              ],
              if (isOwner) ...[
                const SizedBox(height: 6),
                AppButton(
                  label: context.s.inviteAdult,
                  variant: AppButtonVariant.secondary,
                  icon: AppIcons.userPlus,
                  onPressed: () => _showInvite(role: MemberRole.admin),
                ),
              ],
            ]),
          );
        },
      ),
    );
  }
}
