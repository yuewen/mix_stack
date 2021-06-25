import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_stack/mix_stack.dart';
import 'package:mix_stack/src/native_overlay_replacer.dart';
import 'package:mix_stack/src/stack_exchange.dart';

main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Uint8List data = Uint8List(0);
  StackExchange exchange = StackExchange();
  setUp(() {
    File file;
    print(Directory.current);
    final pwd = Directory.current.path;
    if (pwd.split('/').last == 'test') {
      file = File('../.images/logo.png');
    } else {
      file = File('.images/logo.png');
    }
    file.readAsBytes().then((value) {
      print('Loaded');
      data = value;
    });

    exchange.bridge.setMockMethodCallHandler((call) {
      if (call.method == 'currentOverlayTexture') {
        return Future.value(data);
      }
      return Future.value(0);
    });
  });

  tearDown(() {
    data = Uint8List(0);
  });
  test('NativeOverlayInfo', () {
    final rect = Rect.fromLTWH(1.0, 2.0, 3.0, 4.0);
    final info =
        NativeOverlayInfo({'hidden': true, 'x': rect.left, 'y': rect.top, 'width': rect.width, 'height': rect.height});
    expect(info.hidden, true);
    expect(info.rect, rect);
    expect(info.hashCode, info.hidden.hashCode ^ info.rect.hashCode);
  });

  test('autoHidesTabBar', () {
    final replacer = NativeOverlayReplacer.autoHidesTabBar(child: Container());
    expect(replacer.autoHidesOverlayNames.first, MXOverlayNameTabBar);
    expect(replacer.autoHidesOverlayNames.length, 1);
  });

  test('NativeOverlayConfig', () {
    final config = NativeOverlayConfig(name: 'hello', alpha: 0.1, hidden: true, needsAnimation: true);
    expect(config.dict, {'hidden': 1, 'alpha': 0.1, 'animation': 1});
  });

  testWidgets('NativeOverlayReplacer', (WidgetTester tester) async {
    NativeOverlayReplacer? overlay;
    MXRouteObserver observer = MXRouteObserver(pageAddress: '123');
    late BuildContext testCTX;
    final navigator = Navigator(
      observers: [observer],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
            builder: (BuildContext context) {
              overlay = NativeOverlayReplacer(
                child: Builder(builder: (BuildContext ctx) {
                  testCTX = ctx;
                  expect(NativeOverlayReplacer.of(ctx)!.widget, overlay);
                  return Container();
                }),
              );
              return overlay!;
            },
            settings: settings);
      },
    );
    final app = MixStack(stackExchange: exchange, child: MaterialApp(home: Scaffold(body: navigator)));
    await tester.pumpWidget(app);
    expect(find.byType(Image), findsNothing);
    NativeOverlayReplacer.of(testCTX)!.overflowData = data;
    await tester.pump(Duration(seconds: 1));
    expect(find.byType(NativeOverlayReplacer), findsOneWidget);
    expect(find.descendant(of: find.byType(NativeOverlayReplacer), matching: find.byType(Image)), findsOneWidget);
    NativeOverlayReplacer.of(testCTX)!.overflowData = Uint8List(0);
    NativeOverlayReplacer.of(testCTX)!.registerAutoPushHiding(
      ['123'],
      persist: true,
      adjustConfigs: (configs, {required hideOverlay}) {},
    );
    BuildContext oldCTX = testCTX;
    Navigator.of(testCTX).pushNamed('/hello');
    await tester.pump(Duration(seconds: 1));
    expect(NativeOverlayReplacer.of(oldCTX)!.overflowData, data);
    Navigator.of(testCTX).pop();
    await tester.pump(Duration(seconds: 1));
    expect(NativeOverlayReplacer.of(oldCTX)!.overflowData.length, 0);
  });
}
