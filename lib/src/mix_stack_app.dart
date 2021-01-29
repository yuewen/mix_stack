import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'stack_exchange.dart';
import 'mix_stack.dart';
import 'pages.dart';

final StackExchange stackExchange = StackExchange();

///Entry Widget for MixStack based application
class MixStackApp extends StatefulWidget {
  final Route Function(BuildContext context, String path) routeBuilder;
  final NavigatorObserversBuilder observersBuilder;
  final CustomPopHandler customPopHandler;
  final String debugRoot;

  ///
  /// Initializes [key] for subclasses.
  ///
  /// [routeBuilder] for MixStack to matching route and build root widget
  ///
  /// [observersBuilder] for building addional Navigator Observers
  ///
  /// [customPopHandler] for replace default Navigator.pop action
  ///
  /// [debugRoot] are using for directly run app without native support, so MixStack can have a root to start presenting
  MixStackApp({Key key, @required this.routeBuilder, this.observersBuilder, this.customPopHandler, this.debugRoot})
      : super(key: key);
  @override
  MixStackAppState createState() => MixStackAppState();
}

class MixStackAppState extends State<MixStackApp> {
  @override
  Widget build(BuildContext context) {
    return MixStack(
        stackExchange: stackExchange,
        child: Pages(
            command: stackExchange.pagesCommand,
            routeForPath: widget.routeBuilder,
            observersBuilder: widget.observersBuilder,
            customPopHandler: widget.customPopHandler,
            debugRoot: widget.debugRoot));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (kDebugMode) {
      stackExchange.updatePages();
    }
  }
}
