import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/features/onboarding/presentation/widgets/onboarding_dots.dart';

/// One onboarding page — **the** reusable slide. All three pages are this widget
/// with different copy; there is no per-slide file.
///
/// Built from Figma frame `22:104`, the reference the three frames were
/// normalised onto: image over the top 60%, then dots, title, body, and the
/// action button pinned to the bottom of the content area.
///
/// Each slide renders its own indicator from its own [pageIndex]. That is
/// deliberate: the dots then travel with the page during a swipe, so the outgoing
/// page shows its dot and the incoming page shows the next — a coherent
/// transition, rather than the double-row flicker a shared indicator inside a
/// `PageView` produces.
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    required this.title,
    required this.body,
    required this.pageIndex,
    required this.pageCount,
    required this.actionLabel,
    required this.onAction,
    this.image,
    super.key,
  });

  final String title;
  final String body;
  final int pageIndex;
  final int pageCount;

  /// "Next" on every page but the last, which finishes the onboarding.
  final String actionLabel;
  final VoidCallback onAction;

  /// The slide artwork. When null a palette-consistent placeholder is drawn.
  ///
  /// The design's source photographs are 286x512 — below 1x for a 390pt-wide
  /// slot, so shipping them would look upscaled on any modern phone. Passing this
  /// is the only change needed once real assets exist; nothing else relayouts.
  final Widget? image;

  /// Image occupies the top 60%, matching 530 of the reference frame's 884.
  static const int _imageFlex = 3;
  static const int _contentFlex = 2;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Expanded(
          flex: _imageFlex,
          child: _ImageArea(image: image),
        ),
        Expanded(
          flex: _contentFlex,
          // top: false so the artwork stays full-bleed under the status bar while
          // the button still clears the home indicator.
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.l,
                vertical: AppSpacing.xl,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // space-between when there is room, scroll when there is not.
                  // Without this the content overflows on a short window instead
                  // of becoming reachable.
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OnboardingDots(
                            count: pageCount,
                            activeIndex: pageIndex,
                          ),
                          Column(
                            children: [
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: textTheme.headlineLarge,
                              ),
                              SizedBox(height: AppSpacing.xs),
                              Text(
                                body,
                                textAlign: TextAlign.center,
                                style: textTheme.bodyLarge?.copyWith(
                                  // The design's #444748. Derived from the
                                  // palette, not added to it
                                  // (12-flutter-design-system-guard.md §3).
                                  color: AppColors.mutedStrong,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: onAction,
                              child: Text(actionLabel),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The artwork band, with the design's fade into the content area.
class _ImageArea extends StatelessWidget {
  const _ImageArea({this.image});

  final Widget? image;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        image ?? const _ArtworkPlaceholder(),
        // The design's bottom gradient, so the band dissolves into the page
        // instead of ending on a hard edge. Ratios only — no measurements.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, AppColors.background],
              stops: [0.65, 1],
            ),
          ),
        ),
      ],
    );
  }
}

/// Stands in until real artwork is supplied.
///
/// On-palette and deliberately calm rather than an error state — a first-launch
/// screen should not look broken.
class _ArtworkPlaceholder extends StatelessWidget {
  const _ArtworkPlaceholder();

  /// Sized to read at a glance across a band ~530pt tall. Specific to this one
  /// element on this one screen and used nowhere else, so it stays local rather
  /// than joining a shared scale (`12-flutter-design-system-guard.md` §5).
  static const double _iconSize = 64;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.secondary,
      child: Center(
        child: Icon(
          Icons.photo_size_select_actual_outlined,
          size: _iconSize,
          color: AppColors.subtle,
          semanticLabel: '',
        ),
      ),
    );
  }
}
