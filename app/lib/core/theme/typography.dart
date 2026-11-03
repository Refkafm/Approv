import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Skala tipografi design.md bagian 3: Gabarito untuk display & angka, Plus Jakarta Sans untuk UI.
abstract final class AppText {
  /// Dimatikan di tes supaya tidak mengunduh font.
  static bool useGoogleFonts = true;

  static TextStyle get displayXl => _display(40, 44);
  static TextStyle get displayLg => _display(32, 36);

  static TextStyle get numberHero => _display(48, 48).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  static TextStyle get titleLg => _body(24, 30, FontWeight.w700);
  static TextStyle get titleMd => _body(18, 24, FontWeight.w700);
  static TextStyle get body => _body(15, 22, FontWeight.w500);
  static TextStyle get bodySm => _body(13, 18, FontWeight.w500);
  static TextStyle get label => _body(13, 16, FontWeight.w600);
  static TextStyle get button => _body(17, 22, FontWeight.w700);

  /// Teks stempel status (satu-satunya tempat ALL CAPS).
  static TextStyle get stamp => _display(18, 20).copyWith(letterSpacing: 0.5);

  static TextStyle _display(double size, double lineHeight) => _font(
    'Gabarito',
    TextStyle(
      fontSize: size,
      height: lineHeight / size,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.01 * size,
      color: AppColors.ink,
    ),
  );

  static TextStyle _body(double size, double lineHeight, FontWeight weight) => _font(
    'Plus Jakarta Sans',
    TextStyle(fontSize: size, height: lineHeight / size, fontWeight: weight, color: AppColors.ink),
  );

  static TextStyle _font(String family, TextStyle base) =>
      useGoogleFonts ? GoogleFonts.getFont(family, textStyle: base) : base.copyWith(fontFamily: family);
}
