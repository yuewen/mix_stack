import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'stack_exchange.dart';
import 'mix_stack.dart';
import 'pages.dart';

final StackExchange stackExchange = StackExchange();

class MixStackApp extends StatefulWidget {
  final Route Function(BuildContext context, String path) routeBuilder;
  final NavigatorObserversBuilder? observersBuilder;
  final CustomPopHandler? customPopHandler;
  final String? debugRoot;

  MixStackApp({Key? key, required this.routeBuilder, this.observersBuilder, this.customPopHandler, this.debugRoot})
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
