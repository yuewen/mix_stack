import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AutofocusPageSmoother extends StatefulWidget {
  final Widget child;
  final focusNode = FocusNode();
  AutofocusPageSmoother({Key key, this.child}) : super(key: key);
  @override
  _AutofocusPageSmootherState createState() => _AutofocusPageSmootherState();
}

class _AutofocusPageSmootherState extends State<AutofocusPageSmoother> {
  Timer _timer;
  bool _didCancelAutoFocus = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //Code to handle keyboard entry issue
    if (!_didCancelAutoFocus) {
      _didCancelAutoFocus = true;
      FocusScope.of(context).autofocus(widget.focusNode);
      _timer = Timer(Duration(milliseconds: 800), () {
        for (var node in FocusScope.of(context).children) {
          if (node.context != null) {
            if (node.context.widget is EditableText) {
              EditableText a = node.context.widget as EditableText;
              if (a.autofocus) {
                node.requestFocus();
                break;
              }
            }
          }
        }
      });
    } else {
      if (!_timer.isActive) {
        _timer.cancel();
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Container(child: widget.child);
  }
}
