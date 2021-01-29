import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'route_observer.dart';
import 'helper.dart';
import 'stack_exchange.dart';

enum PagesCommandType { update, pop, query, updateInfo, event, resetPanGesture }

class PageInfo {
  List<String> history;
}

class PagesCommand extends ChangeNotifier {
  List<String> _pages = [];
  String _currentPage = '';
  PagesCommandType type;
  bool popResult = false;
  String pageNavQueryAddr;
  PageInfo pageNavInfo;
  String targetPage = '';
  PageContainerInfo containerInfo;
  String eventName = '';
  Map<String, dynamic> eventQuery;

  List<String> get pages => _pages;
  String get currentPage => _currentPage;
  void update(List<String> pgs, String current) {
    print('PagesCommand Update:$pgs, Current:$current');
    _currentPage = current;
    _pages = pgs;
    type = PagesCommandType.update;
    notifyListeners();
  }

  void updateInfo(String target, PageContainerInfo info) {
    print('PagesCommand Update Info:$target');
    targetPage = target;
    containerInfo = info;
    type = PagesCommandType.updateInfo;
    notifyListeners();
  }

  bool popPage(String page) {
    type = PagesCommandType.pop;
    notifyListeners();
    return popResult;
  }

  bool exist(String addr) {
    final addrs = _pages.map((e) => e.address).toList();
    return addrs.contains(addr);
  }

  PageInfo pageNavigatorInfo(String addr) {
    if (addr == null) {
      return null;
    }
    type = PagesCommandType.query;
    pageNavQueryAddr = addr;
    notifyListeners();
    return pageNavInfo;
  }

  void pageEvent(String addr, String event, Map<String, dynamic> query) {
    if (addr == null) {
      return null;
    }
    targetPage = addr;
    eventName = event;
    eventQuery = query;
    type = PagesCommandType.event;
    notifyListeners();
  }

  void resetPanGesture() {
    type = PagesCommandType.resetPanGesture;
    notifyListeners();
  }
}

class PageContainerInfo extends ChangeNotifier {
  PageContainerInfo(Map<String, dynamic> dict) : super() {
    if (dict != null) {
      _insets = EdgeInsets.fromLTRB(dict['left'], dict['top'], dict['right'], dict['bottom']);
    }
  }
  EdgeInsets _insets = EdgeInsets.zero;
  EdgeInsets get insets => _insets;

  update(PageContainerInfo anotherInfo) {
    if (anotherInfo == null) {
      return;
    }
    print('PageContainerInfo ${anotherInfo.insets}');
    if (_insets != anotherInfo.insets) {
      _insets = anotherInfo.insets;
      notifyListeners();
    }
  }
}

typedef EventHandler = void Function(Map<String, dynamic> query);

class PageContainer extends InheritedWidget {
  final PageContainerInfo info = PageContainerInfo(null);
  PageContainer({Widget child}) : super(child: child);

  static PageContainer of(BuildContext context) {
    return context.getElementForInheritedWidgetOfExactType<PageContainer>().widget;
  }

  final Map<String, ObserverList<EventHandler>> _listeners = <String, ObserverList<EventHandler>>{};
  VoidCallback addListener(String eventName, EventHandler handler) {
    ObserverList<EventHandler> list = _listeners[eventName];
    if (list == null) {
      list = ObserverList<EventHandler>();
      _listeners[eventName] = list;
    }
    list.add(handler);
    return () {
      list.remove(handler);
    };
  }

  void removeListener(String eventName, EventHandler handler) {
    if (_listeners[eventName] != null) {
      _listeners[eventName].remove(handler);
    }
  }

  void trigger(String eventName, Map<String, dynamic> query) {
    if (_listeners[eventName] != null) {
      for (var item in _listeners[eventName]) {
        item(query);
      }
    }
  }

  @override
  bool updateShouldNotify(PageContainer old) {
    return false;
  }
}

class Pages extends StatefulWidget {
  final PagesCommand command;
  final PageBuilderForRoute routeForPath;
  final NavigatorObserversBuilder observersBuilder;
  final CustomPopHandler customPopHandler;
  final String debugRoot;
  Pages(
      {Key key,
      @required this.command,
      @required this.routeForPath,
      this.observersBuilder,
      this.customPopHandler,
      this.debugRoot});

  @override
  PagesState createState() => PagesState();
}

