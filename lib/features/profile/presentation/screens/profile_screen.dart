import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/core/widgets/avatar_circle.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/core/widgets/settings_card.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:nova_modest/features/auth/presentation/bloc/account_deletion_bloc.dart';
import 'package:nova_modest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nova_modest/features/profile/presentation/widgets/profile_menu_tile.dart';
import 'package:nova_modest/l10n/app_localizations.dart';
import 'package:nova_modest/router/routes.dart';

/// The account screen, built from Figma frame `1:1645`.
///
/// A **shell branch**, so the bottom navigation stays visible — the frame draws
/// a back arrow as well as the bar with this tab active, and a tab root has
/// nothing to go back to.
///
/// Reads [AuthBloc] rather than a repository of its own: the signed-in user is
/// already app-wide state, and a second source for the same person would be one
/// that could disagree.
///
/// **No four-state contract here, deliberately.** Nothing loads: `/profile` is
/// in `Routes.protectedPrefixes`, so anyone who reaches this screen already has
/// a resolved session. The only other state it can be caught in is the moment
/// between requesting sign-out and the router moving them on.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          l10n.brandName,
          // direction-fixed: a brandmark's glyph order is fixed by the mark
          // itself, not by the reader's language
          textDirection: TextDirection.ltr,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ),
      // Account deletion is one visit's business, so its bloc is scoped here
      // rather than app-wide — the same call as ProfileEditBloc.
      body: BlocProvider<AccountDeletionBloc>(
        create: (_) => sl<AccountDeletionBloc>(),
        child: BlocConsumer<AccountDeletionBloc, AccountDeletionState>(
          listener: _onDeletion,
          builder: (context, deletion) => deletion is AccountDeletionInProgress
              // Nothing on this screen may be touched while an irreversible
              // request is in flight.
              ? const Center(child: CircularProgressIndicator())
              : BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) => switch (state) {
                    AuthAuthenticated(:final user) => _Body(user: user),
                    // Signing out is in flight; the redirect follows in a
                    // moment.
                    AuthLoading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    // Unreachable behind the gate, and listed rather than
                    // caught by a wildcard so a new AuthState is a compile
                    // error here.
                    AuthInitial() ||
                    AuthCheckInProgress() ||
                    AuthUnauthenticated() ||
                    AuthFailureState() => const SizedBox.shrink(),
                  },
                ),
        ),
      ),
    );
  }

  /// What each outcome of a deletion does. The router does the navigating in
  /// both session-ending cases: the session state goes unauthenticated,
  /// `/profile` is protected, and the guard moves her to sign-in.
  void _onDeletion(BuildContext context, AccountDeletionState state) {
    switch (state) {
      case AccountDeletionSucceeded():
        // The repository already cleared the device's session; this only moves
        // the app's own state.
        context.read<AuthBloc>().add(const AuthAccountDeleted());
      case AccountDeletionFailed(failure: UnauthorizedFailure()):
        // An expired session, handled as every expired session is: signed out
        // and back to sign-in, rather than a message asking her to do that by
        // hand (owner, 2026-09-21). Nothing was deleted.
        context.read<AuthBloc>().add(const AuthLogoutRequested());
      case AccountDeletionFailed(:final failure):
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failureMessage(failure, l10n))));
      case AccountDeletionIdle() || AccountDeletionInProgress():
        break;
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: EdgeInsetsDirectional.all(AppSpacing.l),
      children: [
        _HeaderCard(user: user),
        SizedBox(height: AppSpacing.l),
        SettingsCard(
          children: [
            ProfileMenuTile(
              icon: Icons.receipt_long_outlined,
              label: l10n.profileMyOrders,
              onTap: () => context.push(Routes.ordersPath),
            ),
            ProfileMenuTile(
              icon: Icons.person_outline,
              label: l10n.profilePersonalInfo,
              onTap: () => context.push(Routes.personalInfo),
            ),
            ProfileMenuTile(
              icon: Icons.location_on_outlined,
              label: l10n.profileAddresses,
              onTap: () => context.push(Routes.addresses),
            ),
            ProfileMenuTile(
              icon: Icons.language_outlined,
              label: l10n.profileLanguage,
              // Each locale names itself in the ARB, so this is the language
              // actually in force rather than a lookup table that would go
              // stale the day a third one is added.
              value: l10n.languageName,
              onTap: () => context.push(Routes.language),
            ),
            ProfileMenuTile(
              icon: Icons.notifications_none,
              label: l10n.profileNotifications,
              onTap: () => context.push(Routes.notifications),
            ),
            ProfileMenuTile(
              icon: Icons.help_outline,
              label: l10n.profileHelp,
              onTap: () => context.push(Routes.help),
            ),
            ProfileMenuTile(
              icon: Icons.description_outlined,
              label: l10n.profileTerms,
              onTap: () => context.push(Routes.terms),
            ),
            ProfileMenuTile(
              icon: Icons.logout,
              label: l10n.logoutButton,
              destructive: true,
              onTap: () => _confirmLogout(context),
            ),
            // Last, and in the error colour. Play requires deletion to be
            // discoverable inside the app; the dialog, not an obscure
            // placement, is what protects against a mistaken tap
            // (owner, 2026-09-21).
            ProfileMenuTile(
              icon: Icons.delete_forever_outlined,
              label: l10n.accountDelete,
              destructive: true,
              onTap: () => _confirmDeletion(context),
            ),
          ],
        ),
      ],
    );
  }

  /// Says what goes and what stays, then asks.
  ///
  /// Both halves are stated **before** she can press: the profile, the saved
  /// addresses and the photograph are deleted; past orders stay with the shop,
  /// unlinked, because `orders.user_id` is ON DELETE SET NULL. Learning the
  /// second half afterwards would be learning it too late (owner, 2026-09-21).
  Future<void> _confirmDeletion(BuildContext context) async {
    final bloc = context.read<AccountDeletionBloc>();
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(l10n.accountDelete),
        content: SingleChildScrollView(child: Text(l10n.accountDeleteBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.accountDelete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed ?? false) bloc.add(const AccountDeletionConfirmed());
  }

  /// Asks before ending the session.
  ///
  /// The design draws sign-out as one more row in a scrolling list, which makes
  /// it the easiest thing on the screen to hit by accident. The dialog is the
  /// only addition to the frame.
  Future<void> _confirmLogout(BuildContext context) async {
    final bloc = context.read<AuthBloc>();
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(l10n.logoutButton),
        content: Text(l10n.profileLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.logoutButton,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    // The router does the navigating: signing out makes the session state
    // unauthenticated, and `/profile` is protected, so the guard moves the user
    // to sign-in. No screen navigates on its own state change.
    if (confirmed ?? false) bloc.add(const AuthLogoutRequested());
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.hairline,
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.all(AppSpacing.l),
        child: Row(
          children: [
            // Read-only here: the picture is changed on the personal-
            // information screen, one tap away, rather than from two places.
            AvatarCircle(
              imageUrl: user.avatarUrl,
              displayName: user.displayName,
            ),
            SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.headlineMedium,
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  _Detail(text: user.email),
                  // Omitted rather than blank: a shopper who signed in with
                  // Google may have no phone number at all.
                  if (user.phone case final phone?) ...[
                    SizedBox(height: AppSpacing.xxs),
                    _Detail(text: phone),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
  );
}

/// The bordered card the menu rows sit in, with the design's hairlines between
/// them.
