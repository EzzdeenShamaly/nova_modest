import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/l10n/app_localizations.dart';
import 'package:nova_modest/l10n/app_localizations_ar.dart';

/// What a shopper actually reads when `place_order` refuses.
///
/// Until 2026-09-17 every one of the thirteen refusals rendered the same
/// sentence — "يرجى التحقق من البيانات المدخلة" — because `failureMessage`
/// switched on the failure's *type* and the code never left the mapper. Nothing
/// was broken; the information was simply discarded on the way to the screen.
///
/// These assert the sentence, not the plumbing, because the sentence is the
/// deliverable.
void main() {
  final AppLocalizations ar = AppLocalizationsAr();

  String messageFor(String code, {String? subject}) => failureMessage(
    ValidationFailure('ignored', code: code, subject: subject),
    ar,
  );

  group('a refusal the shopper can act on, about a product it can name', () {
    test('sold out names the product and says what to do', () {
      final message = messageFor(
        'product_sold_out',
        subject: 'عباية حرير مغسول',
      );

      expect(message, contains('عباية حرير مغسول'));
      expect(message, contains('نفدت'));
      // Actionable: it tells them the move, not merely that something is wrong.
      expect(message, contains('حذف المنتج من السلة'));
    });

    test('without a resolved name the sentence still reads', () {
      // The degradation path. `details` is not a format the contract promises,
      // so an unresolved name is expected behaviour — and must not produce
      // "null" or a dangling colon.
      final message = messageFor('product_sold_out');

      expect(message, contains('أحد منتجات سلتك'));
      expect(message, isNot(contains('null')));
      expect(message, contains('نفدت'));
    });

    test('the other three product codes each say something different', () {
      final messages = {
        for (final code in const [
          'product_sold_out',
          'product_not_found',
          'colour_not_for_product',
          'size_not_for_product',
        ])
          code: messageFor(code, subject: 'عباية كتان يومية'),
      };

      expect(messages.values.toSet(), hasLength(4));
      expect(messages['colour_not_for_product'], contains('لون'));
      expect(messages['size_not_for_product'], contains('مقاس'));
      for (final message in messages.values) {
        expect(message, contains('عباية كتان يومية'));
      }
    });
  });

  group('a refusal the shopper can act on', () {
    test('card payment points at the method that does work', () {
      final message = messageFor('payment_not_available');

      expect(message, contains('الدفع عند الاستلام'));
    });

    test('too many lines names the limit', () {
      expect(messageFor('too_many_lines'), contains('٢٠'));
    });

    test('a lapsed session says to sign in', () {
      expect(messageFor('not_signed_in'), contains('تسجيل الدخول'));
    });
  });

  group('a refusal that is our defect, not their mistake', () {
    // The app validates every one of these before it sends: a blank field, a
    // repeated line, a quantity outside 1–10, an unknown shipping, payment or
    // address kind. One arriving means the bug is ours, so the sentence must
    // not suggest the shopper mistyped anything.
    const ours = [
      'missing_details',
      'duplicate_line',
      'invalid_quantity',
      'invalid_shipping_method',
      'invalid_payment_method',
      'invalid_address_kind',
    ];

    test('all six share one honest message', () {
      final messages = {for (final code in ours) messageFor(code)};

      expect(messages, hasLength(1));
      expect(messages.single, contains('خلل تقني'));
    });

    test('it says the problem is ours and does not blame the shopper', () {
      final message = messageFor('missing_details');

      expect(message, contains('لدينا'));
      // The generic validation sentence puts it on the shopper's input. These
      // are not that.
      expect(message, isNot(equals(ar.failureValidation)));
    });
  });

  group('a code this build has never heard of', () {
    test('renders the technical message, not raw English', () {
      // A code added to the database after this build ships. It must not reach
      // `Failure.message`, which is the server's own English.
      final message = messageFor('teleportation_unavailable');

      expect(message, ar.orderErrorTechnical);
      expect(message, isNot(contains('teleportation')));
    });

    test('and an empty code is treated the same way', () {
      expect(messageFor(''), ar.orderErrorTechnical);
    });
  });

  test('a validation failure with no code keeps the generic message', () {
    // 23514, and anything that never came from the order contract at all.
    expect(
      failureMessage(const ValidationFailure('constraint violated'), ar),
      ar.failureValidation,
    );
  });

  test('every other failure type is untouched', () {
    expect(failureMessage(const NetworkFailure(), ar), ar.failureNetwork);
    expect(failureMessage(const ServerFailure('boom'), ar), ar.failureServer);
    expect(failureMessage(const NotFoundFailure(), ar), ar.failureNotFound);
    expect(
      failureMessage(const UnauthorizedFailure(), ar),
      ar.failureUnauthorized,
    );
    expect(failureMessage(const CacheFailure(), ar), ar.failureCache);
    expect(failureMessage(const UnknownFailure(), ar), ar.failureUnknown);
  });
}
