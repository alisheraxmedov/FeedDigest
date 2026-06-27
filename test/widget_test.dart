import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/core/theme/app_theme.dart';
import 'package:feeddigest/core/widgets/state_views.dart';
import 'package:feeddigest/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.dark(),
  locale: const Locale('uz'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('EmptyView shows its message', (tester) async {
    await tester.pumpWidget(_wrap(const EmptyView(message: 'Bo\'sh')));
    expect(find.text('Bo\'sh'), findsOneWidget);
  });

  testWidgets('ErrorView shows message and retry button', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      _wrap(ErrorView(message: 'Xato', onRetry: () => retried = true)),
    );
    expect(find.text('Xato'), findsOneWidget);
    await tester.tap(find.text('Qayta urinish'));
    expect(retried, true);
  });
}
