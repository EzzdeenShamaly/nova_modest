import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';
import 'package:nova_modest/features/address/presentation/bloc/address_form_bloc.dart';
import 'package:nova_modest/features/address/presentation/bloc/address_list_bloc.dart';
import 'package:nova_modest/features/address/presentation/widgets/address_form.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// Hosts [AddressForm] on a page of its own, for the account section.
///
/// Checkout will host the same widget inline instead of pushing this screen —
/// which is why the form is a widget and this is only one of its two homes.
///
/// The address being edited is looked up from [AddressListBloc], which the
/// pushed route still sits under: a second fetch for a row the list already
/// holds would be a second source of truth for it.
class AddressFormScreen extends StatelessWidget {
  const AddressFormScreen({this.addressId, super.key});

  /// Null when adding.
  final String? addressId;

  @override
  Widget build(BuildContext context) {
    final existing = switch (context.watch<AddressListBloc>().state) {
      AddressListLoaded(:final addresses) =>
        addresses.where((address) => address.id == addressId).firstOrNull,
      _ => null,
    };

    return BlocProvider<AddressFormBloc>(
      create: (_) => sl<AddressFormBloc>(),
      child: _AddressFormView(initial: existing, isEditing: addressId != null),
    );
  }
}

class _AddressFormView extends StatefulWidget {
  const _AddressFormView({required this.initial, required this.isEditing});

  final Address? initial;
  final bool isEditing;

  @override
  State<_AddressFormView> createState() => _AddressFormViewState();
}

class _AddressFormViewState extends State<_AddressFormView> {
  final _formKey = GlobalKey<AddressFormFieldsState>();
  bool _isDirty = false;

  /// Confirms before throwing away a part-typed address.
  Future<bool> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context);

    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(l10n.personalInfoDiscardTitle),
        content: Text(l10n.personalInfoDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.personalInfoDiscard,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<AddressFormBloc, AddressFormState>(
      listener: (context, state) {
        switch (state) {
          case AddressFormSucceeded():
            // The list bloc is above this route, so it takes the saved list
            // rather than re-reading what it has just been handed.
            context.read<AddressListBloc>().add(const AddressesRequested());
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.addressSaved)));
            Navigator.of(context).pop();
          case AddressFormFailureState(:final failure):
            // A snack bar, not a FailureView: eight fields of typing are still
            // on screen and still correct.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failureMessage(failure, l10n))),
            );
          case AddressFormIdle() || AddressFormSubmitting():
            break;
        }
      },
      builder: (context, state) {
        final busy = state.isSubmitting;

        return PopScope<Object?>(
          canPop: !_isDirty,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            if (await _confirmDiscard() && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: Text(
                widget.isEditing ? l10n.addressEdit : l10n.addressAdd,
              ),
            ),
            body: SingleChildScrollView(
              padding: EdgeInsetsDirectional.all(AppSpacing.l),
              child: AddressForm(
                key: _formKey,
                initial: widget.initial,
                enabled: !busy,
                onDirtyChanged: (dirty) {
                  if (dirty != _isDirty) setState(() => _isDirty = dirty);
                },
                onSubmit: (address) => context.read<AddressFormBloc>().add(
                  AddressFormSubmitted(address),
                ),
              ),
            ),
            bottomNavigationBar: _SaveBar(
              onSave: busy ? null : () => _formKey.currentState?.submit(),
              busy: busy,
            ),
          ),
        );
      },
    );
  }
}

/// The sticky bar: one action, to save.
class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.onSave, required this.busy});

  final VoidCallback? onSave;
  final bool busy;

  /// Matches the spinner the other submit buttons use.
  static const double _spinner = 20;
  static const double _spinnerStroke = 2;

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
            onPressed: onSave,
            icon: busy
                ? const SizedBox.square(
                    dimension: _spinner,
                    child: CircularProgressIndicator(
                      strokeWidth: _spinnerStroke,
                    ),
                  )
                : const Icon(Icons.check),
            label: Text(l10n.addressSave),
          ),
        ),
      ),
    );
  }
}
