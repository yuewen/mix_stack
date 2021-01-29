import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_stack/mix_stack.dart';
import 'package:mix_stack/src/route_observer.dart';
import 'package:mix_stack/src/helper.dart';

main() {
  const page = '/test?addr=123';
  group("Basic", () {
    test("Intialziation", () {
      final observer = MXRouteObserver(pageAddress: page.address);
      expect(observer.stackLength, 0);
      expect(observer.pageAddress, page.address);
    });

    testWidgets('Put into navigator', (WidgetTester tester) async {
      final observer = MXRouteObserver(pageAddress: page.address);
      BuildContext ctx;
      await tester.pumpWidget(CupertinoApp(
        home: Navigator(
            observers: [observer],
            onGenerateRoute: (settings) {
              return CupertinoPageRoute(
                  builder: (BuildContext context) {
                    ctx = context;
                    return Container();
                  },
                  settings: settings);
            }),
      ));
      expect(observer.stackLength, 1);
      expect(observer.lastIndex, 1);
      expect(observer.isRoot, true);
      Navigator.of(ctx).pushNamed('/test');
      expect(observer.stackLength, 2);
      expect(observer.lastIndex, 2);
      expect(observer.isRoot, false);
      expect(MXRouteObserver.of(ctx), observer);
      expect(observer.toString(), '${observer.runtimeType} ${observer.hashCode}, 2');
      Navigator.of(ctx).pop();
      expect(observer.stackLength, 1);
      expect(observer.lastIndex, 1);
      expect(observer.isRoot, true);
    });
  });

  testWidgets('Persiste is false', (WidgetTester tester) async {
    final observer = MXRouteObserver(pageAddress: page.address);
    BuildContext ctx;
    await tester.pumpWidget(CupertinoApp(
      home: Navigator(
          observers: [observer],
          onGenerateRoute: (settings) {
            print('--> ${settings.name}');
            return CupertinoPageRoute(
                builder: (BuildContext context) {
                  ctx = context;
                  print('--> ${ctx.hashCode}');
                  return Container();
                },
                settings: settings);
          }),
    ));
    int count = 0;
    observer.registerAutoPushHiding(ctx, ['123'], (configs, {hideOverlay}) {
      count += 1;
      return configs;
    }, persist: false);
    Navigator.of(ctx).pushNamed('/1');
    await tester.pumpAndSettle(Duration(seconds: 1));
    expect(count, 1);
    Navigator.of(ctx).pop();
    expect(count, 2);
    // Navigator.of(ctx).pushNamed('/2');
    // await tester.pumpAndSettle(Duration(seconds: 1));
    // Navigator.of(ctx).pop();
    Navigator.of(ctx).pop();
  });

  testWidgets('Persiste is true', (WidgetTester tester) async {
    final observer = MXRouteObserver(pageAddress: page.address);
    BuildContext ctx;
    await tester.pumpWidget(CupertinoApp(
      home: Navigator(
          observers: [observer],
          onGenerateRoute: (settings) {
            print('--> ${settings.name}');
            return CupertinoPageRoute(
                builder: (BuildContext context) {
                  ctx = context;
                  print('--> ${ctx.hashCode}');
                  return Container();
                },
                settings: settings);
          }),
    ));
    int count = 0;
    observer.registerAutoPushHiding(ctx, ['123'], (configs, {hideOverlay}) {
      count += 1;
      return configs;
    }, persist: true);
    Navigator.of(ctx).pushNamed('/1');
    await tester.pumpAndSettle(Duration(seconds: 1));
    expect(count, 1);
    Navigator.of(ctx).pop();
    expect(count, 2);
    // Navigator.of(ctx).pushNamed('/2');
    // await tester.pumpAndSettle(Duration(seconds: 1));
    // Navigator.of(ctx).pop();
    Navigator.of(ctx).pop();
  });
}
