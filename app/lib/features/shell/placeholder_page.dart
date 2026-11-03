import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';

/// Tab yang layarnya belum dibuat. [plan] menyebut minggu & ID PRD dari Rencana Implementasi.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title, required this.plan});

  final String title;
  final String plan;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.screenX, 24, AppSpace.screenX, 24),
        children: [
          Text(title, style: AppText.displayLg),
          const SizedBox(height: 8),
          Text(plan, style: AppText.body.copyWith(color: AppColors.inkMuted)),
        ],
      ),
    );
  }
}
