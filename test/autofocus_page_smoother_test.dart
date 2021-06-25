import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_stack/src/autofocus_page_smoother.dart';

main() {
  testWidgets('Basic', (WidgetTester tester) async {
    final testKey = Key('K');
    Widget child = TextField(autofocus: true);
    await tester.pumpWidget(MaterialApp(key: testKey, home: Scaffold(body: AutofocusPageSmoother(child: child))));
    expect(find.byWidget(child), findsOneWidget);
  });

  testWidgets('Focus test Autofocus True', (WidgetTester tester) async {
    final testKey = Key('K');
    FocusNode node = FocusNode();
    TextField child = TextField(
      autofocus: true,
      focusNode: node,
    );
    print(child);
    await tester.pumpWidget(MaterialApp(key: testKey, home: Scaffold(body: AutofocusPageSmoother(child: child))));
    await tester.pumpAndSettle(Duration(seconds: 1));
    expect(child.focusNode!.hasFocus, true);
  });

  testWidgets('Focus test Autofocus False', (WidgetTester tester) async {
    final testKey = Key('K');
    FocusNode node = FocusNode();
    TextField child = TextField(
      autofocus: false,
      focusNode: node,
    );
    print(child);
    await tester.pumpWidget(MaterialApp(key: testKey, home: Scaffold(body: AutofocusPageSmoother(child: child))));
    await tester.pumpAndSettle(Duration(seconds: 1));
    expect(child.focusNode!.hasFocus, false);
  });
}
