import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mix_stack_example/common_utils.dart';

class TestMain extends StatefulWidget {
  @override
  _TestMainState createState() => _TestMainState();
}

class _TestMainState extends State<TestMain> {
  LinkedHashMap<String, VoidCallback> actionMap;
  List<String> actionKeys;
  @override
  void initState() {
    super.initState();
    actionMap = _generateActionMap();
    actionKeys = actionMap.keys.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MixStack Examples'),
        centerTitle: true,
        backgroundColor: Colors.grey,
        automaticallyImplyLeading: false,
      ),
      body: ListView.separated(
        itemCount: actionMap.length,
        separatorBuilder: (BuildContext context, int index) => Divider(
          height: 1,
          indent: 10,
          endIndent: 10,
          thickness: 0.1,
          color: Colors.blueGrey,
        ),
        itemBuilder: (context, index) => _buildListTile(context, index),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, int index) {
    String key = actionKeys[index];
    return ListTile(
      onTap: actionMap[key],
      title: Text(key, style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.normal)),
      trailing: Icon(Icons.keyboard_arrow_right, color: Colors.grey, size: 25.0),
    );
  }

  LinkedHashMap<String, VoidCallback> _generateActionMap() {
    LinkedHashMap<String, VoidCallback> map = new LinkedHashMap();
    map['Open native Flutter container'] = () => goFlutterPage('/simple_flutter_page');
    map['Multiple Tab support'] = () => goFlutterPage('/tab');
    map['Area inset adjustment'] = () => goFlutterPage('/area_inset');
    map['Flutter popup covering native UI'] = () => goFlutterPage('/popup_window');
    if (Platform.isIOS) {
      map['Using event to navigate VCs'] = () => goFlutterPage('/clear_stack');
    } else {
      map['Using event to handle TabBar index'] = () => goFlutterPage('/clear_stack');
    }
    if (Platform.isIOS) {
      map['Module Test With ios'] = () => goFlutterPage('/test_list');
    }
    return map;
  }
}
