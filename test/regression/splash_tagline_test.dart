import 'package:c_billing/common_widgets/twinkling_slogan.dart';
import 'package:c_billing/core/localization/english.dart';
import 'package:c_billing/core/localization/hindi.dart';
import 'package:c_billing/core/localization/marathi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the splash/login slogan exists in all three languages', () {
    expect(EnglishLocalization.backboneOfBusiness, 'Power your Business');
    expect(HindiLocalization.backboneOfBusiness, isNotEmpty);
    expect(MarathiLocalization.backboneOfBusiness, isNotEmpty);
  });

  testWidgets('the shared slogan widget renders its text centered and left',
      (tester) async {
    for (final align in [TextAlign.center, TextAlign.start]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TwinklingSlogan(
                  text: EnglishLocalization.backboneOfBusiness,
                  textAlign: align,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('Power your Business'), findsWidgets);
      expect(tester.takeException(), isNull);
    }
  });
}
