![alt text](.images/logo.png "MixStack Logo")

[中文 README](README_cn.md)

# MixStack

MixStack lets you connects Flutter smoothly with Native pages, supports things like Multiple Tab Embeded Flutter View, Dynamic tab changing, and more. You can enjoy a smooth transition from legacy native code to Flutter with it.

## MixStack basic structure

![alt text](.images/mixstack_structure.png "MixStack strucure")

As above picture shows, each Native Flutter Container provided by MixStack, contains an independent Flutter Navigator to maintain page management, through Stack Widget inside Flutter to let Flutter render the current Native Flutter Container belonged Flutter page stack. With this approach, Flutter and Native's page navigation, and all kind of View interaction became possible and manageable.

## Get Start

Hybrid development may sometimes a bit overwhelming and bit complicated, please have some patience.

### Installation

Add mixstack dependency in pubspec.yaml

```yaml
dependencies:
  mix_stack: <lastest_version>
```

Run ```flutter pub get``` in your project folder

Run ```pod install``` in your iOS folder

Add in Android's `build.gradle`:

```gradle
implementation rootProject.findProject(":mix_stack")
```

## How to Integrate

### On Flutter Side

Find your root Widget inside your Flutter project, and add MixStackApp in your initial Widget's build, pass your route generation function to MixStackApp, like below:

```dart
class MyApp extends StatelessWidget {
  void defineRoutes(Router router) {
    router.define('/test', handler: Handler(handlerFunc: (ctx, params) => TestPage()));
  }

  @override
  Widget build(BuildContext context) {
    defineRoutes(router);
    return MixStackApp(routeBuilder: (context, path) {
      return router.matchRoute(context, path).route; //传回 route
    });
  }
}
```

