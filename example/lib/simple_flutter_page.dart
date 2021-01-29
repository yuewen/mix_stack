import 'package:flutter/material.dart';
import 'package:mix_stack/mix_stack.dart';
import 'package:mix_stack_example/common_utils.dart';

class SimpleFlutterPage extends StatefulWidget {
  final String route;
  SimpleFlutterPage(this.route);

  @override
  _SimpleFlutterPageState createState() => _SimpleFlutterPageState();
}

class _SimpleFlutterPageState extends State<SimpleFlutterPage> {
  @override
  void initState() {
    super.initState();
    if (!Navigator.of(context).canPop()) {
      PageContainer.of(context).addListener('popToTab', (query) {
        var data = query['query_data'];
        print('MixStack get event data: $data');
        Navigator.of(context).popUntil((route) => route.settings.name != '/');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MixStack'), centerTitle: true),
      body: ButtonTheme(
        minWidth: 200.0,
        buttonColor: Colors.grey[300],
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: _generateChildren(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _generateChildren(BuildContext context) {
    List<Widget> children = [
      SizedBox(height: 20),
      Container(
        width: MediaQuery.of(context).size.width - 20,
        height: 64,
        decoration: new BoxDecoration(color: randomColor()),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Flutter page', style: TextStyle(fontSize: 20, color: Colors.white)),
            Text(
              'hashCode:${this.hashCode}',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
      SizedBox(height: 50),
      RaisedButton(
        onPressed: () => router.navigateTo(context, widget.route),
        child: Text('Push Page in Flutter'),
      ),
      RaisedButton(
        onPressed: () => router.pop(context),
        child: Text('Pop Page'),
      ),
      RaisedButton(
        onPressed: () => goFlutterPage('/native'),
        child: Text('Open Native Page'),
      ),
    ];

    if (widget.route == '/clear_stack') {
      children.add(
        RaisedButton(
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.settings.name == '/');
            eventChannel.invokeMethod('go_to_tab');
          },
          child: Text('Back to Native Tab 2'),
        ),
      );
    }
    return children;
  }
}
