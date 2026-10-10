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
    'احذف',
    'أضف',
    'اضف',
    'اختر',
    'قم',
    'تابع',
    'اكتشف',
    'سجّل',
    'سجل',
    'راجع',
    'تصفح',
    'انقر',
    'اضغط',
    'أدخل',
    'ادخل',
    'اكتب',
    'اذهب',
    'ابحث',
    'اطلب',
    'جرّب',
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

  /// **The list above guards twenty words and nothing else** — which is how
  /// «وإذا تكرر تواصل معنا» sat in `orderErrorTechnical` unnoticed: «تواصل» was
  /// never on it (found 2026-09-21). A hand-kept list guards what someone
  /// thought of, and looks as though it guards everything.
  ///
  /// This one keeps no list. It reads **every feminine imperative the app itself
  /// speaks** out of `app_ar.arb`, and fails on the masculine form of any of
  /// them, anywhere in the file. Add a string saying «جرّبي» and «جرّب» is
  /// guarded from then on without anyone editing this test.
  ///
  /// **What it cannot do, and why:** tell an imperative from the same letters
  /// used otherwise, in general. «حدث خطأ» is the past tense, «تجربة تسوق» is a
  /// noun — only the sentence around them decides, and a pattern cannot parse a
  /// sentence. So those uses are allowed **per string, not per word**: «حدث» is
  /// fine in `failureServer`, and still fails the day it appears as a command
  /// anywhere else. And a masculine imperative whose feminine form the app
  /// never uses at all is invisible here — that residue is what the list above
  /// is still for.
  test('no feminine imperative the app uses appears in the masculine', () {
    final arb =
        jsonDecode(File('lib/l10n/app_ar.arb').readAsStringSync())
            as Map<String, dynamic>;
    final texts = {
      for (final e in arb.entries)
        if (!e.key.startsWith('@') && e.value is String)
          e.key: _plain(e.value as String),
    };

    final verbs = _feminineImperatives(texts);

    // Guards the guard: if extraction ever silently finds nothing, every
    // string would pass and this test would be decoration. These are forms the
    // app is known to speak.
    expect(
      verbs,
      containsAll(<String>['تواصل', 'اختار', 'أعيد', 'تسوق', 'أضيف']),
      reason: 'the feminine imperatives were not found; the check is blind',
    );

    final offenders = <String>[];
    for (final MapEntry(key: key, value: text) in texts.entries) {
      for (final verb in verbs) {
        final standalone = RegExp('(?<![$_letters])[وف]?$verb(?![$_letters])');
        if (standalone.hasMatch(text) && !_allowed.contains((key, verb))) {
          offenders.add('  $key: «$verb» in «$text»');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'The masculine form of an imperative the app speaks in the feminine. '
          'Use the feminine, or — if the same letters are a noun or a past '
          'tense here — add (key, word) to _allowed with the reason:\n'
          '${offenders.join('\n')}',
    );
  });
}

/// Arabic letters, without the marks.
const String _letters = 'ء-ي';

/// Where the masculine letters are legitimately not an imperative. Keyed by the
/// string, so each exception covers one sentence someone has read, not a word.
const Set<(String, String)> _allowed = {
  // «حدث خطأ …» — past tense, "an error happened".
  ('failureServer', 'حدث'),
  ('failureUnknown', 'حدث'),
  // «تجربة تسوق آمنة» — the noun "shopping", in construct with «تجربة».
  ('onboardingBody3', 'تسوق'),
};

/// Harakat, shadda, sukun, the dagger alef and tatweel removed, so «تسوّقي» and
/// «تسوقي» are one word. The check is about letters, not pointing.
String _plain(String s) => s.replaceAll(RegExp('[ً-ْٰـ]'), '');

/// Every feminine singular imperative in [texts], returned as its masculine
/// stem: «اختاري» → «اختار», «راسلينا» → «راسل».
///
/// A word counts when it ends in «ي» (an attached «نا», «ها» or «ه» allowed),
/// **opens a clause** — the start of the string, or after «.»، «،»، «؟»، «!»،
/// «:» or a line break — and **is followed by more words**, because an
/// imperative takes a complement («اختاري صورة»), while a label ending in «ي»
/// stands alone («طلباتي»). Words carrying the article «ال» are never verbs.
Set<String> _feminineImperatives(Map<String, String> texts) {
  final word = RegExp('[$_letters]+');
  final clauseStart = RegExp(r'(?:^|[.،؟!:\n]\s*)$');
  final feminine = RegExp('^([$_letters]{3,})ي(?:نا|ها|ه)?\$');

  final stems = <String>{};
  for (final text in texts.values) {
    for (final m in word.allMatches(text)) {
      var w = m.group(0)!;
      if (!clauseStart.hasMatch(text.substring(0, m.start))) continue;
      if (!RegExp(r'^\s+\S').hasMatch(text.substring(m.end))) continue;
      // An attached «و» or «ف» is a conjunction, not part of the verb.
      if ((w.startsWith('و') || w.startsWith('ف')) && w.length > 4) {
        w = w.substring(1);
      }
      if (w.startsWith('ال')) continue;
      final f = feminine.firstMatch(w);
      if (f != null) stems.add(f.group(1)!);
    }
  }
  return stems;
}