Flutter part is done。For detail usage please check [Flutter side usage in detail](#flutter_usage)

### On iOS Side

After FlutterEngine excute Run，set engine to MXStackExchange

```objc
//AppDelegate.m
[flutterEngine run];
[MXStackExchange shared].engine = flutterEngine;
```

iOS part is done。For detail usage please check [iOS side usage in detail](#ios_usage)

### On Android Side

Make sure in Application's `onCreate()` execute:

```java
MXStackService.init(application);
```

Android part is done。For detail usage please check [Android side usage in detail](#android_usage)

## Flutter Side Usage

### Listen to container's Navigator

If you need to listen to navigator inside container, you can add additional observer builder in MixStackApp initialization.

```dart
MixStackApp(
      routeBuilder: (context, path) {
        return router.matchRoute(context, path).route;
      },
      observersBuilder: () {
        return [CustomObserver()];
      },
    )
```

### Control native UI display

When you have native view mixed with your Flutter container, sometimes you may want to hide those native views such like you push a new page inside Flutter, something like picture shows:
![alt text](.images/native_replacer_problem.png "Native Replacer Target Problem")

You can do so by using `NativeOverlayReplacer`.

When you need to achieve this, you just need to wrap your page's root widget with NativeOverlayReplacer, and fill in the Native Overlay view's name that you registered in native.

```dart
@override
Widget build(BuildContext context) {
  return NativeOverlayReplacer(child:Container(), autoHidesOverlayNames:[MXOverlayNameTabBar, 'NativeOverlay1', 'NativeOverlay2']);
}
```

We also offer a simple interface to hide MixStack offered Native Tab to simplify the common needs that you embedded a Fluter tab and that tab have its own navigation stack, and when pushed, you need to hide native tab bar.

```dart
@override
Widget build(BuildContext context) {
  return NativeOverlayReplacer.autoHidesTabBar(child:Container());
}
```

If you want fine tuned control, you can tweak the `persist` attribute

```dart
List<String> names = await MixStack.getOverlayNames(context); //Get current native overlay names
names = names.where((element) => element.contains('tabBar')).toList();
NativeOverlayReplacer.of(context).registerAutoPushHiding(names, persist: false); //If we hope this register to work once for single push action, we set persist false, if we want it to work everytime we push a page, set it to true
```

After above code setting, everytime a page pushing action will trigger setting of native UI components, also offer a native UI components snapshot inside Flutter to offer smooth animation and let user ignore the hybrid structure.

### Direct pop the current Flutter container

```dart
MixStack.popNative(context);
```

### Force adjust current Flutter container's back gesture status

MixStack handle this very well all the time, but sometimes you may needs this capability, make sure you don't shoot your foot.

```dart
MixStack.enableNativePanGensture(context, true);
```

### Flutter respond to current container event

Sometimes you may need Flutter code to respond to specific native call, and this achieves that.

```dart
//Some Widget code
void initState() {
  super.initState();
  //Root page register a navigator popToRoot action
  if (!Navigator.of(context).canPop()) {
    PageContainer.of(context).addListener('popToTab', (query) {
      Navigator.of(context).popUntil((route) {
        return route.isFirst;
      });
    });
  }
}
```

### Manually adjust Native Overlay

```dart
NativeOverlayReplacer.of(ctx)
                .configOverlays([NativeOverlayConfig(name: MXOverlayNameTabBar, hidden: false, alpha: 1)]);
```

#### Advance: Subsribe to Flutter App lifecycle

MixStack offers whole Flutter App lifecycle for listen, due to some structure difference than original Flutter lifecycle, if you need to do visibility check or other stuff, consider using this.

```dart
    MixStack.lifecycleNotifier.addListener(() {
      print('Lifecycle:${MixStack.lifecycleNotifier.value}');
    });
```

#### Advance: Subscribe to current container's SafeAreaInsets change

If Flutter side UI components wants to know Native container insets change, you can do the follows:

```dart
  PageContainerInfo containerInfo;
  @override
  void initState() {
    super.initState();
    //Get current container info, and subscribe changes
    containerInfo = PageContainer.of(context).info;
    bottomInset = containerInfo.insets.bottom;
    containerInfo.addListener(updateBottomInset);
  }

  @override
  void dispose() {
    //Cancel subscription
    containerInfo.removeListener(updateBottomInset);
    super.dispose();
  }

  updateBottomInset() {
    bottomInset = PageContainer.of(context).info.insets.bottom;
  }
```

Beware that this subscription only passing SafeAreaInsets change, if you want to know more about Native Container, use `MixStack.overlayInfos` to get infos.

#### Advance: Get current container's native overlay attributes for more customization

```dart
  double bottomInset = 0;
  @override
  Widget build(BuildContext context) {
    //Get native overlay infos to adjust UI inset
    MixStack.overlayInfos(context, [MXOverlayNameTabBar], delay: Duration(milliseconds: 400)).then((value) {
      if (value.keys.length == 0) {
        return;
      }
      final info = value[MXOverlayNameTabBar];
      double newInset = info.hidden == false ? info.rect.height : 0;
      if (bottomInset != newInset) {
        setState(() {
          bottomInset = newInset;
        });
      }
    });
    return Stack(
          children: [
            Positioned(
              bottom: bottomInset + 10,
              right: 20,
              child: FloatingActionButton(
                onPressed: () {
                  print("Floating button follow insets move");
                },
              ),
            ),
          ],
        );
  }
```

## iOS side usage

### Put multiple Flutter page in TabBarController

MixStack offsers `MXAbstractTabBarController` for subclass，mainly for adjusting tab insets and handle tabbar visibility.If you wants more, you can implement one yourself.

When you want to add one or more Flutter Views, please use `MXContainerViewController` as Tab's child viewController. If somehow your `MXContainerViewController` was gonna embedded inside another VC, please mark the root VC with our custom tag

```objc
vc.containsFlutter = YES;
```

The example code of adding Flutter Pages into Tab shows like below:

```objc
TabViewController *tabs = [[TabViewController alloc] init];
UITabBarItem *item1 = [[UITabBarItem alloc] initWithTitle:@"Demo1" image:[UIImage imageNamed:@"icon1"] tag:0];
UITabBarItem *item2 = [[UITabBarItem alloc] initWithTitle:@"Demo2" image:[UIImage imageNamed:@"icon2"] tag:0];
MXContainerViewController *flutterVC1 = [[MXContainerViewController alloc] initWithRoute:@"/test" barItem:item1];
MXContainerViewController *flutterVC2 = [[MXContainerViewController alloc] initWithRoute:@"/test_2" barItem:item2];
SomeNativeVC *nativeVC = [[SomeNativeVC alloc] init]; //Of course you can add normal native VC ^_^
[tabs setViewControllers:@[flutterVC1, flutterVC2, nativeVC]];
```

### Flutter Container as normal VC

MixStack's `MXContainerViewController` can use in normal scene.Just passing the Flutter route matching the target page.

```objc
MXContainerViewController *flutterVC = [[MXContainerViewController alloc] initWithRoute:@"/test"]
[self.navigationController pushViewController:flutterVC animated:YES];
```

### Pop Flutter Container

Assume current page is Flutter Container，and you're not sure about whether you need to pop this VC or you need to pop one of the page contains in the container, you can try like below:

```objc
[[MXStackExchange shared] popPage:^(BOOL popSuccess) {
  if (!popSuccess) {
    [self.navigationController popViewControllerAnimated:YES];
  }
}];
```

If result is true, means inside Flutter Container's navigation stack there's a page being popped, and there's still pages there. If result is false, then it means that current Container contains navigation stack only have root page left, so you can pop the whole container safely.

### Submit event to Flutter Container's Flutter stack

```objc
MXContainerViewController *flutterVC = (MXContainerViewController *)self.tab.viewControllers.lastObject;
[flutterVC sendEvent:@"popToTab" query:@{ @"hello" : @"World" }];
```

### Get current Flutter Container's navigation history

If returns nil, that means current Container contains zero page.

```objc
MXContainerViewController *flutterVC = ...;
[flutterVC currentHistory:^(NSArray<NSString *> *_Nullable history) {
    NSLog(@"%@", history);
}];
```

### Lock current container engine rendering

Sometimes we need to show some UI above Flutter Container, like some popup window.Due to Flutter rendering mechanism, when you do that, Flutter View will black out. So we offer a snapshot mechanism, when you set `showSnapshot` to true, the whole view will be snapshoted and freeze.When you done your business, you can set it back to false.

```objc
MXContainerViewController *fc = ...
fc.showSnapshot = YES;
```

## iOS advance usage & Q&A

### Potential problems in multiple Window usage

In some circumstance, iOS side may use multiple window way to manage UI, it may happened that two window both contains Flutter Container, and it is knowned that different window's VC won't receive callback for visibility. When you meets this situation, you can use codes like below to manually guide MixStack to put FlutterEngine's viewController back to the business correct one.

```objc
[MXStackExchange shared].engineViewControllerMissing = ^id<MXViewControllerProtocol> _Nonnull(NSString *_Nonnull previousRootRoute) {
  return someFlutterVCFitsYourBusiness;
};
```

### Custom support for NativeOverlayReplacer

Make sure the  Flutter Container VC implement [MXOverlayHandlerProtocol](ios/Classes/MXOverlayHandlerProtocol.h#L21) 。
You can check related example code in [MXAbstractTabBarController](ios/Classes/MXAbstractTabBarController.m#L81) 。

### What is ignoreSafeareaInsetsConfig

In MixStack's MXOverlayHandlerProtocol, there's one method called `ignoreSafeareaInsetsConfig`, this method based on a fact that, **in most circumstance, MixStack suggest to set overlay causing SafeAreaInsets to zero**，that is to say, ，Flutter rendering layer should know nothing about native UI's SafeAreaInsets change, the reason for this suggestion is that SafeAreaInsets changing can cause Flutter re-render everything, for complex UI, this is costy and may cause weired bug. So we suggest in specific Container you implement `ignoreSafeareaInsetsConfig`, then inside Flutter use `MixStack.of(context).overlayInfos` to get the overlay changes info for UI adjustment.

## Android Usage
### MXFlutterActivity usage

We offer `MXFlutterActivity` for direct use, just passing target page route registered in Flutter

```java
Intent intent = new Intent(getActivity(), MXFlutterActivity.class);
intent.putExtra(ROUTE, "/test_blue"); //Passing the targeted page route registered in Flutter
startActivity(intent);
```

### MXFlutterFragment usage inside activity and Tab usage

We offer `MXFlutterFragment` for fragment usage, it's like `MXFlutterActivity`, also need passing target page route registered in Flutter

```java
MXFlutterFragment flutterFragment = new MXFlutterFragment();
Bundle bundle = new Bundle();
bundle.putString(MXFlutterFragment.ROUTE, "/test_blue");
hxFlutterFragment.setArguments(bundle);
```

For Tab switching，we need controls over `MXFlutterFragment`，for `MXFlutterFragment` 's  host Activity , you need to implement `IMXPageManager` interface, it's only one function, `getPageManager()`, mainly for getting `MXPageManager` in Activity, this serves two purpose:

- **Controls MXFlutterFragment page lifecycle**

- **Offer Flutter page's native UI control capability**

#### Controls MXFlutterFragment page lifecycle

Classic situation: theres's multiple Tab in activity, each point to different Fragment, you need `IMXPageManager`to control which Fragment to display and also set the `MXFlutterFragment` lifecycle right, as below:

```java
private void showFragment(Fragment fg) {
    FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();
    if (currentFragment != fg) {
        transaction.hide(currentFragment);
    }
    if (!fg.isAdded()) {
        transaction.add(R.id.fl_main_container, fg, fg.getClass().getName());
    } else {
        transaction.show(fg);
    }
    transaction.commit();
    currentFragment = fg;
  
    pageManager.setCurrentShowPage(currentFragment); //tell  MixStack which MXFlutterFragment to show
}
```

Since Flutter have different mechanism with Android, we need to override back logic. So in `MXFlutterFragment`'s host Activity we need to add following:

```java
@Override
public void onBackPressed() {
    if (pageManager.checkIsFlutterCanPop()) {
        pageManager.onBackPressed(this);
    } else {
        super.onBackPressed();
    }
}
```

When Activity gets destroy, we need to also notify MixStack through `IMXPageManager`:

```java
@Override
protected void onDestroy() {
    super.onDestroy();
    pageManager.onDestroy();
}
```

#### Managing Flutter Container's native UI

We also use PageManager to achieve this, you can directly intialize one if you don't need to manage native UI, otherwise you need override methods, there's four methods needs to override:

- overlayViewsForNames  get the mapping between view and names
- configOverlay  Config how native overlay view display, aniate, there's default animation
- overlayNames get avaiable names
- overlayView  get overlay views through name

the example are shown below

```java
MXPageManager pageManager = new MXPageManager() {
  @Override
  public List<String> overlayNames() {
    List<String> overlayNames = new ArrayList<>();
    overlayNames.add("tabBar");
    return overlayNames;
  }

  @Override
  public View overlayView(String viewName) {
    if ("tabBar".equals(viewName)) {
      return mBottomBar;
    }
    return null;
  }
};
```

### Submit events to FlutterFragment/FlutterActivity

```java
flutterFragment.sendEvent("popToTab", query);
flutterActivity.sendEvent("popToTab", query);
```

### Get Flutter Container's navigation stack history

```java
pageManager.getPageHistory(new PageHistoryListener() {
    @Override
    public void pageHistory(List<String> history) {
    }
});
```

#### Destroy

Destory when your MainActivity `onDestroy` gets called

```java
MXStackService.getInstance().destroy();
```
