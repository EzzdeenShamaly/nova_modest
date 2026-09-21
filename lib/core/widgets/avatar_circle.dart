import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// The shopper's picture, or the first letter of her name when there is none.
///
/// One widget for both places a face appears — the account header and the
/// personal-information form — so the fallback, the shape and the failure
/// behaviour are decided once. `12-flutter-design-system-guard` §5 Violation 3
/// is the reason it owns [defaultSize] rather than each screen keeping its own
/// copy of the design's disc.
///
/// **Every failure ends at the letter.** A link that has expired, a network
/// that is down, an image that will not decode: all of them fall back to the
/// initial, because a picture is decorative and a broken-image icon would read
/// as a defect in the account itself.
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    required this.imageUrl,
    required this.displayName,
    this.size,
    this.busy = false,
    this.onTap,
    super.key,
  });

  /// A ready-to-draw link, already signed by the repository, or null.
  final String? imageUrl;

  /// Used for the fallback letter — and for nothing else.
  final String displayName;

  /// Defaults to [defaultSize].
  final double? size;

  /// Draws progress over the picture while a new one uploads.
  final bool busy;

  /// When given, the circle becomes a button that changes the picture.
  final VoidCallback? onTap;

  /// The design's 64pt disc (Figma `1:1645`). A component measurement, not a
  /// spacing step, so it lives with the component instead of on the scale.
  static const double defaultSize = 64;

  /// The first character of the name **by code point**, so a name starting
  /// outside the basic plane is not cut in half.
  String get _initial {
    final name = displayName.trim();
    return name.isEmpty ? '' : String.fromCharCode(name.runes.first);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final diameter = size ?? defaultSize;

    final circle = SizedBox.square(
      dimension: diameter,
      child: ClipOval(
        child: ColoredBox(
          color: AppColors.secondary,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _Picture(imageUrl: imageUrl, letter: _initial, size: diameter),
              if (busy)
                ColoredBox(
                  // The picture stays visible underneath; this dims it rather
                  // than replacing it, so the change is progress and not a
                  // disappearance.
                  color: AppColors.background.withValues(alpha: _scrimAlpha),
                  child: const Center(
                    child: SizedBox.square(
                      dimension: _spinner,
                      child: CircularProgressIndicator(
                        strokeWidth: _spinnerStroke,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (onTap == null) {
      // Decorative here: the name is read out beside it, and announcing
      // "letter S" as well helps nobody.
      return ExcludeSemantics(child: circle);
    }

    return Semantics(
      button: true,
      label: l10n.profileAvatarChange,
      // The disc reads as one control: the badge is decoration and the letter
      // below is excluded from semantics, so nothing competes with this label.
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          circle,
          // The tap target covers the whole disc; at 64pt it clears the 48dp
          // floor on its own.
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: busy ? null : onTap,
              ),
            ),
          ),
          PositionedDirectional(
            bottom: 0,
            end: 0,
            child: _CameraBadge(diameter: diameter),
          ),
        ],
      ),
    );
  }

  /// Enough to keep the spinner readable over a photograph, not so much that
  /// the picture vanishes.
  static const double _scrimAlpha = 0.6;
  static const double _spinner = 20;
  static const double _spinnerStroke = 2;
}

/// The picture itself, with the letter standing in whenever it cannot be drawn.
class _Picture extends StatelessWidget {
  const _Picture({
    required this.imageUrl,
    required this.letter,
    required this.size,
  });

  final String? imageUrl;
  final String letter;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Excluded from semantics: the letter is a stand-in for a picture, not
    // information. Announced, it appends "س" to the button's name and reads the
    // shopper the first letter of her own name.
    final fallback = ExcludeSemantics(
      child: Center(
        child: Text(
          letter,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );

    final url = imageUrl;
    if (url == null || url.isEmpty) return fallback;

    return Image.network(
      url,
      fit: BoxFit.cover,
      // Decorative: the shopper's name sits next to it in every placement.
      excludeFromSemantics: true,
      // A signed link that has expired, or no connection: the letter, not a
      // broken-image glyph.
      errorBuilder: (_, _, _) => fallback,
      // **frameBuilder, not loadingBuilder.** `Image` hands `loadingBuilder` a
      // null `loadingProgress` until the first chunk arrives, and reading that
      // null as "loaded" returns a `RawImage` holding no image — a blank disc
      // for as long as the download takes. `frame == null` is the honest
      // "nothing to paint yet", so the letter holds the place until there is
      // something to replace it (measured on the emulator, 2026-09-21).
      frameBuilder: (_, child, frame, _) => frame == null ? fallback : child,
    );
  }
}

/// The small camera disc that marks the avatar as changeable.
class _CameraBadge extends StatelessWidget {
  const _CameraBadge({required this.diameter});

  /// The avatar's size, so the badge keeps its proportion at any scale.
  final double diameter;

  /// A third of the disc: large enough to read as a control, small enough not
  /// to cover the face.
  static const double _fraction = 1 / 3;

  @override
  Widget build(BuildContext context) {
    final badge = diameter * _fraction;

    return Container(
      width: badge,
      height: badge,
      decoration: BoxDecoration(
        color: AppColors.primaryText,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.background),
      ),
      child: Icon(
        Icons.photo_camera_outlined,
        size: AppFontSize.s,
        color: AppColors.background,
        // The Semantics wrapper above already names the control.
        semanticLabel: '',
      ),
    );
  }
}
