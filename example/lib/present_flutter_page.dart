import 'package:flutter/material.dart';
import 'common_utils.dart';

class PrensentFlutter extends StatefulWidget {
  final String route;
  PrensentFlutter(this.route);

  @override
  _PrensentFlutterState createState() {
    return new _PrensentFlutterState();
  }
}

class _PrensentFlutterState extends State<PrensentFlutter> with SingleTickerProviderStateMixin {
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Container(
        width: MediaQuery.of(context).size.width - 30,
        height: 344,
        child: Column(
          children: [
            Container(
              width: MediaQuery.of(context).size.width - 30,
              height: 64,
              decoration: new BoxDecoration(
                  color: randomColor(),
                  borderRadius: BorderRadius.circular(10),
                  border: new Border.all(color: Colors.black, width: 1)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Flutter page', style: TextStyle(fontSize: 20, color: Colors.white)),
                  Padding(padding: EdgeInsets.only(top: 10)),
                  Text(
                    'hashCode:${this.hashCode}',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
            Padding(padding: EdgeInsets.only(top: 20)),
            new AnimationWidget(),
            Padding(padding: EdgeInsets.only(top: 10)),
            SizedBox(height: 50),
            RaisedButton(
              onPressed: () => router.navigateTo(context, widget.route),
              child: Text('Push Flutter Page', style: TextStyle(fontSize: 18)),
            ),
            RaisedButton(
              onPressed: () => goFlutterPage('/dismiss'),
              child: Text('Dismiss Current', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      )),
    );
  }
}

class AnimationWidget extends StatefulWidget {
  AnimationWidget({Key key}) : super(key: key);

  @override
  _AnimationWidgetState createState() {
    return _AnimationWidgetState();
  }
}

class _AnimationWidgetState extends State<AnimationWidget> with SingleTickerProviderStateMixin {
  bool isStartTrain = true;
  AnimationController _animationController;
  Animation _animation;

  @override
  void initState() {
    _animationController = AnimationController(duration: Duration(seconds: 300), vsync: this);

    _animation = Tween<double>(
      begin: 1,
      end: 300,
    ).animate(_animationController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // 动画完成后反转
          _animationController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          // 反转回初始状态时继续播放，实现无限循环
          _animationController.forward();
        }
      });

    super.initState();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isStartTrain == false) {
          _animationController.forward();
        } else {
          _animationController.stop();
        }
        setState(() {
          isStartTrain = !isStartTrain;
        });
      },
      child: Stack(
        children: [
          Positioned(
            child: Center(
              child: RotationTransition(
                //设置动画的旋转中心
                alignment: Alignment.center,
                //动画控制器
                turns: _animation,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("images/bg_timer.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 33,
            left: MediaQuery.of(context).size.width / 2 - 33,
            child: Center(
                child: Text(
              '${isStartTrain ? "停止" : "开始"}',
              style: TextStyle(color: Colors.white, fontSize: 18),
            )),
          )
        ],
      ),
    );
  }
}
