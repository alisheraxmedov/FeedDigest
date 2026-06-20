import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/core/widgets/state_views.dart';

void main() {
  testWidgets('EmptyView shows its message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: EmptyView(message: 'Bo\'sh'))),
    );
    expect(find.text('Bo\'sh'), findsOneWidget);
  });

  testWidgets('ErrorView shows message and retry button', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorView(message: 'Xato', onRetry: () => retried = true),
        ),
      ),
    );
    expect(find.text('Xato'), findsOneWidget);
    await tester.tap(find.text('Qayta urinish'));
    expect(retried, true);
  });
}
