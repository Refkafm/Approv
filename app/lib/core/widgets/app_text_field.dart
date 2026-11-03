import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

/// Input teks: label di atas, kotak putih bergaris ink 2px (design.md 2 & 4).
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.errorText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.maxLength,
    this.autofocus = false,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.large = false,
    this.maxLines = 1,
  });

  final String label;

  /// Lebih dari 1 untuk teks panjang (mis. deskripsi).
  final int maxLines;
  final TextEditingController controller;
  final String? hint;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool autofocus;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  /// Teks besar berjarak, untuk kode undangan, OTP, dan PIN.
  final bool large;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.chip),
      borderSide: BorderSide(color: color, width: width),
    );
    final textStyle = large ? AppText.displayLg.copyWith(letterSpacing: 6) : AppText.body;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          minLines: 1,
          maxLines: obscureText ? 1 : maxLines,
          autofocus: autofocus,
          obscureText: obscureText,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          onChanged: onChanged,
          style: textStyle,
          textAlign: large ? TextAlign.center : TextAlign.start,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: textStyle.copyWith(color: AppColors.inkFaint),
            errorText: errorText,
            errorStyle: AppText.bodySm.copyWith(color: AppColors.tangerineDeep),
            errorMaxLines: 3,
            counterText: '',
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: border(AppColors.ink, AppStroke.width),
            focusedBorder: border(AppColors.ink, 3),
            errorBorder: border(AppColors.tangerineDeep, AppStroke.width),
            focusedErrorBorder: border(AppColors.tangerineDeep, 3),
          ),
        ),
      ],
    );
  }
}
