import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nova_modest/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:nova_modest/features/checkout/domain/entities/checkout_step.dart';
import 'package:nova_modest/features/checkout/domain/entities/contact_details.dart';
import 'package:nova_modest/features/checkout/presentation/bloc/checkout_bloc.dart';
import 'package:nova_modest/features/checkout/presentation/widgets/address_step.dart';
import 'package:nova_modest/features/checkout/presentation/widgets/checkout_step_indicator.dart';
import 'package:nova_modest/features/checkout/presentation/widgets/contact_step.dart';
import 'package:nova_modest/features/checkout/presentation/widgets/payment_step.dart';
import 'package:nova_modest/features/checkout/presentation/widgets/review_step.dart';
import 'package:nova_modest/features/checkout/presentation/widgets/success_step.dart';
import 'package:nova_modest/l10n/app_localizations.dart';
import 'package:nova_modest/router/routes.dart';

/// The checkout flow: one route, one screen, a body that follows the step.
///
/// Built this way rather than a route per step because the flow carries a draft
/// forward. A URL per step would let someone land on the review with nothing
/// collected — a state every screen would then have to guard. Here the step is
/// bloc state, so it cannot be skipped.
///
/// `CheckoutBloc` is provided by the `ShellRoute` around `/checkout`, so the
/// draft lives exactly as long as the flow.
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CheckoutBloc, CheckoutState>(
      listenWhen: (previous, current) =>
          current is CheckoutFailed ||
          // The transition into the confirmation, not merely being on it: this
          // must fire once per placed order, not once per rebuild.
          (current.step == CheckoutStep.success &&
              previous.step != CheckoutStep.success),
      listener: (context, state) {
        // A snack bar rather than a FailureView: the whole reviewed order is
        // still on screen and still correct, and replacing it with an error
        // card would throw away what the shopper is about to confirm.
        if (state case CheckoutFailed(:final failure)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                failureMessage(failure, AppLocalizations.of(context)),
              ),
            ),
          );
          return;
        }

        // The order exists, so the cart must not — otherwise the shopper comes
        // back to the things they have just bought and buys them again.
        //
        // Dispatched to `CartBloc` from here rather than done inside
        // `CheckoutBloc`: `CartBloc` is the single owner of cart state, and a
        // second writer would leave the navigation badge disagreeing with the
        // storage until something re-read it.
        context.read<CartBloc>().add(const CartCleared());
      },
      builder: (context, state) => _CheckoutView(state: state),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  const _CheckoutView({required this.state});

  final CheckoutState state;

  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> {
  final _contactKey = GlobalKey<ContactStepState>();
  final _addressKey = GlobalKey<AddressStepState>();
  final _paymentKey = GlobalKey<PaymentStepState>();

  /// Back within the flow, or out of it when there is nowhere left inside.
  ///
  /// Asks the **state**, not the step: a shopper who reached this step from a
  /// "تعديل" link has the review to go back to even when the step itself is the
  /// first one. Asking `step.previous` popped them out of checkout entirely.
  void _back() {
    if (!widget.state.canMoveBack) {
      Navigator.of(context).pop();
      return;
    }
    context.read<CheckoutBloc>().add(const CheckoutBackRequested());
  }

  void _next() {
    switch (widget.state.step) {
      case CheckoutStep.contact:
        _contactKey.currentState?.submit();
      // Either advances straight away with a saved address, or starts a save
      // and advances from its own listener once the address has an id.
      case CheckoutStep.address:
        _addressKey.currentState?.submit();
      case CheckoutStep.payment:
        _paymentKey.currentState?.submit();
      case CheckoutStep.review:
        context.read<CheckoutBloc>().add(const CheckoutConfirmed());
      // Terminal: the confirmation screen offers its own ways onward, and it is
      // what the next batch builds.
      case CheckoutStep.success:
        break;
    }
  }

  /// The terminal step: no chrome, no way back into a flow that is finished.
  bool get _isDone => widget.state.step == CheckoutStep.success;

  /// Leaves checkout for the shop front, replacing the stack.
  ///
  /// `go`, not `pop`: popping would land on whatever opened checkout, which is
  /// the cart the order has just emptied.
  void _leave() => context.go(Routes.homePath);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = widget.state;

    return PopScope<Object?>(
      // Back must walk the steps, not leave the flow from the middle of it —
      // and from the confirmation there is no walking back to a placed order.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isDone) {
          _leave();
          return;
        }
        _back();
      },
      child: Scaffold(
        // The confirmation frame draws no bar at all: nothing to title, and
        // nothing to go back to.
        appBar: _isDone
            ? null
            : AppBar(
                centerTitle: true,
                title: Text(_titleFor(state.step, l10n)),
                leading: IconButton(
                  onPressed: _back,
                  // Icons.arrow_back mirrors with the layout; arrow_left would
                  // not.
                  icon: const Icon(Icons.arrow_back),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                ),
              ),
        // A fixed indicator over a step that fills what is left, rather than
        // one scrolling list holding both: a step body that wants the whole
        // height — the placeholder ones do — cannot live inside a ListView, and
        // asking for an unbounded height is exactly how that fails.
        // The confirmation owns its whole display; every other step is a fixed
        // indicator over a body that fills what is left.
        body: _isDone
            ? _bodyFor(state, l10n)
            : Column(
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: AppSpacing.l,
                      end: AppSpacing.l,
                      top: AppSpacing.l,
                    ),
                    child: CheckoutStepIndicator(step: state.step),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  Expanded(child: _bodyFor(state, l10n)),
                ],
              ),
        // The confirmation carries its own two actions inside the content.
        bottomNavigationBar: _isDone
            ? null
            : _NextBar(
                label: _nextLabelFor(state.step, l10n),
                // Only the built steps can move forward — and nothing may while
                // the order is in flight, which is the one action in this app
                // that must not happen twice.
                onNext:
                    _builtSteps.contains(state.step) &&
                        state is! CheckoutPlacing
                    ? _next
                    : null,
                busy: state is CheckoutPlacing,
              ),
      ),
    );
  }

  Widget _bodyFor(
    CheckoutState state,
    AppLocalizations l10n,
  ) => switch (state.step) {
    // Scrollable in its own right, so a keyboard cannot squeeze the form
    // and `_revealFirstError` has something to scroll.
    CheckoutStep.contact => SingleChildScrollView(
      padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.l),
      child: ContactStep(
        key: _contactKey,
        initial: state.draft.contact ?? const ContactDetails(),
        onSubmit: (contact) =>
            context.read<CheckoutBloc>().add(CheckoutContactSubmitted(contact)),
      ),
    ),
    // Not built yet. Shown as a placeholder rather than a dead end, so the
    // step the shopper reached is at least named — the same call `/orders`
    // makes.
    // Brings its own scroll view and padding, because the saved list and
    // the form together are longer than a phone.
    CheckoutStep.address => AddressStep(
      key: _addressKey,
      selected: state.draft.address,
      onSelected: (address) =>
          context.read<CheckoutBloc>().add(CheckoutAddressSelected(address)),
    ),
    // Brings its own scroll view and padding, like the address step.
    CheckoutStep.payment => PaymentStep(
      key: _paymentKey,
      shipping: state.draft.shipping,
      payment: state.draft.payment,
      // The draft owns the arithmetic; this asks it what a pair of selections
      // comes to rather than adding anything up in a widget.
      totalsFor: (shipping, payment) =>
          state.draft.copyWith(shipping: shipping, payment: payment).totals,
      onSubmit: (shipping, payment) => context.read<CheckoutBloc>().add(
        CheckoutPaymentSubmitted(shipping: shipping, payment: payment),
      ),
    ),
    // Stateless: nothing here is chosen, only confirmed, so the bar dispatches
    // straight to the bloc instead of through a key.
    CheckoutStep.review => ReviewStep(
      draft: state.draft,
      onEdit: (step) =>
          context.read<CheckoutBloc>().add(CheckoutStepRequested(step)),
    ),
    CheckoutStep.success => SuccessStep(
      order: state.draft.order,
      // Hidden from a guest: `/orders` is behind the sign-in gate, so the
      // button would send someone who has just paid to a login screen.
      onTrackOrder: switch (context.read<AuthBloc>().state) {
        AuthAuthenticated() => () => context.go(Routes.ordersPath),
        _ => null,
      },
      onKeepShopping: _leave,
    ),
  };

  /// The steps that can be submitted today.
  static const Set<CheckoutStep> _builtSteps = {
    CheckoutStep.contact,
    CheckoutStep.address,
    CheckoutStep.payment,
    CheckoutStep.review,
  };

  /// The forward button is named per step, not "next" throughout — each frame
  /// labels its own. Step 2's says it saves as well as advances, which is what
  /// it does when the shopper typed a new address.
  ///
  /// The unbuilt steps keep the generic label: `1:1840` and `1:2137` draw no
  /// bottom bar at all, and inventing copy for one would be a guess
  /// (`10-evidence-and-dependency-guard.md`).
  static String _nextLabelFor(CheckoutStep step, AppLocalizations l10n) =>
      switch (step) {
        CheckoutStep.address => l10n.checkoutSaveAndContinue,
        CheckoutStep.payment => l10n.checkoutToReview,
        CheckoutStep.review => l10n.reviewConfirm,
        CheckoutStep.contact || CheckoutStep.success => l10n.onboardingNext,
      };

  static String _titleFor(CheckoutStep step, AppLocalizations l10n) =>
      switch (step) {
        CheckoutStep.contact => l10n.checkoutContactTitle,
        CheckoutStep.address => l10n.checkoutAddressTitle,
        CheckoutStep.payment => l10n.checkoutPaymentTitle,
        CheckoutStep.review => l10n.checkoutReviewTitle,
        CheckoutStep.success => l10n.checkoutSuccessTitle,
      };
}

/// The sticky bar carrying the flow forward.
class _NextBar extends StatelessWidget {
  const _NextBar({
    required this.label,
    required this.onNext,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onNext;

  /// True while the order is being placed.
  final bool busy;

  /// Sized to sit inside the button without changing its height.
  static const double _spinnerSize = 20;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: BorderDirectional(top: BorderSide(color: AppColors.secondary)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsetsDirectional.all(AppSpacing.m),
          child: FilledButton(
            onPressed: onNext,
            child: busy
                ? SizedBox.square(
                    dimension: _spinnerSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.background,
                      // The label is gone while this spins, so the button still
                      // has to say what it is doing.
                      semanticsLabel: label,
                    ),
                  )
                : Text(label),
          ),
        ),
      ),
    );
  }
}
