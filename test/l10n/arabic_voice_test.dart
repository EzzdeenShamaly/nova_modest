import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The Arabic copy addresses the shopper in the feminine, everywhere.
///
/// This is a shop for women's clothing and the voice was chosen deliberately —
/// «اكتشفي», «تابعي طلباتك», «تسوّقي الآن», «هل تريدين تسجيل الخروج». Five
/// strings had drifted into the masculine by 2026-09-20, one of them added by
/// the agent three days earlier, and nobody noticed until the app was read
/// screen by screen on a device. A mixed voice reads as carelessness in a way
/// no single string does.
///
/// So the check is mechanical: the masculine imperative forms below must not
/// appear in `app_ar.arb`. Each is bounded on both sides, so the feminine
/// «احذفي» and «أضيفي» pass while «احذف» and «أضف» fail.
///
/// Deliberately **not** in the list, both found by this test crying wolf on its
/// first run: «حدث», which is the past-tense "happened" in «حدث خطأ ما» as
/// often as it is an imperative, and «تسوق», which is the noun "shopping" in
/// «تجربة تسوق آمنة». A check that raises false alarms gets switched off, so
/// an ambiguous word is worth less here than the trust in the check.
void main() {
  const masculineImperatives = [
    'احذف', 'أضف', 'اضف', 'اختر', 'قم', 'تابع', 'اكتشف', 'سجّل', 'سجل',
    'راجع', 'تصفح', 'انقر', 'اضغط', 'أدخل', 'ادخل', 'اكتب', 'اذهب', 'ابحث',
    'اطلب', 'جرّب',
  ];

  test('no user-facing Arabic string slips into the masculine', () {
    final arb =
        jsonDecode(File('lib/l10n/app_ar.arb').readAsStringSync())
            as Map<String, dynamic>;

    final offenders = <String, String>{};
    for (final entry in arb.entries) {
      // Keys beginning with @ are translator metadata, not shown to anyone.
      if (entry.key.startsWith('@') || entry.value is! String) continue;
      for (final word in masculineImperatives) {
        // A letter on either side means it is part of a longer word: the
        // feminine «احذفي» ends in ي, and «تسجيل» contains no standalone «سجّل».
        final bounded = RegExp('(?<![ء-ي])$word(?![ء-ي])');
        if (bounded.hasMatch(entry.value as String)) {
          offenders[entry.key] = entry.value as String;
          break;
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'These read as masculine while the rest of the app speaks to the '
          'shopper in the feminine. Use the feminine form — «احذفي», «أضيفي», '
          '«أدخلي» — or, if this really is an exception, add it to the list '
          'in this test with a reason:\n'
          '${offenders.entries.map((e) => '  ${e.key} = ${e.value}').join('\n')}',
    );
  });
}
