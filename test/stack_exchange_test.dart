import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_stack/src/pages.dart';
import 'package:mix_stack/src/stack_exchange.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  StackExchange exchange = StackExchange();
  group("Native calls", () {
    test('Set pages', () async {
      exchange.setPages({
        'pages': ['test_page?addr=123', 'test_page?addr=456'],
        'current': 'test_page?addr=123'
      });
      expect(exchange.pagesCommand.currentPage, 'test_page?addr=123');
      expect(exchange.pagesCommand.pages, ['test_page?addr=123', 'test_page?addr=456']);
    });

    test('Page exists', () async {
      expect(
          exchange.pageExists({
            'addr': '123',
          }),
          {'exist': true});
      expect(
          exchange.pageExists({
            'addr': '555',
          }),
          {'exist': false});
      expect(exchange.pageExists(null), {'exist': false});
    });

    test('Pop Page', () async {
      expect(
          exchange.popPage({
            'current': '123',
          }),
          {'result': false});
      expect(exchange.popPage(null), {'result': false});
    });

    test('Update ContainerInfo', () async {
      exchange.containerInfoUpdate({
        'target': 'test_page?addr=123',
        'info': {
          'left': 0.0,
          'top': 1.0,
          'right': 2.0,
          'bottom': 3.0,
        }
      });
      expect(exchange.pagesCommand.containerInfo!.insets, EdgeInsets.fromLTRB(0, 1, 2, 3));
    });

    test('pageEvent', () async {
      expect(exchange.pageEvent({'addr': '123', 'query': {}, 'event': 'hello'}), {'result': 0});
      expect(exchange.pageEvent(null), {'result': 0});
    });

    test('Page Navigator Stack Length', () async {
      exchange.pagesCommand.addListener(() {
        if (exchange.pagesCommand.type == PagesCommandType.query) {
          final info = PageInfo(['/hello']);
          exchange.pagesCommand.pageNavInfo = info;
        }
      });
      expect(exchange.pageHistory({'current': 'test_page?addr=123'}), ['/hello']);
      expect(exchange.pageHistory(null), []);
    });
  });

  int count = 0;
  group('Call native', () {
    setUp(() {
      exchange.bridge.setMockMethodCallHandler((call) {
        if (call.method == 'overlayNames') {
          return Future.value(['1', '2', '3']);
        }
        if (call.method == 'configOverlays') {
          return Future.value(null);
        }
        if (call.method == 'currentOverlayTexture') {
          if (count == 0) {
            count += 1;
            return Future.value(null);
          }
          return Future.value(Uint8List(10));
        }
        if (call.method == 'enablePanNavigation') {
          return Future.value(null);
        }
        if (call.method == 'overlayInfos') {
          return Future.value({'1': '1'});
        }
        if (call.method == 'popNative') {
          return Future.value(null);
        }
        return Future.value(0);
      });
    });

    tearDown(() {
      exchange.bridge.setMockMethodCallHandler(null);
    });

    test('getOverlayNames', () {
      expect(exchange.getOverlayNames('1234'), completion(equals(['1', '2', '3'])));
    });
    test('configOverlays', () {
      exchange.configOverlays('1234', {'1': '1'});
    });
    test('overlayTexture', () {
      expect(exchange.overlayTexture('1234', ['1', '2']), completion(equals(Uint8List(0))));
    });
    test('overlayTexture', () {
      expect(exchange.overlayTexture('1234', ['1', '2']), completion(equals(Uint8List(10))));
    });
    test('enableNativePan', () {
      exchange.enableNativePan('1234', false);
    });
    test('overlayInfos', () {
      expect(exchange.overlayInfos('1234', ['1', '2']), completion(equals({'1': '1'})));
    });
    test('popNative', () {
      exchange.popNative('1234');
    });
  });
}
