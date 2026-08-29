import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:nova_modest/features/onboarding/presentation/widgets/onboarding_slide.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// The three welcome slides, shown once per device on first launch.
///
/// A `PageView` over one [OnboardingSlide] per page. The screen owns only the
/// controller and the finish action; everything visual lives in the slide.
///
/// It does not navigate. Finishing dispatches [OnboardingFinished] and the
/// router's redirect guard moves the user to Home — the same contract every other
/// screen follows, so exactly one place decides where anyone may be.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();

  /// The visible page. `setState` is right here: it is ephemeral,
  /// widget-local, and nothing outside this screen has a rule about it
  /// (`02-flutter-state-guard.md`).
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() =>
      context.read<OnboardingBloc>().add(const OnboardingFinished());

  void _onAction(int lastIndex) {
    if (_page >= lastIndex) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final slides = <({String title, String body})>[
      (title: l10n.onboardingTitle1, body: l10n.onboardingBody1),
      (title: l10n.onboardingTitle2, body: l10n.onboardingBody2),
      (title: l10n.onboardingTitle3, body: l10n.onboardingBody3),
    ];
    final lastIndex = slides.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: slides.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) => OnboardingSlide(
              title: slides[index].title,
              body: slides[index].body,
              pageIndex: index,
              pageCount: slides.length,
              // Only the last page starts the app; the others advance.
              actionLabel: index == lastIndex
                  ? l10n.onboardingStart
                  : l10n.onboardingNext,
              onAction: () => _onAction(lastIndex),
            ),
          ),
          // Fixed chrome: identical on every page, so overlaying it once avoids
          // three copies sliding past each other.
          SafeArea(
            child: Align(
              // topStart, not topEnd: all three Figma frames put skip against
              // the right edge of an Arabic screen, and in RTL the right edge is
              // the start. It mirrors to the left in English, which is the same
              // corner relative to reading order.
              alignment: AlignmentDirectional.topStart,
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  top: AppSpacing.xl,
                  start: AppSpacing.l,
                ),
                // Skip ends the onboarding exactly as finishing it does — the
                // user has decided either way.
                child: _SkipButton(
                  onPressed: _finish,
                  label: l10n.onboardingSkip,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The skip affordance: a pill sitting on the artwork.
class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onPressed, required this.label});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.mutedStrong,
        textStyle: Theme.of(context).textTheme.labelMedium,
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        // Keeps the design's compact pill while still giving the 48dp tap area
        // accessibility asks for: this pads the touch target, not the paint.
        tapTargetSize: MaterialTapTargetSize.padded,
        minimumSize: Size.zero,
      ),
      child: Text(label),
    );
  }
}
