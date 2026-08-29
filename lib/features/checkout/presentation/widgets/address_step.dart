import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';
import 'package:nova_modest/features/address/presentation/bloc/address_form_bloc.dart';
import 'package:nova_modest/features/address/presentation/bloc/address_list_bloc.dart';
import 'package:nova_modest/features/address/presentation/widgets/address_form.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// Checkout step 2, from Figma `1:1944`: pick a saved address, or type a new
/// one.
///
/// **Reuses the address feature outright.** The saved list comes from
/// `AddressListBloc`, the form is `AddressForm`, the "exactly one default" rule
/// stays in `AddressRepository`, and a new address typed here lands in the
/// shopper's address book like any other. Nothing about an address is defined a
/// second time for checkout — which is why `Address` was built as its own
/// entity rather than a profile-screen type.
///
/// A **widget, not a screen**, like `ContactStep`: the checkout host owns the
/// app bar, the indicator and the sticky bar, and submits this through a
/// `GlobalKey<AddressStepState>`.
class AddressStep extends StatefulWidget {
  const AddressStep({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// What the draft already holds, when the shopper walks back into this step.
  final Address? selected;

  /// Handed the chosen address — picked or just saved. Either way it exists in
  /// the address book with a real id by the time this fires.
  final ValueChanged<Address> onSelected;

  @override
  State<AddressStep> createState() => AddressStepState();
}

/// Public so the checkout host's sticky bar can submit a form that lives
/// outside it — the same arrangement `AddressForm` and `ContactStep` use.
class AddressStepState extends State<AddressStep> {
  final _formKey = GlobalKey<AddressFormFieldsState>();

  /// Opened by the "add" button. Always effectively open when there is nothing
  /// saved to choose between.
  bool _formOpen = false;

  /// The card the shopper tapped, if any. Null means "whatever [_chosenFrom]
  /// works out" — the draft's address, or the default.
  String? _picked;

  /// The ids present when a save was dispatched, so the address that comes back
  /// unknown is the one just added.
  Set<String> _knownIds = const {};

  bool get _showingForm =>
      _formOpen || context.read<AddressListBloc>().state is AddressListEmpty;

  /// Advances the step, or starts a save that will.
  ///
  /// Returns false when nothing could be submitted, so the host leaves its own
  /// state alone — the same contract `AddressForm.submit` has.
  bool submit() {
    final state = context.read<AddressListBloc>().state;

    if (_showingForm) {
      _knownIds = switch (state) {
        AddressListLoaded(:final addresses) =>
          addresses.map((address) => address.id).toSet(),
        _ => const {},
      };
      // Saving is asynchronous; the step advances from the listener below, once
      // the address exists and has an id.
      return _formKey.currentState?.submit() ?? false;
    }

    final chosen = _chosenFrom(state);
    if (chosen == null) return false;

    widget.onSelected(chosen);
    return true;
  }

  /// Which address this step is offering, before the shopper touches anything.
  ///
  /// The draft's own address first, so walking back into this step shows what
  /// was already chosen; then the default, which the repository guarantees
  /// exactly one of.
  Address? _chosenFrom(AddressListState state) {
    if (state is! AddressListLoaded) return null;

    final id = _picked ?? widget.selected?.id;
    return state.addresses.where((address) => address.id == id).firstOrNull ??
        state.addresses.where((address) => address.isDefault).firstOrNull ??
        state.addresses.firstOrNull;
  }

  void _pick(Address address) => setState(() {
    _picked = address.id;
    // Tapping a saved card is a decision against the one being typed.
    _formOpen = false;
  });

  void _onSaved(List<Address> addresses) {
    // The list bloc is above this widget and still holds the pre-save list.
    context.read<AddressListBloc>().add(const AddressesRequested());

    final saved = addresses
        .where((address) => !_knownIds.contains(address.id))
        .firstOrNull;
    // Unreachable by the repository's contract — `save` mints an id for every
    // address whose own id is empty, and checkout only ever adds. Guarded
    // rather than asserted so a future repository cannot turn this into a
    // button that silently does nothing.
    if (saved == null) return;

    widget.onSelected(saved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocListener<AddressFormBloc, AddressFormState>(
      listener: (context, state) {
        switch (state) {
          case AddressFormSucceeded(:final addresses):
            _onSaved(addresses);
          case AddressFormFailureState(:final failure):
            // A snack bar rather than a FailureView: everything typed is still
            // on screen and still correct.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failureMessage(failure, l10n))),
            );
          case AddressFormIdle() || AddressFormSubmitting():
            break;
        }
      },
      child: BlocBuilder<AddressListBloc, AddressListState>(
        builder: (context, state) => switch (state) {
          AddressListInitial() || AddressListLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          AddressListError(:final failure) => FailureView(
            failure: failure,
            onRetry: () =>
                context.read<AddressListBloc>().add(const AddressesRequested()),
          ),
          // Nothing saved: the form, and only the form. An empty state in the
          // middle of a purchase is one more thing to get past before the step
          // can do what it is for.
          AddressListEmpty() => _Body(children: [_form(l10n)]),
          AddressListLoaded(:final addresses) => _Body(
            children: _saved(addresses, l10n),
          ),
        },
      ),
    );
  }

  List<Widget> _saved(List<Address> addresses, AppLocalizations l10n) {
    final chosenId = _chosenFrom(AddressListLoaded(addresses))?.id;

    return [
      Text(
        l10n.checkoutSavedAddresses,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      SizedBox(height: AppSpacing.m),
      for (final address in addresses) ...[
        _AddressChoiceCard(
          // Keyed by the address, so a refreshed list does not leave a card
          // inheriting its neighbour's position in the element tree.
          key: ValueKey<String>(address.id),
          address: address,
          selected: address.id == chosenId,
          onTap: () => _pick(address),
        ),
        SizedBox(height: AppSpacing.m),
      ],
      if (_formOpen)
        _form(l10n)
      else
        // The app's outlined style, not the frame's black border. The theme
        // already assigns that role to `secondary`, and one screen overriding
        // it is how a button style stops being shared.
        OutlinedButton.icon(
          onPressed: () => setState(() => _formOpen = true),
          icon: const Icon(Icons.add),
          label: Text(l10n.addressAdd),
        ),
    ];
  }

  Widget _form(AppLocalizations l10n) {
    // A Material, not a DecoratedBox: `AddressForm` contains a ListTile for the
    // default switch, and a coloured box between it and the nearest Material
    // swallows its ink — which Flutter asserts on rather than merely drawing
    // wrong.
    return Material(
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.secondary),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.checkoutNewAddress,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: AppSpacing.m),
            AddressForm(
              key: _formKey,
              onSubmit: (address) => context.read<AddressFormBloc>().add(
                AddressFormSubmitted(address),
              ),
              // Nothing here guards a back gesture: leaving checkout discards
              // the whole draft, not just this form.
              onDirtyChanged: (_) {},
              enabled: !context.watch<AddressFormBloc>().state.isSubmitting,
            ),
          ],
        ),
      ),
    );
  }
}

