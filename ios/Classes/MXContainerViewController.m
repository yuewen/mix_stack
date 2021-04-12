//
//  CustomFlutterViewController.m
//  Runner
//
//  Created by pepsin on 2020/6/8.
//

#import "MXContainerViewController.h"
#import "MXAbstractTabBarController.h"
#import "MXOverlayHandlerProtocol.h"
#import "MXStackExchange.h"
#import "MixStackPlugin.h"
#import "UIViewController+FlutterViewHint.h"
#import <objc/runtime.h>


@interface FlutterViewController (SafeBackground)
@end


@implementation FlutterViewController (SafeBackground)
+ (void)load {
  Method originalMethod2 = class_getInstanceMethod([self class], @selector(viewDidAppear:));
  Method newMethod2 = class_getInstanceMethod([self class], @selector(replace_viewDidAppear:));
  method_exchangeImplementations(originalMethod2, newMethod2);
}

- (void)replace_viewDidAppear:(BOOL)animated {
  printf("---mixstack flutter viewDidAppear %p %p\n", self, self.parentViewController);
  [self replace_viewDidAppear:animated];
  if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:@selector(surfaceUpdated:) withObject:@(NO)];
#pragma clang diagnostic pop
    [[MXStackExchange shared].engine.lifecycleChannel sendMessage:@"AppLifecycleState.inactive"];
    [[MXStackExchange shared].engine.lifecycleChannel sendMessage:@"AppLifecycleState.paused"];
  }
}

@end


@interface MXContainerViewController () <MXViewControllerProtocol>
@property (nonatomic, assign) BOOL loaded;
@property (nonatomic, assign) BOOL dirty;
@property (nonatomic, strong) FlutterViewController *flutterVC;
@property (nonatomic, strong) UIView *flutterSnapshot;
@end


@implementation MXContainerViewController

- (instancetype)initWithRoute:(NSString *)route barItem:(UITabBarItem *)item {
  self = [super initWithNibName:nil bundle:nil];
  _barItem = item;
  _route = route;
  self.containsFlutter = YES;
  return self;
}

- (instancetype)initWithRoute:(NSString *)route {
  return [self initWithRoute:route barItem:nil];
}

- (FlutterViewController *)flutterViewController {
  return _flutterVC;
}

- (void)markDirty {
  _dirty = YES;
}

- (void)currentHistory:(void (^)(NSArray<NSString *> *history))resultCallback {
  [MixStackPlugin invoke:@"pageHistory"
                   query:@{ @"current" : MXPageAddress(self) }
                  result:^(id _Nullable result) {
                    if (resultCallback) {
                      resultCallback(result);
                    }
                  }];
}

- (void)sendEvent:(NSString *)eventName
            query:(NSDictionary<NSString *, id> *)query {
  [[MXStackExchange shared] viewController:self
                                 sendEvent:eventName
                                     query:query];
}

- (void)setShowSnapshot:(BOOL)showSnapshot {
  _showSnapshot = showSnapshot;
  if (_showSnapshot) {
    self.flutterSnapshot =
      [self.flutterVC.view snapshotViewAfterScreenUpdates:YES];
  } else {
    self.flutterSnapshot = nil;
  }
}

- (void)setFlutterSnapshot:(UIView *)flutterSnapshot {
  [_flutterSnapshot removeFromSuperview];
  _flutterSnapshot = flutterSnapshot;
  if (_flutterSnapshot == nil) {
    return;
  }
  _flutterSnapshot.frame = self.view.bounds;
  [self.view addSubview:_flutterSnapshot];
}

- (FlutterViewController *)flutterVC {
  if (_flutterVC != nil) {
    return _flutterVC;
  }
  if (!self.viewLoaded) {
    return nil;
  }
  FlutterViewController *old = [MXStackExchange shared].engine.viewController;
  _flutterVC = [[FlutterViewController alloc]
    initWithEngine:[MXStackExchange shared].engine
           nibName:nil
            bundle:nil];
  [_flutterVC setFlutterViewDidRenderCallback:^{
    [[MXStackExchange shared] initPages];
  }];
  _flutterVC.view.backgroundColor = [UIColor clearColor];
  [MXStackExchange shared].engine.viewController = old;
  return _flutterVC;
}

