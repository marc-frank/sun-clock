import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sun_clock/l10n/l10n.dart';

void main() {
  test('every language has twelve month names and its own texts', () {
    final seen = <String>{};
    for (final locale in AppLocalizations.supportedLocales) {
      final l = lookupAppLocalizations(locale);
      expect(monthNames(l), hasLength(12), reason: '$locale');
      expect(l.sunriseAt('06:15'), contains('06:15'));
      seen.add(l.sunTime);
    }
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode),
        containsAll(['en', 'de', 'fr', 'es']));
    expect(seen, hasLength(4));
    expect(dayMonthLabel(lookupAppLocalizations(const Locale('de')),
        DateTime.utc(2026, 3, 8)), '8. Mär');
  });
}
