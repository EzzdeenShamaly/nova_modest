import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/features/checkout/domain/entities/contact_details.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// Checkout step 1, from Figma `1:2163`: a name and a phone number.
///
/// A **widget, not a screen** — the checkout host owns the app bar, the
/// indicator and the sticky "next" bar, and every step slots into the same
/// frame. Its host submits it through a `GlobalKey<ContactStepState>`, the same
/// arrangement `AddressForm` uses.
class ContactStep extends StatefulWidget {
  const ContactStep({required this.initial, required this.onSubmit, super.key});

  /// Pre-filled from the account, or empty for a guest. Either way editable —
  /// a shopper may be buying for someone else.
  final ContactDetails initial;

  final ValueChanged<ContactDetails> onSubmit;

  @override
  State<ContactStep> createState() => ContactStepState();
}

class ContactStepState extends State<ContactStep> {
  final _formKey = GlobalKey<FormState>();
  final _nameKey = GlobalKey<FormFieldState<String>>();
  final _phoneKey = GlobalKey<FormFieldState<String>>();

  late final TextEditingController _name = TextEditingController(
    text: widget.initial.fullName,
  );
  late final TextEditingController _phone = TextEditingController(
    text: _withoutDiallingCode(widget.initial.phone),
  );

  /// The last values **this widget** put in the fields.
  ///
  /// A field still holding its seed has not been typed in; one that differs
  /// has. That is the whole "did the shopper touch it" test, and it needs no
  /// focus or change listeners to answer.
  ///
  /// Assigned in [initState], **not** by a `late` initialiser: a `late` field
  /// runs its initialiser on first *read*, and the first read is inside
  /// [didUpdateWidget] — where `widget` is already the new one. The seed would
  /// then record a value the field never held, every comparison would fail, and
  /// the re-seed this exists for would never fire. It did not, until a test
  /// said so.
  late String _seededName;
  late String _seededPhone;

  bool _autovalidate = false;

  /// The only dialling code the shop takes orders on today.
  ///
  /// A list rather than a constant so the control is the design's chevron and a
  /// second code is one entry — but not an invented world list either. The
  /// frame shows `+970`, which is the odd one out: every other number in the
  /// file, and the seeded account, are `+966`.
  static const List<String> _diallingCodes = ['+966'];

  /// Fixed while there is one code. It becomes state again the day a
  /// selector returns.
  final String _code = _diallingCodes.first;

  @override
  void initState() {
    super.initState();
    // Reading the controllers is also what forces them to build from the
    // original `widget.initial`.
    _seededName = _name.text;
    _seededPhone = _phone.text;
  }

  /// Re-seeds the fields when the account details arrive after the first frame.
  ///
  /// They always do. `BlocProvider` adds `CheckoutStarted` when it creates the
  /// bloc, and a bloc handles an event one microtask later — so the first frame
  /// renders `CheckoutInProgress()` with an empty draft, this widget's
  /// controllers are built from that, and the seeded state that follows rebuilt
  /// the widget without touching the `State` the controllers live in. A signed-
  /// in shopper saw an empty form, and only a test that went through the real
  /// router could see it: a screen test pumps an already-seeded state, so the
  /// first frame it renders is the seeded one.
  ///
  /// Fixed here rather than by keying the step off the draft: a key rebuilds
  /// the whole `State` to work around the staleness, while this updates the one
  /// thing that is stale, and cannot drop a caret mid-typing.
  ///
  /// **A field the shopper has already typed in is never overwritten.** They
  /// may be buying for someone else, which is why the frame lets these be
  /// edited at all.
  @override
  void didUpdateWidget(covariant ContactStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initial == oldWidget.initial) return;

    final name = widget.initial.fullName;
    if (_name.text == _seededName) _name.text = name;
    _seededName = name;

    final phone = _withoutDiallingCode(widget.initial.phone);
    if (_phone.text == _seededPhone) _phone.text = phone;
    _seededPhone = phone;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  /// Strips a known code off a stored number so it does not appear twice — once
  /// in the selector and once in the field.
  static String _withoutDiallingCode(String phone) {
    final trimmed = phone.trim();
    for (final code in _diallingCodes) {
      if (trimmed.startsWith(code)) {
        return trimmed.substring(code.length).trim();
      }
    }
    return trimmed;
  }