/// Scrolls in its own right, so the form has somewhere to scroll to when
/// `AddressForm`'s reveal finds a field below the fold — the defect that made
/// the account screen's save button look dead.
class _Body extends StatelessWidget {
  const _Body({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsetsDirectional.only(
        start: AppSpacing.l,
        end: AppSpacing.l,
        bottom: AppSpacing.l,
      ),
      children: children,
    );
  }
}

/// One saved address, as something to choose rather than something to manage.
///
/// Deliberately **not** `AddressCard`: that one draws the five-line postal block
/// with edit and delete beside it, which is the account screen's job. Here the
/// card is a radio button in a card's clothing, so it draws
/// `Address.shortSummary` and a tick.
class _AddressChoiceCard extends StatelessWidget {
  const _AddressChoiceCard({
    required this.address,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Address address;
  final bool selected;
  final VoidCallback onTap;

  /// The tick beside the chosen card, 20pt in the frame.
  static const double _tickSize = 20;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.m),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.m),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.secondary,
              ),
              borderRadius: BorderRadius.circular(AppRadius.m),
            ),
            padding: EdgeInsetsDirectional.all(AppSpacing.m),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(address.label, style: textTheme.titleMedium),
                      SizedBox(height: AppSpacing.xxs),
                      Text(
                        address.shortSummary,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.xs),
                // A second signal beside the border, because colour alone is
                // not an accessible way to say which one is chosen.
                if (selected)
                  const Icon(
                    Icons.check_circle,
                    size: _tickSize,
                    color: AppColors.accent,
                    // Announced by the Semantics above; reading it twice would
                    // be noise.
                    semanticLabel: '',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