class PagesState extends State<Pages> {
  List<String> _pages = [];
  String _currentPage = '';
  Map<String, MXRouteObserver> _mxObserverMaps = {};
  Map<String, List<NavigatorObserver>> _otherObserverMaps = {};
  Map<String, GlobalKey<State>> _gKeyMaps = {};
  Map<String, PageContainer> _cacheWidgets = {};
  Map<String, FocusScopeNode> _focusNodes = {};
  void loadPages() {
    _pages = widget.command.pages;
    _currentPage = widget.command.currentPage;
    print('----mixstack loadpage $_pages $_currentPage');
    List<String> addresses = _pages.map((e) => e.address).toList();
    _mxObserverMaps.removeWhere((key, value) => !addresses.contains(key));
    _otherObserverMaps.removeWhere((key, value) => !addresses.contains(key));
    _gKeyMaps.removeWhere((key, value) => !addresses.contains(key));
    _cacheWidgets.removeWhere((key, value) => !addresses.contains(key));
    _focusNodes.removeWhere((key, value) => !addresses.contains(key));
    for (var page in _pages) {
      _mxObserverMaps.putIfAbsent(page.address, () => MXRouteObserver(pageAddress: page.address));
      _otherObserverMaps.putIfAbsent(page.address, () {
        if (widget.observersBuilder != null) {
          return widget.observersBuilder();
        } else {
          return [];
        }
      });
      _gKeyMaps.putIfAbsent(page.address, () => GlobalKey<State>());
      _focusNodes.putIfAbsent(page.address, () => FocusScopeNode(debugLabel: page));
    }
  }

  void commandDidUpdate() {
    if (widget.command.type == PagesCommandType.update) {
      setState(() {
        loadPages();
      });
    } else if (widget.command.type == PagesCommandType.pop) {
      final observer = _mxObserverMaps[widget.command.currentPage.address];
      if (observer != null) {
        if (observer.isRoot) {
          widget.command.popResult = false;
        } else {
          if (widget.customPopHandler != null) {
            widget.customPopHandler(observer.navigator.context);
          } else {
            observer.navigator.pop();
          }
          widget.command.popResult = true;
        }
      } else {
        assert(false, 'The current page should be contained in Observer Maps!!!');
      }
    } else if (widget.command.type == PagesCommandType.query) {
      final observer = _mxObserverMaps[widget.command.pageNavQueryAddr.address];
      if (observer == null) {
        widget.command.pageNavInfo = null;
      } else {
        final info = PageInfo();
        info.history = observer.history;
        widget.command.pageNavInfo = info;
      }
    } else if (widget.command.type == PagesCommandType.updateInfo) {
      final addr = widget.command.targetPage.address;
      if (_cacheWidgets[addr] != null) {
        _cacheWidgets[addr].info.update(widget.command.containerInfo);
      }
    } else if (widget.command.type == PagesCommandType.event) {
      final addr = widget.command.targetPage.address;
      final event = widget.command.eventName;
      final query = widget.command.eventQuery;
      if (_cacheWidgets[addr] != null) {
        _cacheWidgets[addr].trigger(event, query);
      }
    } else if (widget.command.type == PagesCommandType.resetPanGesture) {
      _mxObserverMaps[_currentPage.address].updateNativePanGestureState();
    }
  }

  @override
  void initState() {
    super.initState();
    loadPages();
    widget.command.addListener(commandDidUpdate);
    print('Init Pages');
    if (kDebugMode) {
      Future.delayed(Duration(seconds: 1)).then((value) {
        //If root have no connection to MXContainerController, set to debugRoot
        if (kDebugMode && widget.debugRoot != null && _pages.length == 0) {
          final fakeRoot = widget.debugRoot + "?addr=999999";
          widget.command.update([fakeRoot], fakeRoot);
        }
      });
    }
  }

  @override
  void dispose() {
    widget.command.removeListener(commandDidUpdate);
    print('Dispose Pages');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_focusNodes[_currentPage.address] != null) {
      FocusScope.of(context).setFirstFocus(_focusNodes[_currentPage.address]);
    }
    List<Widget> children = [];
    for (var item in _pages) {
      PageContainer child = _cacheWidgets[item.address];
      if (child == null) {
        List<NavigatorObserver> obs = _otherObserverMaps[item.address];
        obs.add(_mxObserverMaps[item.address]);
        // Fix missing hero animation: https://stackoverflow.com/a/60729122/4968633
        obs.add(HeroController());
        child = PageContainer(
          child: Navigator(
              observers: obs,
              onGenerateRoute: (RouteSettings settings) {
                if (settings.name == '/') {
                  return widget.routeForPath(context, item.path);
                } else {
                  return widget.routeForPath(context, settings.name);
                }
              }),
        );
        if (widget.command.targetPage == item) {
          child.info.update(widget.command.containerInfo);
          Timer(Duration(milliseconds: 10), () {
            _mxObserverMaps[item.address].updateNativePanGestureState();
          });
        }
        _cacheWidgets[item.address] = child;
      }
      Offstage stage = Offstage(
          key: _gKeyMaps[item.address],
          offstage: item != _currentPage,
          child: FocusScope(node: _focusNodes[item], child: child));
      children.add(stage);
    }
    if (children.length == 0) {
      children.add(PageContainer(
        child: Container(),
      ));
    }
    return Container(
        color: Colors.transparent,
        child: Stack(
          children: children,
          textDirection: TextDirection.ltr,
        ));
  }
}
