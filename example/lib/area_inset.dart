import 'package:flutter/material.dart';
import 'package:mix_stack/mix_stack.dart';

class TestAreaInset extends StatefulWidget {
  @override
  _TestAreaInsetState createState() => _TestAreaInsetState();
}

class _TestAreaInsetState extends State<TestAreaInset> {
  PageContainerInfo containerInfo;
  @override
  void initState() {
    super.initState();
    containerInfo = PageContainer.of(context).info;
    bottomInset = containerInfo.insets.bottom;
    containerInfo.addListener(updateBottomInset);
  }

  @override
  void dispose() {
    containerInfo.removeListener(updateBottomInset);
    super.dispose();
  }

  updateBottomInset() {
    bottomInset = PageContainer.of(context).info.insets.bottom;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Area Inset'),
      //   centerTitle: true,
      //   backgroundColor: Colors.grey,
      // ),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned(
            bottom: bottomInset + 15,
            right: 20,
            child: Column(
              children: [
                Text('Flutter button', style: TextStyle(color: Colors.grey, fontSize: 13)),
                SizedBox(height: 5),
                FloatingActionButton(
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _bottomInset = 0;
  double get bottomInset => _bottomInset;
  set bottomInset(double inset) {
    setState(() {
      _bottomInset = inset;
    });
  }
}
