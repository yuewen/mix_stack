import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mix_stack/mix_stack.dart';
import 'mix_stack.dart';
import 'native_overlay_replacer.dart';

class MXPageInfo {
  final String name;
  Function(List<MXPageInfo> stack) _nextPopAction;
  Function(List<MXPageInfo> stack, Function pushNewInfo) _nextPushAction;

  Function(List<MXPageInfo> stack) _nextOncePopAction;
  Function(List<MXPageInfo> stack, Function pushNewInfo) _nextOncePushAction;
  List<String> hideOverlays = [];
  MXPageInfo(this.name) : super();

  void pop(List<MXPageInfo> stack) {
    if (_nextOncePopAction != null) {
      _nextOncePopAction(stack);
      _nextOncePopAction = null;
      return;
    }
    if (_nextPopAction != null) {
      _nextPopAction(stack);
    }
  }

  void push(List<MXPageInfo> stack, Function pushNewInfo) {
    if (_nextOncePushAction != null) {
      _nextOncePushAction(stack, pushNewInfo);
      _nextOncePushAction = null;
      return;
    }
    if (_nextPushAction != null) {
      _nextPushAction(stack, pushNewInfo);
    } else {
      if (pushNewInfo != null) {
        pushNewInfo();
      }
    }
  }

  @override
  String toString() {
    return "$runtimeType $name";
  }
}

class MXRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  static MXRouteObserver of(BuildContext context, {bool rootNavigator = false}) {
    NavigatorState navigator = Navigator.of(context, rootNavigator: rootNavigator);
    if (navigator == null) {
      return null;
    }
    List<NavigatorObserver> observers =
        navigator.widget.observers.where((element) => element.runtimeType == MXRouteObserver).toList();
    if (observers.length == 0) {
      return null;
    } else {
      return observers.first;
    }
  }

  final String pageAddress;
  MXRouteObserver({
    @required this.pageAddress,
  }) : super();
  List<MXPageInfo> _stack = [];

  @override
  String toString() {
    return '$runtimeType $hashCode, ${_stack.length}';
  }

  int get lastIndex => _stack.length;
  List<String> get history => _stack.map((e) => e.name).toList();

  bool get isRoot {
    return stackLength <= 1;
  }

  int get stackLength {
    return _stack.length;
  }

  void updateNativePanGestureState() {
    print('Update navigation pan');
    if (navigator?.context == null) {
      return;
    }
    if (MixStack.of(navigator.context) == null) {
      return;
    }
    if (MixStack.of(navigator.context).stackExchange != null) {
      print('Update navigation pan sent');
      MixStack.of(navigator.context).stackExchange.enableNativePan(pageAddress, isRoot);
    }
  }

  void markFullScreen(List<String> names, NativeOverlayConfigsAdjustFunction configNativeOverlay, bool once) {
    List<NativeOverlayConfig> configs = names.map((e) {
      return NativeOverlayConfig(name: e, alpha: 0, hidden: true);
    }).toList();
    if (configNativeOverlay != null) {
      configNativeOverlay(configs, hideOverlay: true);
    }
    MXPageInfo info = _stack.last;
    info.hideOverlays = names;
    final func = (currentStack) {
      Set<String> previousHideParts = Set();
      for (var item in currentStack) {
        previousHideParts.addAll(item.hideOverlays);
      }
      List<String> canShow = names.where((element) => !previousHideParts.contains(element)).toList();
      List<NativeOverlayConfig> showconfigs = canShow.map((e) {
        return NativeOverlayConfig(name: e, alpha: 1, hidden: false);
      }).toList();
      if (configNativeOverlay != null) {
        configNativeOverlay(showconfigs, hideOverlay: false);
      }
    };

    if (once) {
      info._nextOncePopAction = func;
    } else {
      info._nextPopAction = func;
    }
  }

  void registerAutoPushHiding(BuildContext context, List<String> names, NativeOverlayConfigsAdjustFunction configFunc,
      {@required bool persist}) {
    if (_stack.length > 0) {
      Function action = (currentStack, pushNewInfo) {
        pushNewInfo();
        markFullScreen(names, configFunc, !persist);
      };
      if (persist) {
        _stack.last._nextPushAction = action;
      } else {
        _stack.last._nextOncePushAction = action;
      }
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    super.didPush(route, previousRoute);
    MXPageInfo info = MXPageInfo(route.settings.name);
    if (_stack.length > 0) {
      print('Trigger AutoHide');
      _stack.last.push(_stack, () {
        _stack.add(info);
      });
    } else {
      _stack.add(info);
    }
    print('MX ${route.settings.name}');
    print('MX Push $runtimeType $hashCode Last info:$info Stack:$_stack');
    if (_stack.length > 1) {
      updateNativePanGestureState();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) {
    super.didPop(route, previousRoute);
    MXPageInfo info = _stack.removeLast();
    if (info != null) {
      info.pop(_stack);
    }
    print('Pop $runtimeType $hashCode \nLast info:$info \nStack:$_stack');
    updateNativePanGestureState();
    if (_stack.length == 0) {
      if (MixStack.of(navigator.context) != null) {
        MixStack.of(navigator.context).stackExchange.popNative(pageAddress);
      }
    }
  }
}
