import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/core/theme/app_theme.dart';
import 'package:feeddigest/features/interests/view/interests_screen.dart';
import 'package:feeddigest/l10n/app_localizations.dart';

Widget _harness() => ProviderScope(
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.light(),
    home: const InterestsScreen(),
  ),
);

void main() {
  testWidgets('renders interest chips and title', (tester) async {
    await tester.pumpWidget(_harness());
    expect(find.text('Choose your interests'), findsOneWidget);
    expect(find.text('Python'), findsOneWidget);
    expect(find.text('Claude'), findsOneWidget);
  });

  testWidgets('tapping a chip marks it selected (shows a check)', (tester) async {
    await tester.pumpWidget(_harness());
    expect(find.byIcon(Icons.check), findsNothing);

    // Python is in the first group, so it's on-screen and hittable.
    await tester.tap(find.text('Python'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
