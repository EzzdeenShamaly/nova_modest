import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/features/checkout/domain/entities/checkout_step.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// The progress rail at the top of each checkout step, from Figma `1:1944`.
///
/// Three stations joined by rails, and **three appearances, not two**: a step
/// already passed, the one being worked on, and one still ahead.
///
/// The three frames each draw this differently — `1:2163` three equal 10pt
/// dots, `1:1944` dots with rails, `1:2059` a 32pt pill and two dots — and only
/// `1:1944` shows a passed step and an upcoming one at the same time. It is
/// therefore the reference: everything else here is measured from it.
///
/// **Passed is `subtle`; ahead is `hairline`, the fainter of the two.** Measured
/// by absolute x, not by child order: the frames are RTL, so the *rightmost*
/// child is step one. In `1:1944` the rightmost station (step 1, passed) is
/// `#CEC5BA` and the leftmost (step 3, ahead) is `#EBE7E6`; `1:2059` confirms it
/// with both of its passed steps in `#CEC5BA`. This file had the two backwards
/// until step 3 was read — from the same left-to-right misreading that once
/// filed `1:2163` as "step 3 of sign-up".
///
/// Built in **logical** order — step one first — and laid out by a `Row` with no
/// `textDirection`, so the active first station lands on the right of an Arabic
/// screen. **Centred**, as all three frames centre it.
///
/// Shapes alone say nothing to a screen reader, so the row carries a label.
class CheckoutStepIndicator extends StatelessWidget {
  const CheckoutStepIndicator({required this.step, super.key});

  final CheckoutStep step;

  /// The design's station sizes: 8pt at rest, 12pt for the one in progress, so
  /// position is not the only signal. Component measurements, not values on the
  /// spacing scale (`12-flutter-design-system-guard.md` §5).
  static const double _stationSize = 8;
  static const double _activeStationSize = 12;

  /// The rail between two stations, 48x4 in the frame. Fixed rather than
  /// `Expanded`: the design's rail does not stretch to the page width, and the
  /// whole row measures 148pt, so it cannot overflow a phone.
  static const double _railLength = 48;
  static const double _railThickness = 4;

  @override
  Widget build(BuildContext context) {
    final index = step.indicatorIndex;
    // Review and success draw no indicator: the design gives them none, because
    // neither is one of the three steps.
    if (index == null) return const SizedBox.shrink();

    return Semantics(
      container: true,
      label: AppLocalizations.of(
        context,
      ).checkoutStepOf(index + 1, CheckoutStep.indicatorCount),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (
            var position = 0;
            position < CheckoutStep.indicatorCount;
            position++
          ) ...[
            _Station(
              size: position == index ? _activeStationSize : _stationSize,
              colour: _colourFor(position: position, active: index),
            ),
            if (position != CheckoutStep.indicatorCount - 1) ...[
              SizedBox(width: AppSpacing.xs),
              _Rail(
                colour: _railColourFor(after: position, active: index),
              ),
              SizedBox(width: AppSpacing.xs),
            ],
          ],
        ],
      ),
    );
  }

  /// Passed, in progress, or still ahead.
  ///
  /// The fainter level marks the part that **has not happened yet**, not the
  /// part behind — see the class doc for the measurement that settles it.
  static Color _colourFor({required int position, required int active}) =>
      switch (position) {
        _ when position == active => AppColors.accent,
        _ when position < active => AppColors.subtle,
        _ => AppColors.hairline,
      };

  /// A rail is only ever passed or ahead — never the accent.
  ///
  /// It spans the gap **after** station [after], so it is behind the shopper
  /// only once that station is: the rail leading into the active station is
  /// passed, the one leading out of it is not. Giving a rail the colour of the
  /// station it follows paints the one ahead in accent, which reads as two
  /// steps in progress at once — which is what it did until a test compared
  /// all five against the frame.
  static Color _railColourFor({required int after, required int active}) =>
      after < active ? AppColors.subtle : AppColors.hairline;
}

class _Station extends StatelessWidget {
  const _Station({required this.size, required this.colour});

  final double size;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.colour});

  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: CheckoutStepIndicator._railLength,
      height: CheckoutStepIndicator._railThickness,
      decoration: BoxDecoration(
        color: colour,
        borderRadius: BorderRadius.circular(
          CheckoutStepIndicator._railThickness,
        ),
      ),
    );
  }
}
