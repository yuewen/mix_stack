import 'dart:core';

import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mix_stack/mix_stack.dart';
import 'package:mix_stack_example/present_flutter_page.dart';

import 'common_utils.dart';
import 'simple_flutter_page.dart';
import 'area_inset.dart';
import 'test_main.dart';
import 'popup_window.dart';
import 'page_controller.dart';

void main() {
  runApp(MyApp());
}

class TestObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    print('MixStack test push ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) {
    print('MixStack test pop ${route.settings.name}');
  }
}

class MyApp extends StatelessWidget {
  MyApp() {
    defineRoutes();
  }

  void defineRoute(String route, Handler handler) {
    router.define(
      route,
      handler: handler,
      transitionType: TransitionType.cupertino,
    );
  }

  void defineRoutes() {
    defineRoute(
      '/test_main',
      Handler(handlerFunc: (ctx, params) => TestMain()),
    );
    defineRoute(
      '/simple_flutter_page',
      Handler(
        handlerFunc: (ctx, params) => SimpleFlutterPage('/simple_flutter_page'),
      ),
    );
    defineRoute(
      '/popup_window',
      Handler(
        handlerFunc: (ctx, params) => TestPopupWindow(),
      ),
    );
    defineRoute(
      '/area_inset',
      Handler(
        handlerFunc: (ctx, params) => TestAreaInset(),
      ),
    );
    defineRoute(
      '/clear_stack',
      Handler(
        handlerFunc: (ctx, params) => SimpleFlutterPage('/clear_stack'),
      ),
    );
    defineRoute(
      '/test_list',
      Handler(
        handlerFunc: (ctx, params) => TestPageController(),
      ),
    );
    defineRoute(
      '/present_flutter',
      Handler(
        handlerFunc: (ctx, params) => PrensentFlutter('/present_flutter'),
      ),
    );
    MixStack.lifecycleNotifier.addListener(() {
      print('MixStack lifecycle:${MixStack.lifecycleNotifier.value}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MixStackApp(
        routeBuilder: (context, path) {
          return router.matchRoute(context, path).route;
        },
        observersBuilder: () {
          return [TestObserver()];
        },
        debugRoot: '/test_blue',
      ),
    );
  }
}
