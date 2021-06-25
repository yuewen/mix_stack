import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'mix_stack.dart';
import 'route_observer.dart';

typedef NativeOverlayConfigsAdjustFunction = void Function(List<NativeOverlayConfig> configs,
    {required bool hideOverlay});
const String MXOverlayNameTabBar = "tabBar";

class NativeOverlayInfo {
  final Rect rect;
  final bool hidden;
  NativeOverlayInfo(Map infoDict)
      : hidden = infoDict['hidden'],
        rect = Rect.fromLTWH(infoDict['x'], infoDict['y'], infoDict['width'], infoDict['height']);

  @override
  bool operator ==(other) {
    return (other is NativeOverlayInfo) && other.rect == rect && other.hidden == hidden;
  }

  @override
  int get hashCode => rect.hashCode ^ hidden.hashCode;
}

///Behavior configuration for NativeOverlay
///
///name: the name defined in native client code, please sync with other developer to get this name
///
///alpha: NativeOverlay's alpha parameters
///
///hidden: NativeOverlay's hidden situation, true for hide, false for show
///
///needsAnimation: whether this configuration needs an animated transition or not
class NativeOverlayConfig {
  bool hidden;
  double alpha;
  bool needsAnimation;
  String name;
  NativeOverlayConfig({required this.name, this.alpha = 1.0, this.hidden = false, this.needsAnimation = true});
  Map<String, dynamic> get dict {
    return {'hidden': hidden ? 1 : 0, 'alpha': alpha, 'animation': needsAnimation ? 1 : 0};
  }
}

class NativeOverlayReplacer extends StatefulWidget {
  final Widget child;
  final List<String> autoHidesOverlayNames;
  NativeOverlayReplacer({Key? key, required this.child, this.autoHidesOverlayNames = const []}) : super(key: key);

  static NativeOverlayReplacerState? of(BuildContext context) {
    final NativeOverlayReplacerState? replacer = context.findAncestorStateOfType<NativeOverlayReplacerState>();
    return replacer;
  }

  static NativeOverlayReplacer autoHidesTabBar({required Widget child}) {
    return NativeOverlayReplacer(
      child: child,
      autoHidesOverlayNames: [MXOverlayNameTabBar],
    );
  }

  @override
  NativeOverlayReplacerState createState() => NativeOverlayReplacerState();
}

class NativeOverlayReplacerState extends State<NativeOverlayReplacer> {
  Uint8List _overflowData = Uint8List(0);
  Uint8List _cacheflowData = Uint8List(0);
  Uint8List get overflowData => _overflowData;
  bool triggerByOthers = true;
  set overflowData(Uint8List list) {
    setState(() {
      triggerByOthers = false;
      _overflowData = list;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.autoHidesOverlayNames.length > 0) {
      MixStack.getOverlayNames(context).then((List<String> value) {
        registerAutoPushHiding(
            value.where((String element) => widget.autoHidesOverlayNames.contains(element.split('-').last)).toList(),
            persist: true);
        registerLock = false;
      });
    } else {
      registerLock = false;
    }
  }

  bool _registerLock = true;
  set registerLock(bool lock) {
    if (_registerLock == lock) {
      return;
    }
    setState(() {
      triggerByOthers = false;
      _registerLock = lock;
    });
  }

  bool get registerLock => _registerLock;

  void registerAutoPushHiding(List<String> names,
      {required bool persist, NativeOverlayConfigsAdjustFunction? adjustConfigs}) async {
    MXRouteObserver observer = MXRouteObserver.of(context)!;
    MixStack.of(context)!.overlayTexture(context, names).then((value) {
      _cacheflowData = value;
    });
    final configuration = (List<NativeOverlayConfig> configs, {required bool hideOverlay}) async {
      if (hideOverlay) {
        if (_cacheflowData.length > 0) {
          overflowData = _cacheflowData;
        } else {
          overflowData = await MixStack.of(context)!.overlayTexture(context, names);
        }
      } else {
        overflowData = Uint8List(0);
      }
      if (adjustConfigs != null) {
        adjustConfigs(configs, hideOverlay: hideOverlay);
      }
      Future.delayed(Duration(milliseconds: hideOverlay ? 100 : 0), () {
        _configOverlays(configs);
      });
    };

    observer.registerAutoPushHiding(context, names, configuration, persist: persist);
  }

  void _configOverlays(List<NativeOverlayConfig> configs) {
    Map<String, dynamic> queries = {};
    for (var config in configs) {
      queries[config.name] = config.dict;
    }
    MixStack.configOverlays(context, queries);
  }

  /// Use for manually config Native Overlay
  void configOverlays(List<NativeOverlayConfig> configs) {
    MixStack.getOverlayNames(context).then((List<String> value) {
      configs.forEach((element) {
        element.name = value.where((name) => name.contains(element.name)).toList().last;
      });
      _configOverlays(configs);
    });
  }

  Timer? delayTimer;

  @override
  Widget build(BuildContext context) {
    if (triggerByOthers) {
      delayTimer?.cancel();
      delayTimer = Timer(Duration(milliseconds: 300), () {
        final offstage = context.findAncestorWidgetOfExactType<Offstage>();
        if (offstage != null) {
          if (!offstage.offstage) {
            MixStack.getOverlayNames(context).then((List<String> value) async {
              final names = value
                  .where((String element) => widget.autoHidesOverlayNames.contains(element.split('-').last))
                  .toList();
              _cacheflowData = await MixStack.of(context)!.overlayTexture(context, names);
            });
          }
        }
      });
    }
    var stacks = <Widget>[];
    if (!registerLock) {
      stacks.add(widget.child);
      if (overflowData.length > 0) {
        stacks.add(IgnorePointer(child: Image.memory(overflowData)));
      }
    }
    triggerByOthers = true;
    return Stack(children: stacks);
  }

  @override
  void dispose() {
    _overflowData = Uint8List(0);
    delayTimer?.cancel();
    super.dispose();
  }
}
