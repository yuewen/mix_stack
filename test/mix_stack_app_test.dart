import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_stack/mix_stack.dart';
import 'package:mix_stack/src/mix_stack_app.dart';

main() {
  testWidgets('Init', (WidgetTester tester) async {
    final app = MixStackApp(
      routeBuilder: (context, path) {
        return MaterialPageRoute(builder: (BuildContext context) {
          return Container();
        });
      },
    );
    await tester.pumpWidget(app);
    expect(find.byWidget(app), findsOneWidget);
    expect(find.byType(Pages), findsOneWidget);
  });
}
