import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'native_overlay_replacer.dart';
import 'route_observer.dart';
import 'stack_exchange.dart';

class MixStack extends InheritedWidget {
  MixStack({@required this.stackExchange, Widget child}) : super(child: child);

  final StackExchange stackExchange;
  static MixStack of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MixStack>();
  }

  static ValueNotifier<AppLifecycleState> lifecycleNotifier =
      ValueNotifier<AppLifecycleState>(AppLifecycleState.paused);

  Future<Uint8List> overlayTexture(BuildContext context, List<String> names) async {
    final addr = MXRouteObserver.of(context).pageAddress;
    return stackExchange.overlayTexture(addr, names);
  }

  static StackExchange getExchange(BuildContext context) {
    final stack = MixStack.of(context);
    return stack.stackExchange;
  }

  static void configOverlays(BuildContext context, Map<String, dynamic> configs) async {
    final addr = MXRouteObserver.of(context).pageAddress;
    getExchange(context).configOverlays(addr, configs);
  }

  static Future<List<String>> getOverlayNames(BuildContext context) async {
    final addr = MXRouteObserver.of(context).pageAddress;
    return getExchange(context).getOverlayNames(addr);
  }

  static void enableNativePanGensture(BuildContext context, bool enable) async {
    final addr = MXRouteObserver.of(context).pageAddress;
    getExchange(context).enableNativePan(addr, enable);
  }

  static Future<Map<String, NativeOverlayInfo>> overlayInfos(BuildContext context, List<String> names,
      {Duration delay}) async {
    getInfos() async {
      final addr = MXRouteObserver.of(context).pageAddress;
      final result = await getExchange(context).overlayInfos(addr, names);
      Map<String, NativeOverlayInfo> infos = {};
      for (var key in result.keys) {
        String name = key as String;
        Map infoDict = result[key];
        NativeOverlayInfo info = NativeOverlayInfo(infoDict);
        infos[name] = info;
      }
      return infos;
    }

    if (delay != null) {
      return Future.delayed(delay, () async {
        return getInfos();
      });
    } else {
      return getInfos();
    }
  }

  static Future<bool> popNative(BuildContext context, {needsAnimation: true}) async {
    final addr = MXRouteObserver.of(context).pageAddress;
    return getExchange(context).popNative(addr, needsAnimation: needsAnimation);
  }

  @override
  bool updateShouldNotify(MixStack old) {
    return old.stackExchange != stackExchange;
  }
}
