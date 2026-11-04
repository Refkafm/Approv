import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'pressable.dart';
import '../../l10n/strings.dart';

/// Avatar anggota: lingkaran pastel bergaris ink dengan huruf awal nama.
/// Kunci warna disimpan di kolom members.avatar. Avatar ilustrasi menyusul (design.md 6).
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.name, this.avatarKey, this.size = 44});

  final String name;
  final String? avatarKey;
  final double size;

  static const colors = {
    'lime': AppColors.pastelLime,
    'lilac': AppColors.pastelLilac,
    'sky': AppColors.pastelSky,
    'peach': AppColors.pastelPeach,
    'butter': AppColors.pastelButter,
  };

  static Color colorOf(String? key) => colors[key] ?? AppColors.pastelButter;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorOf(avatarKey),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.ink, width: AppStroke.width),
        ),
        child: Text(initial, style: AppText.titleMd.copyWith(fontSize: size * 0.42)),
      ),
    );
  }
}

/// Deretan pilihan warna avatar.
class AvatarPicker extends StatelessWidget {
  const AvatarPicker({super.key, required this.name, required this.selected, required this.onChanged});

  final String name;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final key in MemberAvatar.colors.keys)
          Pressable(
            semanticLabel: context.s.avatarSemantic(context.s.avatarColorName(key)),
            selected: key == selected,
            onTap: () => onChanged(key),
            builder: (context, pressed) => Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: key == selected ? AppColors.ink : const Color(0x00000000),
                  width: AppStroke.width,
                ),
              ),
              child: MemberAvatar(name: name, avatarKey: key, size: 48),
            ),
          ),
      ],
    );
  }
}
