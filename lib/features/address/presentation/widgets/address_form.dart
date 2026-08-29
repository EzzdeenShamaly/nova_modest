import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// The address form, from the card Figma draws inside `1:1944`.
///
/// A **widget, not a screen**, and that is the point: the account section hosts
/// it on a page of its own today, and the checkout step hosts it inline
/// tomorrow — which is exactly how the frame draws it, embedded in a longer
/// page rather than pushed.
///
/// It owns only what a form owns: the text being typed and whether it is valid.
/// Saving belongs to whoever hosts it, through [onSubmit].
class AddressForm extends StatefulWidget {
  const AddressForm({
    required this.onSubmit,
    required this.onDirtyChanged,
    this.initial,
    this.enabled = true,
    super.key,
  });

  /// The address being edited, or null for a new one.
  final Address? initial;

  /// Handed a complete [Address] once every field validates. Its id is empty
  /// for a new address and carries [initial]'s id for an edit, so the
  /// repository decides which without the host branching.
  final ValueChanged<Address> onSubmit;

  /// Reported so a host can guard a back gesture, or disable its own save
  /// button, without reaching into this widget's state.
  final ValueChanged<bool> onDirtyChanged;

  /// False while a save is in flight.
  final bool enabled;

  @override
  State<AddressForm> createState() => AddressFormFieldsState();
}

/// Public so a host holding a `GlobalKey<AddressFormFieldsState>` can ask the
/// form to submit from a button that lives outside it — the sticky bar on the
/// account screen, and checkout's own footer later.
///
/// Named for the fields rather than the widget: `AddressFormState` is already
/// the bloc state that saves what this collects, and the two would collide in
/// any file that used both — which the screen hosting this does.
class AddressFormFieldsState extends State<AddressForm> {
  final _formKey = GlobalKey<FormState>();

  late final Map<_Field, TextEditingController> _controllers = {
    for (final field in _Field.values)
      field: TextEditingController(text: field.readFrom(widget.initial)),
  };

  /// One key per field, so a failed submit can find the first field actually in
  /// error and scroll to it.
  final Map<_Field, GlobalKey<FormFieldState<String>>> _fieldKeys = {
    for (final field in _Field.values)
      field: GlobalKey<FormFieldState<String>>(),
  };

  /// Off until the first submit, then on: re-validating as the shopper types is
  /// help once they have been told something is wrong, and nagging before that.
  bool _autovalidate = false;

  late AddressKind _kind = widget.initial?.kind ?? AddressKind.home;
  late String _country = widget.initial?.country ?? _shippingCountries.first;
  late bool _isDefault = widget.initial?.isDefault ?? false;

  /// The only country the shop ships to today.
  ///
  /// A list rather than a constant so the control is the design's dropdown and
  /// adding a second country is one entry — but not an invented world list
  /// either: the backend will supply this.
  static const List<String> _shippingCountries = ['المملكة العربية السعودية'];

