import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mix_stack.dart';
import 'pages.dart';

typedef PageBuilderForRoute = Route Function(BuildContext context, String route);
typedef NavigatorObserversBuilder = List<NavigatorObserver> Function();
typedef CustomPopHandler = void Function(BuildContext context);

class StackExchange {
  final pagesCommand = PagesCommand();
  final MethodChannel bridge = MethodChannel('mix_stack');

  StackExchange() {
    bridge.setMethodCallHandler((call) {
      print('mix_stack call: $call');
      Map query = call.arguments['query'];
      if (call.method == 'pageExists') {
        return Future.value(pageExists(query));
      }
      if (call.method == 'setPages') {
        setPages(query);
      }
      if (call.method == 'containerInfoUpdate') {
        containerInfoUpdate(query);
      }
      if (call.method == 'popPage') {
        return Future.value(popPage(query));
      }
      if (call.method == 'pageHistory') {
        return Future.value(pageHistory(query));
      }
      if (call.method == 'pageEvent') {
        return Future.value(pageEvent(query));
      }
      if (call.method == 'resetPanGesture') {
        return Future.value(resetPanGesture());
      }
      if (call.method == 'updateLifecycle') {
        updateLifecycle(query);
      }
      return Future.value(0);
    });
  }
  //Input
  Map pageExists(Map query) {
    Map<String, dynamic> result = Map<String, dynamic>.from(query);
    return {'exist': pagesCommand.exist(result['addr'])};
  }

  setPages(Map query) {
    final pages = List<String>.from(query['pages']);
    pagesCommand.update(pages, query['current']);
  }

  popPage(Map query) {
    if (query == null) {
      query = {};
    }
    return {'result': pagesCommand.popPage(query['current'])};
  }

  containerInfoUpdate(query) {
    if (query == null) {
      return;
    }
    final info = PageContainerInfo(Map<String, dynamic>.from(query['info']));
    pagesCommand.updateInfo(query['target'], info);
  }

  pageHistory(Map query) {
    if (query == null) {
      query = {};
    }
    PageInfo info = pagesCommand.pageNavigatorInfo(query['current']);
    if (info != null) {
      return info.history;
    } else {
      return [];
    }
  }

  pageEvent(Map query) {
    if (query == null) {
      return {'result': 0};
    }
    final q = Map<String, dynamic>.from(query['query']);
    pagesCommand.pageEvent(query['addr'], query['event'], q);
    return {'result': 0};
  }

  resetPanGesture() {
    pagesCommand.resetPanGesture();
    return {'result': 0};
  }

  void updateLifecycle(Map query) {
    switch (query['lifecycle']) {
      case 'resumed':
        MixStack.lifecycleNotifier.value = AppLifecycleState.resumed;
        break;
      case 'detached':
        MixStack.lifecycleNotifier.value = AppLifecycleState.detached;
        break;
      case 'paused':
        MixStack.lifecycleNotifier.value = AppLifecycleState.paused;
        break;
      case 'inactive':
        MixStack.lifecycleNotifier.value = AppLifecycleState.inactive;
        break;
      default:
        break;
    }
  }

  //Output
  Future<List<String>> getOverlayNames(String addr) async {
    List<dynamic> result = await bridge.invokeMethod('overlayNames', {'addr': addr});
    return List<String>.from(result);
  }

  void configOverlays(String addr, Map<String, dynamic> configs) async {
    bridge.invokeMethod('configOverlays', {'addr': addr, 'configs': configs});
  }

  Future<Uint8List> overlayTexture(String addr, List<String> names) async {
    return bridge.invokeMethod('currentOverlayTexture', {'addr': addr, 'names': names});
  }

  void enableNativePan(String addr, bool enable) async {
    bridge.invokeMethod('enablePanNavigation', {'addr': addr, 'enable': enable});
  }

  Future<Map> overlayInfos(String addr, List<String> names) async {
    return bridge.invokeMethod<Map>('overlayInfos', {'addr': addr, 'names': names});
  }

  Future<bool> popNative(String addr, {needsAnimation: true}) async {
    return bridge.invokeMethod('popNative', {'addr': addr, 'needsAnimation': needsAnimation});
  }

  void updatePages() {
    bridge.invokeMethod('updatePages', null);
  }
}
