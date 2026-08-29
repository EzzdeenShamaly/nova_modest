import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:nova_modest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nova_modest/features/auth/presentation/bloc/profile_edit_bloc.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// Name, email and phone, from Figma frame `1:1593`.
///
/// Reached from the account menu, and the first **writing** screen in the app:
/// everything before it either read or held state locally.
///
/// The user comes from [AuthBloc], which already owns the session; the save
/// goes through [ProfileEditBloc], which reports the result back to `AuthBloc`
/// with `AuthProfileUpdated`. That is the same path `SignInBloc` takes, and it
/// keeps a transient "saving" state out of an app-wide singleton.
class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = switch (context.watch<AuthBloc>().state) {
      AuthAuthenticated(:final user) => user,
      _ => null,
    };

    return BlocProvider<ProfileEditBloc>(
      create: (_) => sl<ProfileEditBloc>(),
      // Behind the sign-in gate there is always a user; the branch exists for
      // the instant after a sign-out, before the router moves them on.
      child: user == null
          ? const Scaffold(body: SizedBox.shrink())
          : _PersonalInfoView(user: user),
    );
  }
}

class _PersonalInfoView extends StatefulWidget {
  const _PersonalInfoView({required this.user});

  final User user;

  @override
  State<_PersonalInfoView> createState() => _PersonalInfoViewState();
}

class _PersonalInfoViewState extends State<_PersonalInfoView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.user.displayName,
  );
  late final TextEditingController _phone = TextEditingController(
    text: widget.user.phone ?? '',
  );

  @override
  void initState() {
    super.initState();
    // Rebuilds the save button as the fields change, so "nothing to save" is
    // visible rather than something the shopper discovers by tapping.
    _name.addListener(_onChanged);
    _phone.addListener(_onChanged);
  }

  @override
  void dispose() {
    _name
      ..removeListener(_onChanged)
      ..dispose();
    _phone
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  /// Whether anything differs from the user this screen opened with.
  bool get _isDirty =>
      _name.text.trim() != widget.user.displayName ||
      _phoneValue != widget.user.phone;

  /// An emptied field means "no number", not "unchanged".
  String? get _phoneValue {
    final trimmed = _phone.text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ProfileEditBloc>().add(
      ProfileEditSubmitted(displayName: _name.text.trim(), phone: _phoneValue),
    );
  }

  /// Confirms before throwing away edits.
  ///
  /// The frame has no dialog; a form that loses what was typed to one back
  /// gesture is worse than the extra tap.
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
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<ProfileEditBloc, ProfileEditState>(
      listener: (context, state) {
        switch (state) {
          case ProfileEditSucceeded(:final user):
            // The session's user is AuthBloc's to own; this screen reports the
            // outcome rather than holding a second copy.
            context.read<AuthBloc>().add(AuthProfileUpdated(user));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.personalInfoSaved)));
            Navigator.of(context).pop();
          case ProfileEditFailureState(:final failure):
            // A snack bar, not a FailureView: what the shopper typed is still
            // on screen and still correct, so replacing the form would throw
            // their work away to report a transient problem.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failureMessage(failure, l10n))),
            );
          case ProfileEditIdle() || ProfileEditSubmitting():
            break;
        }
      },
      builder: (context, state) {
        final busy = state.isSubmitting;

        // Explicitly typed: an untyped PopScope is PopScope<dynamic>, which a
        // test cannot name to read `canPop` off.
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
                l10n.brandName,
                // direction-fixed: a brandmark's glyph order is fixed by the
                // mark itself, not by the reader's language
                textDirection: TextDirection.ltr,
                style: textTheme.headlineLarge,
              ),
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsetsDirectional.all(AppSpacing.l),
                children: [
                  Text(
                    l10n.profilePersonalInfo,
                    style: textTheme.headlineLarge,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.personalInfoSubtitle,
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  _Field(
                    label: l10n.personalInfoFullName,
                    child: TextFormField(
                      controller: _name,
                      enabled: !busy,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        fillColor: AppColors.secondary,
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? l10n.personalInfoNameRequired
                          : null,
                    ),
                  ),
                  SizedBox(height: AppSpacing.l),
                  _Field(
                    label: l10n.emailLabel,
                    muted: true,
                    note: l10n.personalInfoEmailLocked,
                    child: TextFormField(
                      initialValue: widget.user.email,
                      // Not merely disabled here: `updateProfile` has no email
                      // parameter, so no screen can express the change.
                      enabled: false,
                      // direction-fixed: email addresses are LTR in every locale
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        fillColor: AppColors.secondary,
                        suffixIcon: Icon(
                          Icons.lock_outline,
                          size: AppFontSize.l,
                          color: AppColors.muted,
                          semanticLabel: '',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.l),
                  _Field(
                    label: l10n.personalInfoPhone,
                    child: TextFormField(
                      controller: _phone,
                      enabled: !busy,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      // direction-fixed: a dialling number reads left to right
                      // in every locale, country code first
                      textDirection: TextDirection.ltr,
                      onFieldSubmitted: (_) => _save(),
                      decoration: const InputDecoration(
                        fillColor: AppColors.secondary,
                      ),
                      validator: (value) => _validatePhone(value, l10n),
                    ),
                  ),
                ],
              ),
            ),
            // bottomNavigationBar is the slot that pins: the bar stays put
            // while the form scrolls.
            bottomNavigationBar: _SaveBar(
              // Disabled until something actually differs, so the control
              // reports the state rather than restating it.
              onSave: busy || !_isDirty ? null : _save,
              busy: busy,
            ),
          ),
        );
      },
    );
  }

  /// Optional, and deliberately loose.
  ///
  /// No country format was specified, so this rejects what is obviously not a
  /// number rather than inventing an E.164 rule that would turn away valid
  /// local ones.
  String? _validatePhone(String? value, AppLocalizations l10n) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;

    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    final shaped = RegExp(r'^\+?[0-9 ()-]+$').hasMatch(trimmed);
    return (shaped && digits.length >= _minPhoneDigits)
        ? null
        : l10n.personalInfoPhoneInvalid;
  }

  /// Short enough to admit a local number, long enough to reject a typo.
  static const int _minPhoneDigits = 7;
}

/// A label, the field, and an optional note beneath it.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.child,
    this.note,
    this.muted = false,
  });

  final String label;
  final Widget child;

  /// Shown under the field. The design uses it once, to say the email is fixed.
  final String? note;

  /// The design fades the label of the field that cannot be edited.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: muted ? AppColors.muted : AppColors.primaryText,
          ),
        ),
        SizedBox(height: AppSpacing.xxs),
        child,
        if (note case final text?) ...[
          SizedBox(height: AppSpacing.xxs),
          Text(
            text,
            style: textTheme.labelMedium?.copyWith(color: AppColors.muted),
          ),
        ],
      ],
    );
  }
}

/// The sticky bar: one action, to save.
class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.onSave, required this.busy});

  final VoidCallback? onSave;
  final bool busy;

  /// Matches the spinner the sign-in button uses while a request is in flight.
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
            label: Text(l10n.personalInfoSave),
          ),
        ),
      ),
    );
  }
}
