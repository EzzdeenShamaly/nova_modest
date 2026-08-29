import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// How the stepper is drawn. The behaviour is identical either way.
enum QuantityStepperVariant {
  /// The product page's sticky action bar: a filled block beside the primary
  /// button.
  filled,

  /// The cart line: a compact outlined control that sits quietly beside a
  /// price.
  outlined,
}

/// Minus / count / plus.
///
/// Lives in `core/widgets/` rather than inside a feature because two features
/// now use it — the product page and the cart. One control, one behaviour, and
/// [variant] carries the only difference the designs have between them.
///
/// Reports the value it wants; the bloc clamps. The buttons disable at the ends
/// so the affordance matches the rule rather than restating it.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.variant = QuantityStepperVariant.filled,
    super.key,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final QuantityStepperVariant variant;

  bool get _isOutlined => variant == QuantityStepperVariant.outlined;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _isOutlined ? AppColors.background : AppColors.secondary,
        borderRadius: BorderRadius.circular(AppRadius.s),
        border: _isOutlined
            ? const Border.fromBorderSide(
                BorderSide(color: AppColors.secondary),
              )
            : null,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepButton(
              icon: Icons.remove,
              label: l10n.productDecreaseQuantity,
              size: _isOutlined ? AppFontSize.m : AppFontSize.xl,
              onPressed: value > min ? () => onChanged(value - 1) : null,
            ),
            // Fixed width so the row does not jump when 9 becomes 10.
            SizedBox(
              width: AppSpacing.xl,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                // direction-fixed: a numeral has no linguistic direction
                textDirection: TextDirection.ltr,
                style: _isOutlined
                    ? textTheme.bodyMedium
                    : textTheme.titleLarge,
              ),
            ),
            _StepButton(
              icon: Icons.add,
              label: l10n.productIncreaseQuantity,
              size: _isOutlined ? AppFontSize.m : AppFontSize.xl,
              onPressed: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.label,
    required this.size,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final double size;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: size,
      tooltip: label,
      color: AppColors.muted,
      disabledColor: AppColors.subtle,
      // The design's compact control keeps its size while the touch target
      // still reaches the accessible minimum.
      visualDensity: VisualDensity.compact,
    );
  }
}
