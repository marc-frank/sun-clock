// Access to the translated texts (lib/l10n/app_*.arb): `context.l10n.settings`.

import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

final AppLocalizations _english = lookupAppLocalizations(const Locale('en'));

extension L10n on BuildContext {
  /// The texts for this context's language; English where no localizations
  /// are installed (widget tests that pump a bare MaterialApp).
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ?? _english;
}

/// Short month names, January first.
List<String> monthNames(AppLocalizations l) => l.monthsShort.split(',');

/// "8 Nov" / "8. Nov".
String dayMonthLabel(AppLocalizations l, DateTime d) =>
    l.dayMonth('${d.day}', monthNames(l)[d.month - 1]);
