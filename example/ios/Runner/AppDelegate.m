#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import "GeneratedPluginRegistrant.h"
#import "TabViewController.h"
#import "NativeViewController.h"
#import "MoreFunctionViewController.h"
#import <Flutter/Flutter.h>
#import <mix_stack/mix_stack.h>


@interface AppDelegate ()
@property (nonatomic, strong, readonly) FlutterEngine *flutterEngine;
@property (nonatomic, strong) UINavigationController *rootVC;
@property (nonatomic, strong) TabViewController *tab;
@property (nonatomic, strong) UIWindow *floatWindow;
@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
  didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  _flutterEngine = [[FlutterEngine alloc] initWithName:@"engine"];
  [_flutterEngine run];
  [MXStackExchange shared].engine = _flutterEngine;
  [self eventChannel];
  [self nativeRouterChannel];

  MXContainerViewController *flutterMain = [[MXContainerViewController alloc] initWithRoute:@"/test_main"];

  UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:flutterMain];
  nav.navigationBar.hidden = YES;
  self.rootVC = nav;
  self.window.rootViewController = self.rootVC;
  [self.window makeKeyAndVisible];

  [GeneratedPluginRegistrant registerWithRegistry:self.flutterEngine];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (FlutterMethodChannel *)nativeRouterChannel {
  static FlutterMethodChannel *channel;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    channel = [FlutterMethodChannel methodChannelWithName:@"goto_native_channel" binaryMessenger:_flutterEngine.binaryMessenger];
    [channel setMethodCallHandler:^(FlutterMethodCall *_Nonnull call, FlutterResult _Nonnull result) {
      NSString *method = call.method;
      if ([method isEqualToString:@"go"]) {
        NSString *route = call.arguments[@"route"];
        [self navigateToNativePage:route];
      }
    }];
  });
  return channel;
}

- (void)navigateToNativePage:(NSString *)route {
  if ([route isEqualToString:@"/simple_flutter_page"]) {
    MXContainerViewController *simpleFlutter = [[MXContainerViewController alloc] initWithRoute:route];
    [self.rootVC pushViewController:simpleFlutter animated:YES];
  } else if ([route isEqualToString:@"/native"]) {
    NativeViewController *native = [[NativeViewController alloc] init];
    [self.rootVC pushViewController:native animated:YES];
  } else if ([route isEqualToString:@"/tab"] ||
             [route isEqualToString:@"/clear_stack"]) {
    [self initTabViewController:route];
  } else if ([route isEqualToString:@"/popup_window"] ||
             [route isEqualToString:@"/area_inset"]) {
    [self initMoreFunctionController:route];
  } else {
    NSLog(@"MixStack not found: %@", route);
  }
}

- (void)initMoreFunctionController:(NSString *)route {
  MoreFunctionViewController *moreController = [[MoreFunctionViewController alloc] init];
  UITabBarItem *item1 = [[UITabBarItem alloc] initWithTitle:@"Tab" image:[UIImage imageNamed:@"ic_collections"] tag:0];
  [moreController setViewControllers:@[
    [[MXContainerViewController alloc] initWithRoute:route barItem:item1]
  ]];
  [self.rootVC pushViewController:moreController animated:YES];
}

- (void)initTabViewController:(NSString *)route {
  TabViewController *tabController = [[TabViewController alloc] init];
  UITabBarItem *item1 = [[UITabBarItem alloc] initWithTitle:@"Native" image:[UIImage imageNamed:@"ic_collections"] tag:0];
  UITabBarItem *item2 = [[UITabBarItem alloc] initWithTitle:@"Flutter1" image:[UIImage imageNamed:@"ic_collections"] tag:1];
  UITabBarItem *item3 = [[UITabBarItem alloc] initWithTitle:@"Flutter2" image:[UIImage imageNamed:@"ic_collections"] tag:2];

  NativeViewController *native = [[NativeViewController alloc] initWithRoute:route];
  native.tabBarItem = item1;
  MXContainerViewController *f1 = [[MXContainerViewController alloc] initWithRoute:@"/simple_flutter_page" barItem:item2];
  MXContainerViewController *f2 = [[MXContainerViewController alloc] initWithRoute:@"/simple_flutter_page" barItem:item3];
  [tabController setViewControllers:@[ native, f1, f2 ]];
  [self.rootVC pushViewController:tabController animated:YES];
}

- (FlutterMethodChannel *)eventChannel {
  static FlutterMethodChannel *channel;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    channel = [FlutterMethodChannel methodChannelWithName:@"eventChannel" binaryMessenger:_flutterEngine.binaryMessenger];
    [channel setMethodCallHandler:^(FlutterMethodCall *_Nonnull call, FlutterResult _Nonnull result) {
      if ([call.method isEqualToString:@"go_to_tab"]) {
        NSArray *vcs = [self.rootVC.viewControllers subarrayWithRange:NSMakeRange(0, 2)];
        [self.rootVC setViewControllers:vcs animated:YES];
        MXContainerViewController *flutterVC = (MXContainerViewController *)self.tab.viewControllers.lastObject;
        [(UITabBarController *)vcs.lastObject setSelectedIndex:1];
        [flutterVC sendEvent:@"popToTab" query:@{ @"query_data" : @"data from native" }];
      }

    }];
  });
  return channel;
}


@end