- (NSString *)rootRoute {
  return _route;
}

- (UITabBarItem *)tabBarItem {
  return self.barItem;
}

- (void)viewSafeAreaInsetsDidChange {
  [super viewSafeAreaInsetsDidChange];
  [self.flutterVC.view safeAreaInsetsDidChange];
}

- (UITabBarController *)parentTabbarController {
  UITabBarController *controller = (UITabBarController *)self;
  while ([controller parentViewController] != nil) {
    if ([controller isKindOfClass:[UITabBarController class]]) {
      break;
    } else {
      controller = (UITabBarController *)[controller parentViewController];
    }
  }
  if (![controller isKindOfClass:[UITabBarController class]]) {
    controller = nil;
  }
  return controller;
}

- (UIEdgeInsets)parentOverlayCancelledInsets {
  UIResponder *controller = [self nextResponder];
  __block UIEdgeInsets totalInsets = UIEdgeInsetsZero;

  typedef void (^HandleBlock)(id<MXOverlayHandlerProtocol> handler);
  HandleBlock handleBlock = ^void(id<MXOverlayHandlerProtocol> handler) {
    if ([handler ignoreSafeareaInsetsConfig] != nil) {
      UIEdgeInsets insets = [[handler ignoreSafeareaInsetsConfig]
        ignoreSafeareaInsetsForOverlayHandler:handler];
      totalInsets.bottom = totalInsets.bottom - insets.bottom;
      totalInsets.top = totalInsets.top - insets.top;
      totalInsets.right = totalInsets.right - insets.right;
      totalInsets.left = totalInsets.left - insets.left;
    }
  };
  while ([controller nextResponder] != nil) {
    if ([controller conformsToProtocol:@protocol(MXOverlayHandlerProtocol)]) {
      id<MXOverlayHandlerProtocol> handler =
        (id<MXOverlayHandlerProtocol>)controller;
      handleBlock(handler);
    }
    controller = [controller nextResponder];
  }
  if ([controller conformsToProtocol:@protocol(MXOverlayHandlerProtocol)]) {
    id<MXOverlayHandlerProtocol> handler =
      (id<MXOverlayHandlerProtocol>)controller;
    handleBlock(handler);
  }
  return totalInsets;
}

- (void)viewWillAppear:(BOOL)animated {
  if (self.background != nil) {
    [self.view addSubview:self.background];
  }
  if ([self parentTabbarController] != nil ||
      self.flutterVC.parentViewController == nil) {
    [self.flutterVC willMoveToParentViewController:self];
    self.flutterVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addChildViewController:self.flutterVC];
    [self.view addSubview:self.flutterVC.view];
    [self.flutterVC didMoveToParentViewController:self];
  }
  // Make sure the order is correct
  [self.view sendSubviewToBack:self.flutterVC.view];
  if (self.background != nil) {
    [self.view sendSubviewToBack:self.background];
  }
  if (self.flutterSnapshot != nil) {
    [self.view bringSubviewToFront:self.flutterSnapshot];
  }
  [super viewWillAppear:animated];
  [[MXStackExchange shared] viewWillAppear:self];
  if (self.dirty) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.flutterVC performSelector:NSSelectorFromString(@"surfaceUpdated:")
                         withObject:@(YES)];
