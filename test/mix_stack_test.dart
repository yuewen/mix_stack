import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_stack/mix_stack.dart';
import 'package:mix_stack/src/stack_exchange.dart';

main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  StackExchange exchange = StackExchange();

  group('MixStack', () {
    final observer = MXRouteObserver(pageAddress: '123');
    bool? panEnabled;
    bool? popNative;
    final infoDict = {'hidden': true, 'x': 1.0, 'y': 2.0, 'width': 3.0, 'height': 4.0};
    final info = NativeOverlayInfo(infoDict);
    setUp(() {
      exchange.bridge.setMockMethodCallHandler((call) {
        if (call.method == 'overlayNames') {
          return Future.value(['1', '2', '3']);
        }
        if (call.method == 'configOverlays') {
          return Future.value(null);
        }
        if (call.method == 'currentOverlayTexture') {
          return Future.value(Uint8List(10));
        }
        if (call.method == 'enablePanNavigation') {
          panEnabled = call.arguments['enable'];
          return Future.value(null);
        }
        if (call.method == 'overlayInfos') {
          return Future.value({
            '1': {'hidden': true, 'x': 1.0, 'y': 2.0, 'width': 3.0, 'height': 4.0}
          });
        }
        if (call.method == 'popNative') {
          popNative = true;
          return Future.value(null);
        }
        return Future.value(0);
      });
    });

    tearDown(() {
      exchange.bridge.setMockMethodCallHandler(null);
    });

    testWidgets('Statics', (WidgetTester tester) async {
      final p = MaterialApp(
        home: Scaffold(
          body: Navigator(
            observers: [observer],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) {
                  expect(MixStack.of(context)!.overlayTexture(context, ['123']),
                      completion(equals(equals(Uint8List(10)))));
                  expect(MixStack.getExchange(context), exchange);
                  MixStack.configOverlays(context, {
                    '1': {'1': 1}
                  });
                  MixStack.getOverlayNames(context).then((value) {
                    expect(value, ['1', '2', '3']);
                  });
                  MixStack.enableNativePanGensture(context, true);
                  expect(panEnabled, true);
                  expect(MixStack.overlayInfos(context, ['1']), completion(equals(equals({'1': info}))));
                  expect(MixStack.overlayInfos(context, ['1'], delay: Duration(seconds: 1)),
                      completion(equals(equals({'1': info}))));
                  MixStack.popNative(context);
                  expect(popNative, true);
                  return Container();
                },
              );
            },
          ),
        ),
      );
      final stack = MixStack(
        stackExchange: exchange,
        child: p,
      );
      expect(stack.updateShouldNotify(stack), false);
      await tester.pumpWidget(stack);
      await tester.pump(Duration(seconds: 2));
    });
  });
}
