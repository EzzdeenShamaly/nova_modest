import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nova_modest/features/auth/presentation/bloc/sign_in_bloc.dart';
import 'package:nova_modest/l10n/app_localizations.dart';
import 'package:nova_modest/router/routes.dart';

/// How to sign in: Google, or a one-time code emailed to you.
///
/// There is no password field and no "forgot password" — the product has no
/// passwords, so neither exists anywhere in the flow.
///
/// Built from Figma frame `1:2247`.
class AuthMethodScreen extends StatelessWidget {
  const AuthMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignInBloc>(
      create: (_) => sl<SignInBloc>(),
      child: const _AuthMethodView(),
    );
  }
}

class _AuthMethodView extends StatefulWidget {
  const _AuthMethodView();

  @override
  State<_AuthMethodView> createState() => _AuthMethodViewState();
}

class _AuthMethodViewState extends State<_AuthMethodView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submitEmail() {
    if (!_formKey.currentState!.validate()) return;
    context.read<SignInBloc>().add(
      SignInEmailSubmitted(_emailController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<SignInBloc, SignInState>(
          listener: (context, state) {
            switch (state) {
              // The flow bloc finished; the session belongs to AuthBloc, and the
              // router's guard is what actually navigates.
              case SignInSucceeded(:final user):
                context.read<AuthBloc>().add(AuthSessionEstablished(user));
              case SignInCodeSent(:final email):
                context.goNamed(
                  Routes.verifyEmailName,
                  queryParameters: {Routes.emailQueryParam: email},
                );
              case SignInIdle() || SignInSubmitting() || SignInFailureState():
                break;
            }
          },
          builder: (context, state) {
            if (state is SignInFailureState) {
              return FailureView(
                failure: state.failure,
                onRetry: () => context.read<SignInBloc>().add(
                  const SignInGoogleRequested(),
                ),
              );
            }

            final busy = state is SignInSubmitting;

            return SingleChildScrollView(
              padding: EdgeInsetsDirectional.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.authMethodTitle,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineLarge,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.authMethodSubtitle,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      // The design's #444748, derived from the palette rather
                      // than added to it.
                      color: AppColors.mutedStrong,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  _GoogleButton(
                    label: l10n.authContinueWithGoogle,
                    onPressed: busy
                        ? null
                        : () => context.read<SignInBloc>().add(
                            const SignInGoogleRequested(),
                          ),
                  ),
                  SizedBox(height: AppSpacing.l),
                  _OrDivider(label: l10n.authOr),
                  SizedBox(height: AppSpacing.l),
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _emailController,
                      enabled: !busy,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      // direction-fixed: email addresses are LTR in every locale
                      textDirection: TextDirection.ltr,
                      onFieldSubmitted: (_) => _submitEmail(),
                      decoration: InputDecoration(
                        hintText: l10n.emailLabel,
                        fillColor: AppColors.secondary,
                      ),
                      validator: (value) => _validateEmail(value, l10n),
                    ),
                  ),
                  SizedBox(height: AppSpacing.l),
                  FilledButton(
                    onPressed: busy ? null : _submitEmail,
                    child: busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.authContinueWithEmail),
                  ),
                  SizedBox(height: AppSpacing.l),
                  TextButton(
                    // Browsing is public, so "continue as guest" is simply Home.
                    onPressed: busy ? null : () => context.go(Routes.homePath),
                    child: Text(l10n.authContinueAsGuest),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String? _validateEmail(String? value, AppLocalizations l10n) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return l10n.emailRequired;
    // Deliberately permissive: rejecting an address the backend would accept is
    // a worse failure than accepting one it rejects.
    if (!email.contains('@') || email.startsWith('@') || email.endsWith('@')) {
      return l10n.emailInvalid;
    }
    return null;
  }
}

/// The Google button: bordered, with the official brand mark.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  /// The exported mark is square and sits beside the label at text height.
  static const double _markSize = 20;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.background,
        side: BorderSide(
          // The design's #635E54 — the same derivation the splash tagline uses.
          color: AppColors.muted,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/auth/google.png',
            width: _markSize,
            height: _markSize,
            // The label names the provider, so the mark is decorative.
            excludeFromSemantics: true,
          ),
          SizedBox(width: AppSpacing.xs),
          // Flexible, not a bare Text: the label is translated, and a longer
          // rendering than the Arabic one must shrink rather than overflow the
          // button.
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

/// A rule either side of a single word.
class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(child: Divider(color: AppColors.muted));

    return Row(
      children: [
        line,
        Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.m),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedStrong),
          ),
        ),
        line,
      ],
    );
  }
}
