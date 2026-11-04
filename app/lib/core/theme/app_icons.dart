import 'package:flutter/widgets.dart';

/// Ikon Phosphor (design.md 6: garis tebal, sudut membulat).
///
/// Kode Dart paket phosphor_flutter 2.1.0 tidak bisa dikompilasi di Flutter 3.47
/// (`IconData` sekarang final), jadi paket itu hanya dipakai untuk file font-nya.
/// Jangan import `package:phosphor_flutter`; tambahkan ikon baru di sini dengan code point
/// dari lib/src/phosphor_icons_bold.dart di paket tersebut.
abstract final class AppIcons {
  static const appleLogo = IconData(0xe516, fontFamily: _bold, fontPackage: _pkg);
  static const arrowLeft = IconData(0xe058, fontFamily: _bold, fontPackage: _pkg);
  static const arrowUpRight = IconData(0xe092, fontFamily: _bold, fontPackage: _pkg);
  static const checkCircle = IconData(0xe184, fontFamily: _bold, fontPackage: _pkg);
  static const circle = IconData(0xe18a, fontFamily: _bold, fontPackage: _pkg);
  static const googleLogo = IconData(0xe292, fontFamily: _bold, fontPackage: _pkg);
  static const key = IconData(0xe2d6, fontFamily: _bold, fontPackage: _pkg);
  static const phone = IconData(0xe3b8, fontFamily: _bold, fontPackage: _pkg);
  static const signOut = IconData(0xe42a, fontFamily: _bold, fontPackage: _pkg);
  static const userPlus = IconData(0xe4d0, fontFamily: _bold, fontPackage: _pkg);
  static const caretRight = IconData(0xe13a, fontFamily: _bold, fontPackage: _pkg);
  static const check = IconData(0xe182, fontFamily: _bold, fontPackage: _pkg);
  static const checkSquare = IconData(0xe186, fontFamily: _bold, fontPackage: _pkg);
  static const clockCounterClockwise = IconData(0xe1a0, fontFamily: _bold, fontPackage: _pkg);
  static const envelope = IconData(0xe214, fontFamily: _bold, fontPackage: _pkg);
  static const eye = IconData(0xe220, fontFamily: _bold, fontPackage: _pkg);
  static const eyeSlash = IconData(0xe224, fontFamily: _bold, fontPackage: _pkg);
  static const flag = IconData(0xe244, fontFamily: _bold, fontPackage: _pkg);
  static const globe = IconData(0xe288, fontFamily: _bold, fontPackage: _pkg);
  static const gear = IconData(0xe270, fontFamily: _bold, fontPackage: _pkg);
  static const gift = IconData(0xe276, fontFamily: _bold, fontPackage: _pkg);
  static const hourglass = IconData(0xe2b2, fontFamily: _bold, fontPackage: _pkg);
  static const house = IconData(0xe2c2, fontFamily: _bold, fontPackage: _pkg);
  static const listChecks = IconData(0xeadc, fontFamily: _bold, fontPackage: _pkg);
  static const plus = IconData(0xe3d4, fontFamily: _bold, fontPackage: _pkg);
  static const sealCheck = IconData(0xe606, fontFamily: _bold, fontPackage: _pkg);
  static const star = IconData(0xe46a, fontFamily: _bold, fontPackage: _pkg);
  static const usersThree = IconData(0xe68e, fontFamily: _bold, fontPackage: _pkg);
  static const x = IconData(0xe4f6, fontFamily: _bold, fontPackage: _pkg);

  static const archive = IconData(0xe00c, fontFamily: _bold, fontPackage: _pkg);
  static const arrowCounterClockwise = IconData(0xe038, fontFamily: _bold, fontPackage: _pkg);
  static const camera = IconData(0xe10e, fontFamily: _bold, fontPackage: _pkg);
  static const clock = IconData(0xe19a, fontFamily: _bold, fontPackage: _pkg);
  static const images = IconData(0xe836, fontFamily: _bold, fontPackage: _pkg);
  static const minus = IconData(0xe32a, fontFamily: _bold, fontPackage: _pkg);
  static const pencilSimple = IconData(0xe3b4, fontFamily: _bold, fontPackage: _pkg);

  static const starFill = IconData(0xe46a, fontFamily: 'PhosphorFill', fontPackage: _pkg);

  /// Ikon tugas. Kunci disimpan di kolom tasks.icon (kunci template SQL: bed, dish, book, pencil, broom, trophy).
  static const tasks = <String, IconData>{
    'bed': IconData(0xe0cc, fontFamily: _bold, fontPackage: _pkg),
    'dish': IconData(0xe262, fontFamily: _bold, fontPackage: _pkg),
    'book': IconData(0xe0e6, fontFamily: _bold, fontPackage: _pkg),
    'pencil': IconData(0xe3b4, fontFamily: _bold, fontPackage: _pkg),
    'broom': IconData(0xec54, fontFamily: _bold, fontPackage: _pkg),
    'trophy': IconData(0xe67e, fontFamily: _bold, fontPackage: _pkg),
    'tooth': IconData(0xe9cc, fontFamily: _bold, fontPackage: _pkg),
    'dog': IconData(0xe74a, fontFamily: _bold, fontPackage: _pkg),
    'plant': IconData(0xebae, fontFamily: _bold, fontPackage: _pkg),
    'basket': IconData(0xe964, fontFamily: _bold, fontPackage: _pkg),
    'shirt': IconData(0xe670, fontFamily: _bold, fontPackage: _pkg),
    'trash': IconData(0xe4a6, fontFamily: _bold, fontPackage: _pkg),
    'bath': IconData(0xe81e, fontFamily: _bold, fontPackage: _pkg),
    'math': IconData(0xe538, fontFamily: _bold, fontPackage: _pkg),
    'music': IconData(0xe340, fontFamily: _bold, fontPackage: _pkg),
    'run': IconData(0xe730, fontFamily: _bold, fontPackage: _pkg),
  };

  static IconData task(String? key) => tasks[key] ?? checkSquare;

  static const timer = IconData(0xe492, fontFamily: _bold, fontPackage: _pkg);
  static const confetti = IconData(0xe81a, fontFamily: _bold, fontPackage: _pkg);

  /// Ikon hadiah. Kunci disimpan di kolom rewards.icon.
  static const rewards = <String, IconData>{
    'game': IconData(0xe26e, fontFamily: _bold, fontPackage: _pkg),
    'phone': IconData(0xe1e0, fontFamily: _bold, fontPackage: _pkg),
    'food': IconData(0xe262, fontFamily: _bold, fontPackage: _pkg),
    'pizza': IconData(0xe796, fontFamily: _bold, fontPackage: _pkg),
    'icecream': IconData(0xe804, fontFamily: _bold, fontPackage: _pkg),
    'movie': IconData(0xe8c2, fontFamily: _bold, fontPackage: _pkg),
    'ticket': IconData(0xe490, fontFamily: _bold, fontPackage: _pkg),
    'bike': IconData(0xe0d6, fontFamily: _bold, fontPackage: _pkg),
    'shopping': IconData(0xe416, fontFamily: _bold, fontPackage: _pkg),
    'shirt': IconData(0xe670, fontFamily: _bold, fontPackage: _pkg),
    'gift': IconData(0xe276, fontFamily: _bold, fontPackage: _pkg),
  };

  static IconData reward(String? key) => rewards[key] ?? gift;

  static const _bold = 'PhosphorBold';
  static const _pkg = 'phosphor_flutter';
}
