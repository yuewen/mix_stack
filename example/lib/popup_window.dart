import 'package:flutter/material.dart';
import 'package:mix_stack/mix_stack.dart';
import 'dart:math';

class TestPopupWindow extends StatelessWidget {
  static const double kMinRadius = 32.0;
  static const double kMaxRadius = 128.0;

  @override
  Widget build(BuildContext context) {
    return NativeOverlayReplacer(
      autoHidesOverlayNames: ["tabBar", "navigationBar"],
      child: Scaffold(
        body: Container(
          alignment: Alignment.center,
          child: Column(
            children: [
              SizedBox(height: 50),
              Container(
                width: MediaQuery.of(context).size.width - 100,
                child: Text(
                  'Click to show popup window, then MixStack will auto hide naive\'s TabBar.',
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 10),
              _buildHero(context, 'images/test.png', 'Moutain')
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, String imageName, String description) {
    return Container(
      width: kMinRadius * 2.0,
      height: kMinRadius * 2.0,
      child: Hero(
        createRectTween: _createRectTween,
        tag: imageName + "${context.hashCode}",
        child: RadialExpansion(
          maxRadius: kMaxRadius,
          child: Photo(
            photo: imageName,
            onTap: () async {
              //Aggregate these into a packed method
              if (NativeOverlayReplacer.of(context) != null) {
                List<String> names = await MixStack.getOverlayNames(context);
                NativeOverlayReplacer.of(context).registerAutoPushHiding(
                  names,
                  persist: false,
                  adjustConfigs: (configs, {hideOverlay}) {
                    for (var c in configs) {
                      c.alpha = hideOverlay ? 0 : 1;
                    }
                  },
                );
              }
              Navigator.of(context).push(
                PhotoGalleryFadeRouter(
                  _buildPage(context, imageName, description),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, String imageName, String description) {
    return GestureDetector(
      onTap: () async {
        Navigator.of(context).pop();
      },
      child: Container(
        color: Colors.black.withAlpha(200),
        child: Center(
          child: Card(
            elevation: 8.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: kMaxRadius * 2.0,
                  height: kMaxRadius * 2.0,
                  child: Hero(
                    createRectTween: _createRectTween,
                    tag: imageName + '${context.hashCode}',
                    child: RadialExpansion(
                      maxRadius: kMaxRadius,
                      child: Photo(photo: imageName),
                    ),
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textScaleFactor: 3.0,
                ),
                const SizedBox(height: 16.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static RectTween _createRectTween(Rect begin, Rect end) {
    return MaterialRectCenterArcTween(begin: begin, end: end);
  }
}

class Photo extends StatelessWidget {
  Photo({Key key, this.photo, this.color, this.onTap}) : super(key: key);

  final String photo;
  final Color color;
  final VoidCallback onTap;

  Widget build(BuildContext context) {
    return Material(
      // Slightly opaque color appears where the image has transparency.
      color: Theme.of(context).primaryColor.withOpacity(0.25),
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints size) {
            return Image.asset(photo, fit: BoxFit.contain);
          },
        ),
      ),
    );
  }
}

class RadialExpansion extends StatelessWidget {
  RadialExpansion({
    Key key,
    this.maxRadius,
    this.child,
  })  : clipRectSize = 2.0 * (maxRadius / sqrt2),
        super(key: key);

  final double maxRadius;
  final clipRectSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Center(
        child: SizedBox(
          width: clipRectSize,
          height: clipRectSize,
          child: ClipRect(child: child),
        ),
      ),
    );
  }
}

class PhotoGalleryFadeRouter extends PageRouteBuilder {
  final Widget widget;

  @override
  bool get opaque => false;

  PhotoGalleryFadeRouter(this.widget)
      : super(
          transitionDuration: Duration(milliseconds: 300),
          pageBuilder: (BuildContext context, Animation<double> animation1, Animation<double> animation2) {
            return widget;
          },
          transitionsBuilder:
              (BuildContext context, Animation<double> animation1, Animation<double> animation2, Widget child) {
            return FadeTransition(
              opacity: Tween(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation1, curve: Curves.fastOutSlowIn),
              ),
              child: child,
            );
          },
        );
}
