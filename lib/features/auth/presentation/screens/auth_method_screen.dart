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

/// How to sign in: a one-time code emailed to you.
///
/// There is no password field and no "forgot password" — the product has no
/// passwords, so neither exists anywhere in the flow.
///
/// The frame also draws a Google button. It was built, and removed on
/// 2026-09-21 because it could not work in any build this repo produces; see
/// the note at its former place in the column.
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
                // Back to the form. Re-dispatching the request that just
                // failed would repeat it with the same inputs; what the shopper
                // needs is her address field again.
                onRetry: () =>
                    context.read<SignInBloc>().add(const SignInDismissed()),
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
                  // **The Google button was here, and was removed on
                  // 2026-09-21.** It could not work in any build this repo
                  // produces: `GOOGLE_WEB_CLIENT_ID` is defined in no config
                  // file, so the call returned a server failure before the
                  // plugin was reached, and the native setup and the provider
                  // were missing behind that. A control that looks live and
                  // ends in a technical error is worse than one that is not
                  // there — the same call made for the dead heart and share
                  // icons. The Dart path behind it is intact and reachable
                  // again the day the three layers in `progress.md`
                  // (blocker 6) are settled; only this control is gone.
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
