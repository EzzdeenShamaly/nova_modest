import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// hide Order: injectable exports an `Order` annotation that shadows this
// feature's entity.
import 'package:injectable/injectable.dart' hide Order;
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_item.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_totals.dart';
import 'package:nova_modest/features/checkout/domain/entities/checkout_draft.dart';
import 'package:nova_modest/features/checkout/domain/entities/checkout_step.dart';
import 'package:nova_modest/features/checkout/domain/entities/contact_details.dart';
import 'package:nova_modest/features/checkout/domain/entities/payment_method.dart';
import 'package:nova_modest/features/checkout/domain/entities/shipping_method.dart';
import 'package:nova_modest/features/checkout/domain/repositories/order_repository.dart';

part 'checkout_event.dart';
part 'checkout_state.dart';

/// Runs the checkout flow: which step the shopper is on, and what the steps
/// have collected between them.
///
/// A **factory**, provided by the `ShellRoute` around `/checkout` — so it lives
/// exactly as long as the flow. A singleton would keep a half-finished draft
/// alive for the rest of the session and hand it to whoever opened checkout
/// next; `CartBloc` is a singleton because the navigation badge reads it, and
/// nothing outside this flow reads a checkout draft.
///
/// Holds one repository, and only from the review step: nothing leaves the
/// device until the shopper confirms.
@injectable
class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  CheckoutBloc(this._orders) : super(const CheckoutInProgress()) {
    // droppable: opening is idempotent, and a duplicate would re-seed the
    // contact fields over whatever the shopper had already typed.
    on<CheckoutStarted>(_onStarted, transformer: droppable());
    // sequential: every step change is a read-modify-write of one draft.
    on<CheckoutContactSubmitted>(
      _onContactSubmitted,
      transformer: sequential(),
    );
    on<CheckoutAddressSelected>(_onAddressSelected, transformer: sequential());
    on<CheckoutPaymentSubmitted>(
      _onPaymentSubmitted,
      transformer: sequential(),
    );
    on<CheckoutStepRequested>(_onStepRequested, transformer: sequential());
    // droppable: placing an order is the one action in this app that must not
    // happen twice. A second tap while the first is in flight is discarded,
    // not queued.
    on<CheckoutConfirmed>(_onConfirmed, transformer: droppable());
    on<CheckoutBackRequested>(_onBackRequested, transformer: sequential());
  }

  final OrderRepository _orders;

  void _onStarted(CheckoutStarted event, Emitter<CheckoutState> emit) {
    final user = event.user;

    emit(
      CheckoutInProgress(
        draft: CheckoutDraft(
          // Pre-filled from the account, and editable; empty for a guest. The
          // email is not a field on the form — it rides along from the account
          // so the review screen can show it, and stays null for a guest.
          contact: ContactDetails(
            fullName: user?.displayName ?? '',
            phone: user?.phone ?? '',
            email: user?.email,
          ),
          cart: event.cart,
          items: event.items,
        ),
      ),
    );
  }

  void _onContactSubmitted(
    CheckoutContactSubmitted event,
    Emitter<CheckoutState> emit,
  ) => _advance(emit, (draft) => draft.copyWith(contact: event.contact));

  void _onAddressSelected(
    CheckoutAddressSelected event,
    Emitter<CheckoutState> emit,
  ) => _advance(emit, (draft) => draft.copyWith(address: event.address));

  void _onPaymentSubmitted(
    CheckoutPaymentSubmitted event,
    Emitter<CheckoutState> emit,
  ) => _advance(
    emit,
    (draft) => draft.copyWith(shipping: event.shipping, payment: event.payment),
  );

  /// Records what a step collected and moves on.
  ///
  /// "On" is the review when the shopper got here by a "تعديل" link, and the
  /// next step otherwise — so finishing an edit returns them whether they tap
  /// the forward button or the back arrow. The pending return is consumed
  /// either way.
  void _advance(
    Emitter<CheckoutState> emit,
    CheckoutDraft Function(CheckoutDraft) collect,
  ) {
    final current = state;
    final destination = current.returnTo ?? current.step.next;
    if (destination == null) return;

    emit(CheckoutInProgress(step: destination, draft: collect(current.draft)));
  }

  /// Jumps back to an earlier step from a "تعديل" link.
  ///
  /// Records where the shopper came from, so finishing the edit returns them
  /// straight to the review instead of walking the remaining steps again.
  void _onStepRequested(
    CheckoutStepRequested event,
    Emitter<CheckoutState> emit,
  ) {
    final current = state;
    // Backwards only. A jump forward would skip a step, which is the thing the
    // single-route design exists to prevent.
    if (event.step.index >= current.step.index) return;

    emit(
      CheckoutInProgress(
        step: event.step,
        draft: current.draft,
        returnTo: current.step,
      ),
    );
  }

  Future<void> _onConfirmed(
    CheckoutConfirmed event,
    Emitter<CheckoutState> emit,
  ) async {
    final current = state;
    emit(CheckoutPlacing(step: current.step, draft: current.draft));

    // No try/catch: the repository returns a Result and this folds it
    // (`06-flutter-error-guard.md` §4).
    final result = await _orders.place(current.draft);

    emit(
      result.fold(
        (failure) => CheckoutFailed(
          step: current.step,
          draft: current.draft,
          failure: failure,
        ),
        (order) => CheckoutInProgress(
          step: CheckoutStep.success,
          draft: current.draft.copyWith(order: order),
        ),
      ),
    );
  }

  void _onBackRequested(
    CheckoutBackRequested event,
    Emitter<CheckoutState> emit,
  ) {
    final current = state;

    // An edit that came from the review returns there, not one step back. The
    // pending return is consumed by this move.
    final destination = current.returnTo ?? current.step.previous;
    // Null at the first step: nothing to move back to inside the flow, so
    // nothing is emitted and the host leaves checkout instead.
    if (destination == null) return;

    emit(CheckoutInProgress(step: destination, draft: current.draft));
  }
}
