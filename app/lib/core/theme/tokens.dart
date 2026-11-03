import 'package:flutter/widgets.dart';

/// Token desain dari design.md (bagian 2, 4, 5, 10, 13).
/// Widget tidak boleh memakai warna, radius, atau durasi literal; selalu lewat token ini.
abstract final class AppColors {
  // Netral
  static const paper = Color(0xFFFBF7EE);
  static const paperGrid = Color(0xFFEFE7D6);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF161616);
  static const inkMuted = Color(0xFF6B6760);
  static const inkFaint = Color(0xFFA9A39A); // hanya placeholder & disabled
  static const lineSoft = Color(0xFFD9D3C7);

  // Blok warna
  static const tangerine = Color(0xFFE9693F);
  static const sunflower = Color(0xFFF4C845);
  static const grape = Color(0xFF6A4E9E);
  static const cobalt = Color(0xFF3E6CE0);
  static const bubblegum = Color(0xFFF08BB2);
  static const matcha = Color(0xFF9DB33F);

  // Pastel
  static const pastelLilac = Color(0xFFDCD5FF);
  static const pastelButter = Color(0xFFFBEFB4);
  static const pastelLime = Color(0xFFE4F5B8);
  static const pastelSky = Color(0xFFD8E7FF);
  static const pastelPeach = Color(0xFFFFDCCB);

  // Varian gelap untuk teks & stempel (lolos AA)
  static const tangerineDeep = Color(0xFFB4421C);
  static const matchaDeep = Color(0xFF5C6E1C);
  static const cobaltDeep = Color(0xFF2F55B8);
}

abstract final class AppRadius {
  static const pill = 999.0;
  static const card = 28.0;
  static const photo = 24.0;
  static const chip = 14.0;
  static const select = 40.0;
}

abstract final class AppStroke {
  static const width = 2.0;
  static const softWidth = 1.5;
}

/// Bayangan keras tanpa blur.
abstract final class HardShadow {
  static const sm = [BoxShadow(color: AppColors.ink, offset: Offset(2, 3))];
  static const md = [BoxShadow(color: AppColors.ink, offset: Offset(3, 4))];
  static const lg = [BoxShadow(color: AppColors.ink, offset: Offset(4, 6))];
}

abstract final class AppSpace {
  static const base = 8.0;
  static const screenX = 20.0;
  static const cardGap = 16.0;
  static const cardPadding = 20.0;
}

/// Area tap minimum: mode orang tua 48, mode anak 56.
abstract final class TapTarget {
  static const parent = 48.0;
  static const child = 56.0;
}

abstract final class AppMotion {
  static const press = Duration(milliseconds: 80);
  static const pressOffset = Offset(2, 3);
  static const cardIn = Duration(milliseconds: 220);
  static const cardStagger = Duration(milliseconds: 40);
  static const stamp = Duration(milliseconds: 320);
  static const countUp = Duration(milliseconds: 600);
  static const dotFill = Duration(milliseconds: 30);
  static const confetti = Duration(milliseconds: 1200);

  /// Pengganti semua animasi saat "reduce motion" aktif.
  static const reduced = Duration(milliseconds: 150);

  static bool reduce(BuildContext context) => MediaQuery.disableAnimationsOf(context);
}

/// Rotasi maksimum kartu foto/stiker, dalam derajat (−5° s/d +5°).
const tiltMaxDeg = 5.0;
