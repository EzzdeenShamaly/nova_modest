import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_colour.dart';

/// The colour choices for a product.
///
/// Each swatch is painted in the garment's **actual** colour, parsed from the
/// hex the catalogue supplies. That is content, not design-system palette — a
/// swatch showing anything else would misinform the shopper — so no colour
/// literal appears here and the palette does not grow
/// (`12-flutter-design-system-guard.md`).
///
/// Everything around the swatch — the selected ring, the tick — comes from the
/// palette as usual.
class ColourSwatchRow extends StatelessWidget {
  const ColourSwatchRow({
    required this.colours,
    required this.selectedId,
    required this.onSelected,
    super.key,
  });

  final List<ProductColour> colours;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final colour in colours) ...[
          ColourSwatch(
            colour: colour,
            selected: colour.id == selectedId,
            onTap: () => onSelected(colour.id),
          ),
          SizedBox(width: AppSpacing.m),
        ],
      ],
    );
  }
}

/// One garment colour as a tappable disc.
///
/// Public because two layouts need it: [ColourSwatchRow] offers a product's
/// colours one-of-many on the product page, and the filter sheet wraps the same
/// disc many-of-many. The parsing, the fallback and the luminance-aware tick are
/// the part that must not be written twice; the layout around them is not.
class ColourSwatch extends StatelessWidget {
  const ColourSwatch({
    required this.colour,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final ProductColour colour;
  final bool selected;
  final VoidCallback onTap;

  /// The design's 40x40 disc. One element on one widget, so it stays local
  /// (`12-flutter-design-system-guard.md` §5).
  static const double _size = 40;

  /// Parses `#RRGGBB` from the catalogue.
  ///
  /// Falls back to the page colour rather than throwing: a malformed hex from
  /// the backend should leave an unremarkable swatch, not crash a product page.
  Color? _parse(String hex) {
    final cleaned = hex.replaceFirst('#', '').trim();
    if (cleaned.length != 6) return null;
    final value = int.tryParse(cleaned, radix: 16);
    return value == null ? null : Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    final swatch = _parse(colour.hex) ?? AppColors.secondary;

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: colour.name,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            color: swatch,
            shape: BoxShape.circle,
            // The ring is palette; only the fill is content.
            border: Border.all(
              color: selected ? AppColors.primaryText : AppColors.secondary,
              width: selected ? 2 : 1,
            ),
          ),
          child: selected
              ? Icon(
                  Icons.check,
                  size: AppFontSize.l,
                  // Reads against whichever colour the garment happens to be.
                  color: swatch.computeLuminance() > 0.5
                      ? AppColors.primaryText
                      : AppColors.background,
                  semanticLabel: '',
                )
              : null,
        ),
      ),
    );
  }
}
