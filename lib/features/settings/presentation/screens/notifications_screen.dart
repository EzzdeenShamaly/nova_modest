import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/core/widgets/settings_card.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/features/settings/domain/entities/notification_preferences.dart';
import 'package:nova_modest/features/settings/presentation/bloc/notification_preferences_bloc.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// Which notifications the shopper wants.
///
/// **No Figma frame exists** — checked against all 38 in the file, none of which
/// is a notifications or settings screen. The third such screen after help and
/// terms, so the layout borrows the account section's own vocabulary.
///
/// The switches inherit `switchTheme`, which exists because Material 3 derives a
/// switch's off state from `surfaceContainerHighest` and `outline` — both of
/// which this palette maps to `AppColors.secondary`, leaving the control one
/// solid block at 1.00:1 until it was themed.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocProvider<NotificationPreferencesBloc>(
      create: (_) =>
          sl<NotificationPreferencesBloc>()
            ..add(const NotificationPreferencesRequested()),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(l10n.profileNotifications),
        ),
        body:
            BlocConsumer<
              NotificationPreferencesBloc,
              NotificationPreferencesState
            >(
              listenWhen: (previous, current) =>
                  current is NotificationPreferencesResolved &&
                  current.saveFailure != null,
              listener: (context, state) {
                // The switch has already moved; this only says the choice will not
                // survive a restart.
                final failure =
                    (state as NotificationPreferencesResolved).saveFailure!;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(failureMessage(failure, l10n))),
                );
              },
              builder: (context, state) =>
                  _Body(preferences: state.preferences),
            ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.preferences});

  final NotificationPreferences preferences;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<NotificationPreferencesBloc>();

    void change(NotificationPreferences next) =>
        bloc.add(NotificationPreferencesChanged(next));

    return ListView(
      padding: EdgeInsetsDirectional.all(AppSpacing.l),
      children: [
        SettingsCard(
          children: [
            _PreferenceRow(
              title: l10n.notificationsOrders,
              description: l10n.notificationsOrdersDescription,
              value: preferences.orders,
              onChanged: (value) => change(preferences.copyWith(orders: value)),
            ),
            _PreferenceRow(
              title: l10n.notificationsPromotions,
              description: l10n.notificationsPromotionsDescription,
              value: preferences.promotions,
              onChanged: (value) =>
                  change(preferences.copyWith(promotions: value)),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.m),
        Text(
          l10n.notificationsDeviceNote,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

/// The account section's card of rows.
///
/// The **fourth** near-identical one, after the account menu's, the language
/// chooser's and help's. Still local, still recorded in `progress.md` as its own
/// task: promoting a shared card now means editing three working screens in the
/// middle of an unrelated change (`09-minimal-changes.md`).

/// One preference: a title, a line saying what it actually covers, and a switch.
class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: textTheme.bodyLarge),
      subtitle: Text(
        description,
        style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
      ),
      // Colours come from the theme's switchTheme, not from here.
      contentPadding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.xs,
      ),
    );
  }
}
