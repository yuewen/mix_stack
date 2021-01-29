import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'native_overlay_replacer.dart';
import 'route_observer.dart';
import 'stack_exchange.dart';

/// Data provider for MixStack based app
class MixStack extends InheritedWidget {
  MixStack({@required this.stackExchange, Widget child}) : super(child: child);

  /// Wrapper of channel communication
  final StackExchange stackExchange;

  /// Use this to reach the MixStack widget for children
  static MixStack of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MixStack>();
  }

  /// Offers correct lifecyccle change events for app
  static ValueNotifier<AppLifecycleState> lifecycleNotifier =
      ValueNotifier<AppLifecycleState>(AppLifecycleState.paused);

  /// Fetch the current native container's texture according to [names]
  Future<Uint8List> overlayTexture(BuildContext context, List<String> names) async {
    final addr = MXRouteObserver.of(context).pageAddress;
    return stackExchange.overlayTexture(addr, names);
  }

  /// Fetch StackExchange for children
  static StackExchange getExchange(BuildContext context) {
    final stack = MixStack.of(context);
    return stack.stackExchange;
  }

  /// Config current native container's overlay UI through a map with [Name -> Config]
  static void configOverlays(BuildContext context, Map<String, dynamic> configs) async {
    final addr = MXRouteObserver.of(context).pageAddress;
    getExchange(context).configOverlays(addr, configs);
  }

  /// Get current native container's customizable overlay UI names
  static Future<List<String>> getOverlayNames(BuildContext context) async {
    final addr = MXRouteObserver.of(context).pageAddress;
    return getExchange(context).getOverlayNames(addr);
  }

  /// Manually enable or disable current native container's pan back gesture, mainly for iOS
  static void enableNativePanGensture(BuildContext context, bool enable) async {
    final addr = MXRouteObserver.of(context).pageAddress;
    getExchange(context).enableNativePan(addr, enable);
  }

  /// Get current native container's overlay UI's details based on offered [names]
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

  /// Manually pop current native container from native navigation stack
  ///
  /// [needsAnimation] marks whether enable native's animation or not
  static Future<bool> popNative(BuildContext context, {needsAnimation: true}) async {
    final addr = MXRouteObserver.of(context).pageAddress;
    return getExchange(context).popNative(addr, needsAnimation: needsAnimation);
  }

  @override
  bool updateShouldNotify(MixStack old) {
    return old.stackExchange != stackExchange;
  }
}