#pragma clang diagnostic pop
    self.dirty = NO;
    self.flutterVC.view.hidden = YES;
    __weak MXContainerViewController *weakself = self;
    [self.flutterVC setFlutterViewDidRenderCallback:^{
      weakself.flutterVC.view.hidden = NO;
    }];
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [MixStackPlugin invoke:@"resetPanGesture" query:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  if ([self parentTabbarController] != nil) {
    [self.flutterVC viewDidDisappear:animated];
    [self.flutterVC willMoveToParentViewController:nil];
    [self.flutterVC.view removeFromSuperview];
    [self.flutterVC removeFromParentViewController];
  }
  [[MXStackExchange shared] viewDidDisappear:self];
}

- (void)viewWillDisappear:(BOOL)animated {
  printf("---mixstack viewWillDisappear %p\n", self);
  [super viewWillDisappear:animated];
  UINavigationController *rootNavigationController = self.navigationController;
  rootNavigationController.interactivePopGestureRecognizer.enabled = YES;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
  UIPanGestureRecognizer *panGestureRecognizer = objc_getAssociatedObject(
    rootNavigationController, @selector(fd_fullscreenPopGestureRecognizer));
#pragma clang diagnostic pop
  if (panGestureRecognizer != nil &&
      [panGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
    panGestureRecognizer.enabled = YES;
  }
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  UITabBarController *parent = [self parentTabbarController];
  if (@available(iOS 11.0, *)) {
    UIEdgeInsets totalInsets = [self parentOverlayCancelledInsets];
    MXContainerInfo *info = [[MXContainerInfo alloc] init];
    info.insets = totalInsets;
    [[MXStackExchange shared] updateContainer:self info:info];
    if (parent != nil && !parent.tabBar.translucent && !self.hidesBottomBarWhenPushed) {
      self.flutterVC.additionalSafeAreaInsets = self.view.safeAreaInsets;
    }
  }

  self.background.frame = self.view.bounds;
  if (self.background != nil) {
    self.flutterVC.view.backgroundColor = [UIColor clearColor];
  }

  if (parent != nil) {
    if (parent.tabBar.translucent) {
      self.flutterVC.view.frame = self.view.bounds;
    } else {
      if (parent.viewLoaded) {
        self.flutterVC.view.frame = parent.view.bounds;
      } else {
        self.flutterVC.view.frame = self.view.bounds;
      }
    }
  } else {
    self.flutterVC.view.frame = self.view.bounds;
  }
}

- (void)fakeAppear {
  [self fakeApppear:self];
}

- (void)fakeApppear:(UIViewController<MXViewControllerProtocol> *)vc {
  [[MXStackExchange shared] viewWillAppear:vc];
  [[[MXStackExchange shared].engine lifecycleChannel]
    sendMessage:@"AppLifecycleState.inactive"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  [vc.flutterViewController
    performSelector:NSSelectorFromString(@"surfaceUpdated:")
         withObject:@(YES)];
#pragma clang diagnostic pop
  [[[MXStackExchange shared].engine lifecycleChannel]
    sendMessage:@"AppLifecycleState.resumed"];
}

- (void)dealloc {
  if ([MXStackExchange shared].engine.viewController != self.flutterVC) {
    return;
  }
  if ([MXStackExchange shared].engineViewControllerMissing != nil) {
    UIViewController<MXViewControllerProtocol> *vc =
      [MXStackExchange shared].engineViewControllerMissing(self.rootRoute);
    [self fakeApppear:vc];
    [MXStackExchange shared].engineViewControllerMissing = nil;
    // Automatically link to previous displayed controller
    return;
  }
  if ([[MXStackExchange shared] previousFlutterContainer:self] != nil) {
    UIViewController<MXViewControllerProtocol> *vc =
      [[MXStackExchange shared] previousFlutterContainer:self];
    if (vc.viewLoaded) {
      if (vc.view.window != nil) {
        [self fakeApppear:[[MXStackExchange shared]
                            previousFlutterContainer:self]];
        return;
      }
    }
  }
  if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
    [MXStackExchange shared].engine.viewController = nil;
  } else {
    [MXStackExchange shared].engine.viewController = [[MXStackExchange shared] previousFlutterContainer:self].flutterViewController;
  }
}

@end
