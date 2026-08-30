import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/widgets/settings_card.dart';

import '../../helpers/pump_app.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pump(
    WidgetTester tester, {
    required List<Widget> children,
    SettingsCardVariant variant = SettingsCardVariant.outlined,
  }) async {
    await tester.pumpApp(
      Scaffold(
        body: SettingsCard(variant: variant, children: children),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The card's own Material, not a row's.
  Material cardMaterial(WidgetTester tester) =>
      tester.widget<Material>(find.byType(Material).at(1));

  RoundedRectangleBorder cardShape(WidgetTester tester) =>
      cardMaterial(tester).shape! as RoundedRectangleBorder;

  List<Color?> ruleColours(WidgetTester tester) => tester
      .widgetList<Divider>(find.byType(Divider))
      .map((divider) => divider.color)
      .toList();

  group('the rules between rows', () {
    testWidgets('separate the rows and never follow the last', (tester) async {
      await pump(
        tester,
        children: const [Text('one'), Text('two'), Text('three')],
      );

      // Three rows, two rules. A trailing rule under the last row is the thing
      // that made every hand-rolled copy of this card look subtly wrong.
      expect(find.byType(Divider), findsNWidgets(2));
      expect(find.text('one'), findsOneWidget);
      expect(find.text('three'), findsOneWidget);
    });

    testWidgets('a single row is drawn without any rule', (tester) async {
      await pump(tester, children: const [Text('only')]);

      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('take no vertical space of their own', (tester) async {
      await pump(tester, children: const [Text('one'), Text('two')]);

      // height 0: the rows carry their own padding, and a Divider's default
      // 16pt of surrounding space would double it.
      expect(tester.widget<Divider>(find.byType(Divider)).height, 0);
    });
  });

  group('the outlined variant', () {
    testWidgets('sits on the page colour behind a hairline border', (
      tester,
    ) async {
      await pump(tester, children: const [Text('one'), Text('two')]);

      expect(cardMaterial(tester).color, AppColors.background);
      expect(cardShape(tester).side.color, AppColors.subtle);
      expect(ruleColours(tester), [AppColors.subtle]);
    });

    testWidgets('is what a card without a named variant gets', (tester) async {
      // Three of the four screens this replaced drew exactly this, so it is
      // the default rather than something every caller has to ask for.
      await tester.pumpApp(
        const Scaffold(body: SettingsCard(children: [Text('one')])),
      );
      await tester.pumpAndSettle();

      expect(cardMaterial(tester).color, AppColors.background);
    });
  });

  group('the filled variant', () {
    testWidgets('is a sand panel with no border and matching rules', (
      tester,
    ) async {
      await pump(
        tester,
        variant: SettingsCardVariant.filled,
        children: const [Text('one'), Text('two')],
      );

      expect(cardMaterial(tester).color, AppColors.secondary);
      // The language frame draws no border at all; a hairline one here would
      // be the outlined card wearing the wrong fill.
      expect(cardShape(tester).side, BorderSide.none);
      expect(ruleColours(tester), [AppColors.secondary]);
    });
  });

  group('the corners', () {
    testWidgets('clip their rows, so ink stops at the radius', (tester) async {
      await pump(tester, children: const [Text('one')]);

      expect(cardMaterial(tester).clipBehavior, Clip.antiAlias);
    });
  });
}