  /// Validates and hands the result up. Returns false when the form is not
  /// valid, so the host can leave its own state alone.
  bool submit() {
    setState(() => _autovalidate = true);
    if (!(_formKey.currentState?.validate() ?? false)) {
      _revealFirstError();
      return false;
    }

    widget.onSubmit(
      ContactDetails(
        fullName: _name.text.trim(),
        phone: '$_code ${_phone.text.trim()}',
        // Carried through untouched: the frame has no email field, and for a
        // guest there is none to carry.
        email: widget.initial.email,
      ),
    );
    return true;
  }

  /// Scrolls to the first field in error. Two fields fit on any phone, so this
  /// rarely fires here — but the address form shipped without it and a save
  /// button that silently did nothing was the result.
  void _revealFirstError() {
    for (final key in [_nameKey, _phoneKey]) {
      if (key.currentState?.hasError ?? false) {
        final context = key.currentContext;
        if (context != null && Scrollable.maybeOf(context) != null) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: 0.2,
          );
        }
        return;
      }
    }
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
          _Field(
            label: l10n.checkoutFullName,
            child: TextFormField(
              key: _nameKey,
              controller: _name,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: InputDecoration(
                hintText: l10n.checkoutFullNameHint,
                fillColor: AppColors.secondary,
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.personalInfoNameRequired
                  : null,
            ),
          ),
          SizedBox(height: AppSpacing.l),
          _Field(
            label: l10n.personalInfoPhone,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3:1 rather than a pinned width for the code. A fixed 96pt
                // segment overflowed by 3pt at the design width — the same
                // knife-edge the size chips, the OTP row and the product card
                // each sat on. Sharing the row cannot overflow at any width.
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    key: _phoneKey,
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    // direction-fixed: a dialling number reads left to right in
                    // every locale
                    textDirection: TextDirection.ltr,
                    onFieldSubmitted: (_) => submit(),
                    decoration: InputDecoration(
                      hintText: l10n.checkoutPhoneHint,
                      fillColor: AppColors.secondary,
                    ),
                    validator: (value) => _validatePhone(value, l10n),
                  ),
                ),
                SizedBox(width: AppSpacing.xs),
                // Not Expanded: it sizes to the code it holds, and the number
                // field beside it absorbs everything else — so the row cannot
                // overflow at any width.
                _DiallingCode(value: _code),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Deliberately loose, like the profile and address forms: the dialling code
  /// is chosen separately, so this only checks that what is left is a number of
  /// plausible length.
  String? _validatePhone(String? value, AppLocalizations l10n) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return l10n.personalInfoNameRequired;

    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    final shaped = RegExp(r'^[0-9 ()-]+$').hasMatch(trimmed);
    return (shaped && digits.length >= _minPhoneDigits)
        ? null
        : l10n.personalInfoPhoneInvalid;
  }

  static const int _minPhoneDigits = 7;
}

/// A label above its field, as every form in this app draws it.
class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

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
          ).textTheme.labelMedium?.copyWith(color: AppColors.mutedStrong),
        ),
        SizedBox(height: AppSpacing.xxs),
        child,
      ],
    );
  }
}

/// The dialling code beside the number.
///
/// **Not a `DropdownButtonFormField`.** One was tried and removed: with a
/// single code there is nothing to choose, and Material's input decorator gave
/// its inner row a fixed 27.8pt whatever width the field was handed — 96, 112
/// and 200 all produced the same overflow, so the width was never the variable.
/// A control that cannot be used is not worth a layout fight.
///
/// A second code turns this back into a real selector; until then it states the
/// code the shop takes orders on and leaves the number field to do the work.
class _DiallingCode extends StatelessWidget {
  const _DiallingCode({required this.value});

  final String value;

  /// Matches the height of the field beside it, from the design's 48pt row.
  static const double _height = 48;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(AppRadius.s),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.s),
          child: Center(
            child: Text(
              value,
              // direction-fixed: a dialling code is written +966 in every
              // locale, never 966+
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ),
    );
  }
}
