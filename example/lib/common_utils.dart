import 'dart:math';

import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final MethodChannel goToNativeChannel = MethodChannel('goto_native_channel');
final MethodChannel eventChannel = MethodChannel('eventChannel');
final router = FluroRouter();

MaterialColor randomColor() {
  return Colors.primaries[Random().nextInt(Colors.primaries.length)];
}

void goFlutterPage(String route) {
  goToNativeChannel.invokeListMethod('go', {'route': route});
}
