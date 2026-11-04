import 'package:flutter/widgets.dart';

import '../theme/app_icons.dart';
import '../theme/typography.dart';
import 'icon_circle_button.dart';
import '../../l10n/strings.dart';

/// Angka dengan tombol − dan + (mis. batas laporan per hari, jumlah foto).
class NumberStepper extends StatelessWidget {
  const NumberStepper({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.unit = '',
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  /// Akhiran angka, mis. "×".
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      value: '$value$unit',
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.body)),
          IconCircleButton(
            icon: AppIcons.minus,
            semanticLabel: context.s.decrease(label),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 44,
            child: Text('$value$unit', textAlign: TextAlign.center, style: AppText.titleMd),
          ),
          IconCircleButton(
            icon: AppIcons.plus,
            semanticLabel: context.s.increase(label),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
