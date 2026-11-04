import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/strings.dart';
import '../theme/app_icons.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// Input teks: label di atas, kotak putih bergaris ink 2px (design.md 2 & 4).
/// Kolom tersembunyi ([obscureText]) punya tombol mata di kanan untuk melihat isinya.
class AppTextField extends StatefulWidget {
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
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final obscured = widget.obscureText && !_revealed;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.chip),
      borderSide: BorderSide(color: color, width: width),
    );
    final textStyle = widget.large ? AppText.displayLg.copyWith(letterSpacing: 6) : AppText.body;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppText.label),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          textCapitalization: widget.textCapitalization,
          inputFormatters: widget.inputFormatters,
          maxLength: widget.maxLength,
          minLines: 1,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          autofocus: widget.autofocus,
          obscureText: obscured,
          textInputAction: widget.textInputAction,
          onSubmitted: widget.onSubmitted,
          onChanged: widget.onChanged,
          style: textStyle,
          textAlign: widget.large ? TextAlign.center : TextAlign.start,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: textStyle.copyWith(color: AppColors.inkFaint),
            errorText: widget.errorText,
            errorStyle: AppText.bodySm.copyWith(color: AppColors.tangerineDeep),
            errorMaxLines: 3,
            counterText: '',
            suffixIcon: widget.obscureText
                ? IconButton(
                    onPressed: () => setState(() => _revealed = !_revealed),
                    tooltip: _revealed ? context.s.hidePassword : context.s.showPassword,
                    icon: Icon(_revealed ? AppIcons.eyeSlash : AppIcons.eye, size: 22, color: AppColors.ink),
                  )
                : null,
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
