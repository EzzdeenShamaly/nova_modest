import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';

/// Which surface a [SettingsCard] sits on.
enum SettingsCardVariant {
  /// The page colour behind a hairline border — the account menu, help and
  /// notification preferences.
  outlined,

  /// A filled sand panel with no border, and rules that match it — the
  /// language chooser, which is the only frame drawn this way.
  filled,
}

/// A rounded card holding a column of rows, ruled between them.
///
/// **This existed four times before it existed once.** `_MenuCard` in the
/// account screen, `_Card` in help and `_Card` in notification preferences were
/// byte-for-byte identical down to the comment; `_OptionCard` in the language
/// screen differed only in its fill and the colour of its rules. Each was
/// defensible alone, and together they were a card that had stopped being one —
/// the shape `12-flutter-design-system-guard` exists to prevent, in layout
/// rather than in colour.
///
/// It carries **no behaviour**: the rows are the caller's, and this owns the
/// surface, the corners and the rules between them.
class SettingsCard extends StatelessWidget {
  const SettingsCard({
    required this.children,
    this.variant = SettingsCardVariant.outlined,
    super.key,
  });

  /// One per row. The rule is drawn between them and never after the last.
  final List<Widget> children;

  final SettingsCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final (Color surface, Color rule) = switch (variant) {
      // `subtle` is a derived alpha, so it is `final` rather than `const` —
      // which is why neither the border nor the Divider below can be a const
      // expression.
      SettingsCardVariant.outlined => (AppColors.background, AppColors.subtle),
      SettingsCardVariant.filled => (AppColors.secondary, AppColors.secondary),
    };

    return Material(
      color: surface,
      // clipBehavior so a row's ink splash stops at the rounded corner rather
      // than squaring it off.
      clipBehavior: Clip.antiAlias,
      // shape, not borderRadius: Material asserts if given both, and the border
      // has to come from the shape.
      shape: RoundedRectangleBorder(
        side: variant == SettingsCardVariant.outlined
            ? BorderSide(color: rule)
            : BorderSide.none,
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Column(
        children: [
          for (final child in children) ...[
            child,
            // height 0: the rule itself, with none of the Divider theme's
            // surrounding space, because the rows already carry their own.
            if (child != children.last) Divider(height: 0, color: rule),
          ],
        ],
      ),
    );
  }
}
