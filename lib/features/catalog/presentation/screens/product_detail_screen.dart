import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// hide TextDirection: intl exports a class of the same name, which shadows
// dart:ui's and silently breaks every directional literal in this file.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/core/widgets/quantity_stepper.dart';
import 'package:nova_modest/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_feature.dart';
import 'package:nova_modest/features/catalog/presentation/bloc/product_detail_bloc.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/colour_swatch_row.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/product_image_carousel.dart';
import 'package:nova_modest/l10n/app_localizations.dart';
import 'package:nova_modest/router/routes.dart';

/// One product, in full.
///
/// Built from Figma frame `1:2584`. A **top-level** route, not a shell branch:
/// the design replaces the bottom navigation with a sticky action bar, so the
/// buying screen takes the whole display and back returns wherever the shopper
/// came from.
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductDetailBloc>(
      create: (_) =>
          sl<ProductDetailBloc>()..add(ProductDetailRequested(productId)),
      child: _ProductDetailView(productId: productId),
    );
  }
}

class _ProductDetailView extends StatelessWidget {
  const _ProductDetailView({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          l10n.brandName,
          // direction-fixed: a brandmark's glyph order is fixed by the mark
          // itself, not by the reader's language
          textDirection: TextDirection.ltr,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        actions: [
          IconButton(
            // Sharing needs a platform share sheet, which would mean a package
            // that is not in pubspec.yaml. Disabled rather than pretending.
            onPressed: null,
            icon: const Icon(Icons.share_outlined),
            tooltip: l10n.productShare,
          ),
        ],
      ),
      body: BlocBuilder<ProductDetailBloc, ProductDetailState>(
        builder: (context, state) => switch (state) {
          ProductDetailInitial() || ProductDetailLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          ProductDetailError(:final failure) => FailureView(
            failure: failure,
            onRetry: () => context.read<ProductDetailBloc>().add(
              ProductDetailRefreshed(productId),
            ),
          ),
          ProductDetailLoaded() => _Body(state: state),
        },
      ),
      // bottomNavigationBar is the slot that pins: the bar stays put while the
      // page scrolls, which is what "sticky" means in the design.
      bottomNavigationBar: BlocBuilder<ProductDetailBloc, ProductDetailState>(
        builder: (context, state) => state is ProductDetailLoaded
            ? _ActionBar(state: state)
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final ProductDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final bloc = context.read<ProductDetailBloc>();
    final product = state.product;

    final price = NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      symbol: l10n.currencySymbol,
      decimalDigits: 0,
    ).format(product.price);

    return ListView(
      padding: EdgeInsetsDirectional.only(bottom: AppSpacing.xxl),
      children: [
        ProductImageCarousel(
          images: product.images,
          isFavourite: product.isFavourite,
        ),
        Padding(
          padding: EdgeInsetsDirectional.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.name, style: textTheme.titleLarge),
              SizedBox(height: AppSpacing.xs),
              Text(
                price,
                style: textTheme.titleLarge?.copyWith(color: AppColors.accent),
              ),
              if (product.colours.isNotEmpty)
                _Section(
                  title: l10n.productColour,
                  child: ColourSwatchRow(
                    colours: product.colours,
                    selectedId: state.selectedColourId,
                    onSelected: (id) =>
                        bloc.add(ProductDetailColourSelected(id)),
                  ),
                ),
              if (product.sizes.isNotEmpty)
                _Section(
                  title: l10n.productSize,
                  // The chart screen does not exist yet, so the link is inert
                  // rather than leading nowhere.
                  trailing: Text(
                    l10n.productSizeGuide,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.subtle,
                    ),
                  ),
                  child: _SizeSelector(
                    sizes: product.sizes,
                    selected: state.selectedSize,
                    onSelected: (size) =>
                        bloc.add(ProductDetailSizeSelected(size)),
                  ),
                ),
              if (product.description != null || product.features.isNotEmpty)
                _Section(
                  title: l10n.productDetails,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.description != null)
                        Text(
                          product.description!,
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppColors.mutedStrong,
                          ),
                        ),
                      if (product.features.isNotEmpty) ...[
                        SizedBox(height: AppSpacing.m),
                        for (final feature in product.features) ...[
                          _FeatureRow(feature: feature),
                          SizedBox(height: AppSpacing.xs),
                        ],
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A titled block with the design's hairline rule above it.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(top: AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          SizedBox(height: AppSpacing.m),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedStrong),
              ),
              ?trailing,
            ],
          ),
          SizedBox(height: AppSpacing.m),
          child,
        ],
      ),
    );
  }
}

