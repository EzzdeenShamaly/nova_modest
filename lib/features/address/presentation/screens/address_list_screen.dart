import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';
import 'package:nova_modest/features/address/presentation/bloc/address_list_bloc.dart';
import 'package:nova_modest/features/address/presentation/widgets/address_card.dart';
import 'package:nova_modest/l10n/app_localizations.dart';
import 'package:nova_modest/router/routes.dart';

/// The saved addresses, from Figma frame `1:1767`.
///
/// Reached from the account menu, and pushed inside the account branch so the
/// bottom bar stays and back returns to the menu.
///
/// **Does not provide its own [AddressListBloc].** The `ShellRoute` around this
/// route and the form's does, so both screens share one — a bloc created here
/// would not be an ancestor of the form, which is a child route rather than a
/// child widget.
class AddressListScreen extends StatelessWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      // The frame titles this one rather than showing the brandmark, so it
      // does; personal information shows the brand because its frame did.
      appBar: AppBar(centerTitle: true, title: Text(l10n.addressListTitle)),
      body: BlocBuilder<AddressListBloc, AddressListState>(
        builder: (context, state) => switch (state) {
          AddressListInitial() || AddressListLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          AddressListError(:final failure) => FailureView(
            failure: failure,
            onRetry: () =>
                context.read<AddressListBloc>().add(const AddressesRequested()),
          ),
          AddressListEmpty() => const _EmptyAddresses(),
          AddressListLoaded(:final addresses) => _List(addresses: addresses),
        },
      ),
      // bottomNavigationBar is the slot that pins. A solid bar with a top
      // rule, like the cart and the profile form — the frame fades the list
      // out behind a gradient instead, which no other screen here does.
      bottomNavigationBar: const _AddBar(),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.addresses});

  final List<Address> addresses;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AddressListBloc>();

    return ListView.separated(
      padding: EdgeInsetsDirectional.all(AppSpacing.l),
      itemCount: addresses.length,
      separatorBuilder: (context, index) => SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final address = addresses[index];
        return AddressCard(
          // Keyed by the address, so deleting one does not leave the next
          // inheriting its position in the list's element tree.
          key: ValueKey<String>(address.id),
          address: address,
          onEdit: () => context.push(Routes.addressEdit(address.id)),
          onDelete: () => _confirmDelete(context, bloc, address),
          onSetDefault: address.isDefault
              ? null
              : () => bloc.add(AddressDefaultSelected(address.id)),
        );
      },
    );
  }

  /// Asks before removing. An address takes eight fields to type back in.
  Future<void> _confirmDelete(
    BuildContext context,
    AddressListBloc bloc,
    Address address,
  ) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(l10n.addressDelete),
        content: Text(l10n.addressDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.addressDelete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed ?? false) bloc.add(AddressDeleted(address.id));
  }
}

class _EmptyAddresses extends StatelessWidget {
  const _EmptyAddresses();

  /// The illustration stands in for artwork that does not exist yet.
  static const double _iconSize = 72;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: EdgeInsetsDirectional.all(AppSpacing.l),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: _iconSize,
              color: AppColors.subtle,
              semanticLabel: '',
            ),
            SizedBox(height: AppSpacing.m),
            Text(l10n.addressEmpty, style: textTheme.headlineMedium),
            SizedBox(height: AppSpacing.xs),
            Text(
              l10n.addressEmptyBody,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The sticky bar: one action, to add.
///
/// Present in every state, including the empty one — the design's own frame has
/// no other way in, and an empty list with no way to fill it is a dead end.
class _AddBar extends StatelessWidget {
  const _AddBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: BorderDirectional(top: BorderSide(color: AppColors.secondary)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsetsDirectional.all(AppSpacing.m),
          child: FilledButton.icon(
            onPressed: () => context.push(Routes.addressNew),
            icon: const Icon(Icons.add),
            label: Text(l10n.addressAdd),
          ),
        ),
      ),
    );
  }
}
