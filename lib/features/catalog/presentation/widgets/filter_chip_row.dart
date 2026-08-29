import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';

/// One chip's data, whatever it happens to represent.
class FilterChipOption {
  const FilterChipOption({required this.id, required this.label});

  final String id;
  final String label;
}

/// A horizontal row of filter chips with a leading "All".
///
/// Serves both catalogue screens: Home filters by category, the listing filters
/// by tag. They looked slightly different in the design — the listing's chips
/// carried an outline Home's did not — and were unified here rather than shipped
/// as two components that drift.
///
/// Scrolls horizontally: chips are meant to run off the edge rather than wrap.
///
/// The leading "All" chip is a UI affordance with its own localized label, not a
/// row the backend returns — selecting it clears the filter.
class FilterChipRow extends StatelessWidget {
  const FilterChipRow({
    required this.options,
    required this.selectedId,
    required this.allLabel,
    required this.onSelected,
    super.key,
  });

  final List<FilterChipOption> options;

  /// `null` means the "All" chip is active.
  final String? selectedId;
  final String allLabel;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.l),
      child: Row(
        children: [
          _Chip(
            label: allLabel,
            selected: selectedId == null,
            onTap: () => onSelected(null),
          ),
          for (final option in options) ...[
            SizedBox(width: AppSpacing.xs),
            _Chip(
              label: option.label,
              selected: option.id == selectedId,
              onTap: () => onSelected(option.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.primaryText : AppColors.secondary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.l,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                // Selected inverts to the page colour; unselected is the
                // design's #686258, derived rather than added.
                color: selected ? AppColors.background : AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