class _SizeSelector extends StatelessWidget {
  const _SizeSelector({
    required this.sizes,
    required this.selected,
    required this.onSelected,
  });

  final List<String> sizes;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    // The chips share the row rather than each taking the design's fixed 78pt.
    // Four fixed chips plus their gaps come to 348pt, which fits the design's
    // 350 by two pixels and wrapped to a second line at our page padding — the
    // same knife-edge the product card and the OTP row both sat on. Sharing the
    // width keeps one row at any screen size.
    return Row(
      children: [
        for (final size in sizes) ...[
          Expanded(
            child: _SizeChip(
              size: size,
              selected: size == selected,
              onTap: () => onSelected(size),
            ),
          ),
          if (size != sizes.last) SizedBox(width: AppSpacing.s),
        ],
      ],
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({
    required this.size,
    required this.selected,
    required this.onTap,
  });

  final String size;
  final bool selected;
  final VoidCallback onTap;

  /// The design's 46pt height. The width now comes from the row, so the chips
  /// stay on one line whatever the screen gives them.
  static const double _height = 46;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.primaryText : AppColors.secondary,
        borderRadius: BorderRadius.circular(AppRadius.s),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: _height,
            child: Center(
              child: Text(
                size,
                // direction-fixed: size codes are Latin in every locale
                textDirection: TextDirection.ltr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: selected ? AppColors.background : AppColors.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});

  final ProductFeature feature;

  /// The catalogue names the kind; this maps it to a glyph. An unknown kind
  /// falls back to a plain marker rather than rendering nothing.
  IconData get _icon => switch (feature.icon) {
    'fabric' => Icons.texture_outlined,
    'fit' => Icons.straighten_outlined,
    'care' => Icons.dry_cleaning_outlined,
    _ => Icons.check_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          _icon,
          size: AppFontSize.l,
          color: AppColors.mutedStrong,
          semanticLabel: '',
        ),
        SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            feature.text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedStrong),
          ),
        ),
      ],
    );
  }
}

/// The sticky bar: add to cart, and how many.
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.state});

  final ProductDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<ProductDetailBloc>();

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: BorderDirectional(top: BorderSide(color: AppColors.secondary)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsetsDirectional.all(AppSpacing.m),
          // Stepper first, button second. The design puts the stepper against
          // the right edge of an Arabic screen — the start side — and the
          // button after it. Ordering the button first mirrored the bar the
          // wrong way round.
          child: Row(
            children: [
              QuantityStepper(
                value: state.quantity,
                min: 1,
                max: ProductDetailBloc.maxQuantity,
                onChanged: (value) =>
                    bloc.add(ProductDetailQuantityChanged(value)),
              ),
              SizedBox(width: AppSpacing.m),
              Expanded(
                child: FilledButton(
                  // The whole selection travels to the cart as values. The cart
                  // never reads ProductDetailBloc — this bloc is a factory that
                  // dies with the screen, and the cart has to outlive it.
                  //
                  // Also gated on isSelectionComplete now that the button has a
                  // consequence: the bloc preselects a colour and a size, so it
                  // is a backstop rather than a state anyone reaches, but adding
                  // a sized garment with no size would be a real defect.
                  onPressed:
                      state.product.isSoldOut || !state.isSelectionComplete
                      ? null
                      : () {
                          context.read<CartBloc>().add(
                            CartItemAdded(
                              product: state.product,
                              colourId: state.selectedColourId,
                              size: state.selectedSize,
                              quantity: state.quantity,
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.productAddedToCart),
                              action: SnackBarAction(
                                label: l10n.cartViewCart,
                                // The snack bar outlives the screen: the action
                                // can be tapped after this route has been
                                // popped, and navigating from a defunct element
                                // throws. Resolved at tap time, not in build,
                                // so the screen still renders without a router
                                // above it.
                                onPressed: () {
                                  if (context.mounted) {
                                    context.go(Routes.cartPath);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                  child: Text(l10n.productAddToCart),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
