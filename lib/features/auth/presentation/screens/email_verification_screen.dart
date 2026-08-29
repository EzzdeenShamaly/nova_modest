import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nova_modest/features/auth/presentation/bloc/sign_in_bloc.dart';
import 'package:nova_modest/features/auth/presentation/widgets/otp_input.dart';
import 'package:nova_modest/l10n/app_localizations.dart';
import 'package:nova_modest/router/routes.dart';

/// Second step of the email path: enter the six-digit code.
///
/// Built from Figma frame `1:2438`.
class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({required this.email, super.key});

  final String email;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignInBloc>(
      create: (_) => sl<SignInBloc>(),
      child: _EmailVerificationView(email: email),
    );
  }
}

class _EmailVerificationView extends StatefulWidget {
  const _EmailVerificationView({required this.email});

  final String email;

  @override
  State<_EmailVerificationView> createState() => _EmailVerificationViewState();
}

class _EmailVerificationViewState extends State<_EmailVerificationView> {
  /// How long before another code may be requested. Matches the design's 0:45.
  static const Duration _resendWindow = Duration(seconds: 45);

  Timer? _ticker;
  int _secondsLeft = _resendWindow.inSeconds;
  String _code = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _ticker?.cancel();
    setState(() => _secondsLeft = _resendWindow.inSeconds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  void _submit(AppLocalizations l10n) {
    if (_code.length < 6) {
      setState(() => _error = l10n.verifyEmailCodeIncomplete);
      return;
    }
    setState(() => _error = null);
    context.read<SignInBloc>().add(
      SignInCodeSubmitted(email: widget.email, code: _code),
    );
  }

  String get _countdown {
    final minutes = _secondsLeft ~/ 60;
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final muted = AppColors.mutedStrong;

    return Scaffold(
      appBar: AppBar(
        // Icons.arrow_back mirrors with the layout; arrow_left would not.
        leading: IconButton(
          onPressed: () => context.go(Routes.loginPath),
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<SignInBloc, SignInState>(
          listener: (context, state) {
            switch (state) {
              case SignInSucceeded(:final user):
                context.read<AuthBloc>().add(AuthSessionEstablished(user));
              case SignInCodeSent():
                // A resend landed; restart the window.
                _startCountdown();
              case SignInIdle() || SignInSubmitting() || SignInFailureState():
                break;
            }
          },
          builder: (context, state) {
            if (state is SignInFailureState) {
              return FailureView(
                failure: state.failure,
                onRetry: () => context.read<SignInBloc>().add(
                  SignInCodeResendRequested(widget.email),
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
                    l10n.verifyEmailTitle,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineLarge,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.verifyEmailSubtitle(widget.email),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  OtpInput(
                    enabled: !busy,
                    onChanged: (code) => _code = code,
                    onCompleted: (_) => _submit(l10n),
                  ),
                  if (_error != null) ...[
                    SizedBox(height: AppSpacing.s),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  SizedBox(height: AppSpacing.xxl),
                  FilledButton(
                    onPressed: busy ? null : () => _submit(l10n),
                    child: busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.verifyEmailConfirm),
                  ),
                  SizedBox(height: AppSpacing.l),
                  _ResendRow(
                    prompt: l10n.verifyEmailNoCode,
                    action: l10n.verifyEmailResend,
                    countdown: _secondsLeft > 0 ? _countdown : null,
                    onResend: busy || _secondsLeft > 0
                        ? null
                        : () => context.read<SignInBloc>().add(
                            SignInCodeResendRequested(widget.email),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// "Did not get the code?  Resend  0:45"
class _ResendRow extends StatelessWidget {
  const _ResendRow({
    required this.prompt,
    required this.action,
    required this.countdown,
    required this.onResend,
  });

  final String prompt;
  final String action;

  /// Null once the window has elapsed and resending is allowed.
  final String? countdown;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = AppColors.mutedStrong;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(prompt, style: textTheme.bodyMedium?.copyWith(color: muted)),
        TextButton(onPressed: onResend, child: Text(action)),
        if (countdown != null)
          Text(
            countdown!,
            // direction-fixed: a m:ss timer reads the same in every locale
            textDirection: TextDirection.ltr,
            style: textTheme.bodyMedium?.copyWith(color: muted),
          ),
      ],
    );
  }
}