  /// The design's 104pt textarea, three lines of the body style.
  static const int _streetLines = 3;

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers.values) {
      controller.addListener(_reportDirty);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller
        ..removeListener(_reportDirty)
        ..dispose();
    }
    super.dispose();
  }

  void _reportDirty() => widget.onDirtyChanged(isDirty);

  /// Whether anything differs from the address this form opened with.
  bool get isDirty => _build() != (widget.initial ?? _emptyDraft);

  /// Validates and hands the result to the host. Returns false if the form is
  /// not valid, so a host can leave its own state alone.
  bool submit() {
    setState(() => _autovalidate = true);

    if (!(_formKey.currentState?.validate() ?? false)) {
      // The form is taller than the viewport, so the field that failed is
      // usually off-screen — and `Form.validate()` does not move to it. Without
      // this the save button reads as doing nothing at all, which is exactly
      // how the defect was reported.
      _revealFirstError();
      return false;
    }

    widget.onSubmit(_build());
    return true;
  }

  /// Scrolls to the first field in error, in the order they are laid out.
  void _revealFirstError() {
    for (final field in _Field.values) {
      final key = _fieldKeys[field]!;
      if (key.currentState?.hasError ?? false) {
        final context = key.currentContext;
        // Null when no host has put this form in a scrollable — the checkout
        // page might not — in which case there is nothing to scroll and the
        // error is already on screen.
        if (context != null && Scrollable.maybeOf(context) != null) {
          Scrollable.ensureVisible(
            context,
            duration: _revealDuration,
            curve: Curves.easeOut,
            // A little above the bottom edge, so the message under the field is
            // in view too rather than flush against it.
            alignment: 0.2,
          );
        }
        return;
      }
    }
  }

  /// Long enough to read as movement rather than a jump.
  static const Duration _revealDuration = Duration(milliseconds: 300);

  Address get _emptyDraft => Address(
    id: '',
    kind: AddressKind.home,
    label: '',
    recipientName: '',
    phone: '',
    country: _shippingCountries.first,
    region: '',
    city: '',
    street: '',
  );

  Address _build() {
    String value(_Field field) => _controllers[field]!.text.trim();
    String? optional(_Field field) {
      final text = value(field);
      return text.isEmpty ? null : text;
    }

    return Address(
      id: widget.initial?.id ?? '',
      kind: _kind,
      label: value(_Field.label),
      recipientName: value(_Field.recipient),
      phone: value(_Field.phone),
      country: _country,
      region: value(_Field.region),
      city: value(_Field.city),
      street: value(_Field.street),
      postalCode: optional(_Field.postalCode),
      notes: optional(_Field.notes),
      isDefault: _isDefault,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Form(
      key: _formKey,
      autovalidateMode: _autovalidate
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KindSelector(
            selected: _kind,
            enabled: widget.enabled,
            onChanged: (kind) => setState(() => _kind = kind),
          ),
          SizedBox(height: AppSpacing.m),
          _text(_Field.label, l10n.addressLabelField, l10n, required: true),
          SizedBox(height: AppSpacing.m),
          _text(_Field.recipient, l10n.addressRecipient, l10n, required: true),
          SizedBox(height: AppSpacing.m),
          _text(
            _Field.phone,
            l10n.personalInfoPhone,
            l10n,
            required: true,
            keyboard: TextInputType.phone,
            // direction-fixed: a dialling number reads left to right in every
            // locale, country code first
            direction: TextDirection.ltr,
            validator: (value) => _validatePhone(value, l10n),
          ),
          SizedBox(height: AppSpacing.m),
          _LabelledField(
            label: l10n.addressCountry,
            child: DropdownButtonFormField<String>(
              initialValue: _country,
              // The dropdown the design draws. One entry today; the backend
              // will supply the rest.
              items: [
                for (final country in _shippingCountries)
                  DropdownMenuItem<String>(
                    value: country,
                    child: Text(country),
                  ),
              ],
              onChanged: widget.enabled
                  ? (value) => setState(() => _country = value ?? _country)
                  : null,
              decoration: const InputDecoration(fillColor: AppColors.secondary),
            ),
          ),
          SizedBox(height: AppSpacing.m),
          // The design pairs these on one line, and they are the two halves of
          // one answer.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _text(
                  _Field.region,
                  l10n.addressRegion,
                  l10n,
                  required: true,
                ),
              ),
              SizedBox(width: AppSpacing.m),
              Expanded(
                child: _text(
                  _Field.city,
                  l10n.addressCity,
                  l10n,
                  required: true,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.m),
          _text(
            _Field.postalCode,
            l10n.addressPostalCode,
            l10n,
            keyboard: TextInputType.number,
          ),
          SizedBox(height: AppSpacing.m),
          _text(
            _Field.street,
            l10n.addressStreet,
            l10n,
            required: true,
            hint: l10n.addressStreetHint,
            lines: _streetLines,
          ),
          SizedBox(height: AppSpacing.m),
          _text(
            _Field.notes,
            l10n.addressNotes,
            l10n,
            hint: l10n.addressNotesHint,
          ),
          SizedBox(height: AppSpacing.s),
          SwitchListTile(
            value: _isDefault,
            onChanged: widget.enabled
                ? (value) => setState(() => _isDefault = value)
                : null,
            title: Text(
              l10n.addressMakeDefault,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            // Colours come from the theme's switchTheme, not from here.
            contentPadding: EdgeInsetsDirectional.zero,
            dense: true,
          ),
        ],
      ),
    );
  }

  Widget _text(
    _Field field,
    String label,
    AppLocalizations l10n, {
    bool required = false,
    String? hint,
    int lines = 1,
    TextInputType? keyboard,
    TextDirection? direction,
    FormFieldValidator<String>? validator,
  }) {
    return _LabelledField(
      label: label,
      child: TextFormField(
        key: _fieldKeys[field],
        controller: _controllers[field],
        enabled: widget.enabled,
        maxLines: lines,
        keyboardType: keyboard,
        textDirection: direction,
        textInputAction: lines > 1
            ? TextInputAction.newline
            : TextInputAction.next,
        decoration: InputDecoration(
          hintText: hint,
          fillColor: AppColors.secondary,
        ),
        validator:
            validator ??
            (value) => (required && (value == null || value.trim().isEmpty))
                ? l10n.addressFieldRequired
                : null,
      ),
    );
  }

  /// The same loose rule the profile form uses: no country format was
  /// specified, and an E.164 pattern would turn away valid local numbers.
  String? _validatePhone(String? value, AppLocalizations l10n) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return l10n.addressFieldRequired;

    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    final shaped = RegExp(r'^\+?[0-9 ()-]+$').hasMatch(trimmed);
    return (shaped && digits.length >= _minPhoneDigits)
        ? null
        : l10n.personalInfoPhoneInvalid;
  }

  static const int _minPhoneDigits = 7;
}

/// The form's text fields, and where each reads its initial value from.
enum _Field {
  label,
  recipient,
  phone,
  region,
  city,
  postalCode,
  street,
  notes;

  String readFrom(Address? address) => switch (this) {
    _Field.label => address?.label ?? '',
    _Field.recipient => address?.recipientName ?? '',
    _Field.phone => address?.phone ?? '',
    _Field.region => address?.region ?? '',
    _Field.city => address?.city ?? '',
    _Field.postalCode => address?.postalCode ?? '',
    _Field.street => address?.street ?? '',
    _Field.notes => address?.notes ?? '',
  };
}

/// A label above its field, as both form frames draw it.
class _LabelledField extends StatelessWidget {
  const _LabelledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
        SizedBox(height: AppSpacing.xxs),
        child,
      ],
    );
  }
}

/// Home / work / other, which picks the card's glyph.
class _KindSelector extends StatelessWidget {
  const _KindSelector({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final AddressKind selected;
  final bool enabled;
  final ValueChanged<AddressKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return _LabelledField(
      label: l10n.addressKind,
      child: Wrap(
        spacing: AppSpacing.xs,
        children: [
          for (final kind in AddressKind.values)
            ChoiceChip(
              selected: kind == selected,
              onSelected: enabled ? (_) => onChanged(kind) : null,
              label: Text(switch (kind) {
                AddressKind.home => l10n.addressKindHome,
                AddressKind.work => l10n.addressKindWork,
                AddressKind.other => l10n.addressKindOther,
              }),
            ),
        ],
      ),
    );
  }
}
