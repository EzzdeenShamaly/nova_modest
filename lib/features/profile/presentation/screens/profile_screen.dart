import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/core/widgets/settings_card.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
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
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) => switch (state) {
          AuthAuthenticated(:final user) => _Body(user: user),
          // Signing out is in flight; the redirect follows in a moment.
          AuthLoading() => const Center(child: CircularProgressIndicator()),
          // Unreachable behind the gate, and listed rather than caught by a
          // wildcard so a new AuthState is a compile error here.
          AuthInitial() ||
          AuthCheckInProgress() ||
          AuthUnauthenticated() ||
          AuthFailureState() => const SizedBox.shrink(),
        },
      ),
    );
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
          ],
        ),
      ],
    );
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

  /// The design's 64pt disc.
  static const double _avatarSize = 64;

  /// The first character of the name, by code point rather than by index, so a
  /// name starting outside the basic plane is not cut in half.
  String get _initial {
    final name = user.displayName.trim();
    return name.isEmpty ? '' : String.fromCharCode(name.runes.first);
  }

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
            Container(
              width: _avatarSize,
              height: _avatarSize,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              // No photography yet. `avatarUrl` is already on the entity, so an
              // image later replaces this without another field.
              child: Text(_initial, style: textTheme.headlineMedium),
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
