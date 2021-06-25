#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import "GeneratedPluginRegistrant.h"
#import "TabViewController.h"
#import "NativeViewController.h"
#import "MoreFunctionViewController.h"
#import <Flutter/Flutter.h>
#import <mix_stack/mix_stack.h>
#import "TestListController.h"
#import "FlutterPageViewController.h"

@interface AppDelegate ()<UINavigationControllerDelegate,UITabBarControllerDelegate>
@property (nonatomic, strong, readonly) FlutterEngineGroup *group;
@property (nonatomic, strong, readonly) FlutterEngine *flutterEngine;
@property (nonatomic, strong) UINavigationController *rootVC;
@property (nonatomic, strong) TabViewController *tabViewVC;
@property (nonatomic, strong) UIWindow *floatWindow;
@property (nonatomic, weak) TestListController *testListController;
@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
  didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  _group = [[FlutterEngineGroup alloc] initWithName:@"engine" project:nil];
  _flutterEngine = [_group makeEngineWithEntrypoint:nil libraryURI:nil];
  [_flutterEngine run];
  [MXStackExchange shared].engine = _flutterEngine;
  [self eventChannel];
  [self nativeRouterChannel];

  MXContainerViewController *flutterMain = [[MXContainerViewController alloc] initWithRoute:@"/test_main"];

  UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:flutterMain];
  nav.navigationBar.hidden = YES;
    nav.delegate = self;
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
    }  else if ([route isEqualToString:@"/test_list"] ||[route isEqualToString:@"/dismiss"]){
        [self initPageManagerController:route];
    }
    else {
        NSLog(@"MixStack not found: %@", route);
    }
}

- (void)initPageManagerController:(NSString *)route {
    if ([route isEqualToString:@"/test_list"]) {
        TabViewController *tabController = [[TabViewController alloc] init];
        tabController.delegate = self;
        TestListController *testListController = [[TestListController alloc] initWithFlutterRoute:route];
        UITabBarItem *item1 = [[UITabBarItem alloc] initWithTitle:@"TestList" image:[UIImage imageNamed:@"ic_collections"] tag:0];
        testListController.tabBarItem = item1;
        UITabBarItem *item2 = [[UITabBarItem alloc] initWithTitle:@"FlutterPage" image:[UIImage imageNamed:@"ic_collections"] tag:1];
        MXContainerViewController *flutterPage = [[MXContainerViewController alloc] initWithRoute:@"/test_list" barItem:item2];
        [tabController setViewControllers:@[testListController,flutterPage]];
        tabController.selectedIndex = 0;
        [self.rootVC pushViewController:tabController animated:YES];
        self.testListController = testListController;
    }else if ([route isEqualToString:@"/dismiss"]) {
        [_testListController goFuncDismissFlutter];
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
    tabController.delegate = self;
    UITabBarItem *item1 = [[UITabBarItem alloc] initWithTitle:@"Native" image:[UIImage imageNamed:@"ic_collections"] tag:0];
    UITabBarItem *item2 = [[UITabBarItem alloc] initWithTitle:@"Flutter1" image:[UIImage imageNamed:@"ic_collections"] tag:1];
    UITabBarItem *item3 = [[UITabBarItem alloc] initWithTitle:@"Flutter2" image:[UIImage imageNamed:@"ic_collections"] tag:2];
    NativeViewController *native = [[NativeViewController alloc] initWithRoute:route];
    native.tabBarItem = item1;
    MXContainerViewController *f1 = [[MXContainerViewController alloc] initWithRoute:@"/simple_flutter_page" barItem:item2];
    MXContainerViewController *f2 = [[MXContainerViewController alloc] initWithRoute:@"/simple_flutter_page" barItem:item3];
    [tabController setViewControllers:@[ native, f1, f2 ]];
    tabController.selectedIndex = 0;
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
                self.rootVC.navigationBarHidden = YES;
                [self.rootVC setViewControllers:vcs animated:YES];
                MXContainerViewController *flutterVC = (MXContainerViewController *)self.tabViewVC.viewControllers.lastObject;
                [(UITabBarController *)vcs.lastObject setSelectedIndex:1];
                [flutterVC sendEvent:@"popToTab" query:@{ @"query_data" : @"data from native" }];
            }
        }];
    });
    return channel;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    UIBarButtonItem *titleLessBack = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    viewController.navigationItem.backBarButtonItem = titleLessBack;
    viewController.navigationController.navigationBar.barTintColor = [UIColor systemBlueColor];
    viewController.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    viewController.navigationItem.title = @"Native View";
    viewController.navigationController.navigationBar.titleTextAttributes = [
                                                                             NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor],
                                                                             NSForegroundColorAttributeName,
                                                                             nil];
    BOOL shouldHidden = NO;
    if ([viewController isKindOfClass:[MXContainerViewController class]] || [viewController isKindOfClass:[FlutterPageViewController class]]) {
        shouldHidden = YES;
    }
    if ([viewController isKindOfClass:[TabViewController class]]) {
        TabViewController *tabVC = (TabViewController *)viewController;
        if ([tabVC.selectedViewController isKindOfClass:[MXContainerViewController class]]) {
            shouldHidden = YES;
        }
    }
    navigationController.navigationBarHidden  = shouldHidden;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    viewController.navigationController.title = @"Native";
    tabBarController.navigationController.navigationBarHidden = [viewController isKindOfClass:[MXContainerViewController class]];
}

@end
