import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// One saved address, from Figma frame `1:1767`.
///
/// Draws [Address.postalLines] rather than assembling the block itself: which
/// fields appear and in what order is a rule about the data, and checkout reads
/// the same entity through its own — shorter — formatter.
class AddressCard extends StatelessWidget {
  const AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
    super.key,
  });

  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Null on the address that already is the default — there is nothing to set.
  final VoidCallback? onSetDefault;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.hairline,
        borderRadius: BorderRadius.circular(AppRadius.s),
        border: Border.fromBorderSide(
          BorderSide(
            // The default is the one the shopper acts on most, so it carries
            // the accent edge the design gives a chosen card.
            color: address.isDefault ? AppColors.accent : AppColors.secondary,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _icon,
                  size: AppFontSize.l,
                  color: AppColors.muted,
                  semanticLabel: '',
                ),
                SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    address.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium,
                  ),
                ),
                if (address.isDefault) ...[
                  SizedBox(width: AppSpacing.xs),
                  const _DefaultBadge(),
                ],
                const Spacer(),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  iconSize: AppFontSize.l,
                  color: AppColors.muted,
                  tooltip: l10n.addressEdit,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  iconSize: AppFontSize.l,
                  color: AppColors.muted,
                  tooltip: l10n.addressDelete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xs),
            for (final line in address.postalLines)
              Text(
                line,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedStrong,
                ),
              ),
            // Offered only where it can do something. On the default itself the
            // control would be a no-op dressed as an action.
            if (onSetDefault case final setDefault?) ...[
              SizedBox(height: AppSpacing.xs),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: setDefault,
                  child: Text(l10n.addressSetDefault),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// The glyph comes from [Address.kind], never from the label: a shopper who
  /// names an address "بيت أمي" still gets a house.
  IconData get _icon => switch (address.kind) {
    AddressKind.home => Icons.home_outlined,
    AddressKind.work => Icons.work_outline,
    AddressKind.other => Icons.location_on_outlined,
  };
}

class _DefaultBadge extends StatelessWidget {
  const _DefaultBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      // Not const: AppRadius.pill is a getter, because the scales resolve
      // through screenutil at call time.
      decoration: BoxDecoration(
        color: AppColors.primaryText,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          AppLocalizations.of(context).addressDefaultBadge,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.background),
        ),
      ),
    );
  }
}
