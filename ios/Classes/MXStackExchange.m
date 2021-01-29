//
//  MXStackExchange.m
//  Runner
//
//  Created by pepsin on 2020/8/5.
//

#import "MXStackExchange.h"
#import "MXAbstractTabBarController.h"
#import "MXContainerViewController.h"
#import "MixStackPlugin.h"

NSString *MXPageAddress(id<MXViewControllerProtocol> vc) {
  return [NSString stringWithFormat:@"%@?addr=%p", vc.rootRoute, vc];
}


@implementation MXContainerInfo

- (NSDictionary *)representation {
  return @{
    @"left" : @(_insets.left),
    @"right" : @(_insets.right),
    @"top" : @(_insets.top),
    @"bottom" : @(_insets.bottom),
  };
}
@end


@interface MXFlutterContainerHolder : NSObject
@property (nonatomic, weak, readonly) UIViewController<MXViewControllerProtocol> *viewController;
@end


@implementation MXFlutterContainerHolder
- (instancetype)initWithContainer:(UIViewController<MXViewControllerProtocol> *)container {
  self = [super init];
  if (self) {
    _viewController = container;
  }
  return self;
}
@end


@interface MXStackExchange ()
@property (nonatomic, strong)
  NSHashTable<UIViewController<MXViewControllerProtocol> *> *views;
@property (nonatomic, strong) NSDictionary *unusedInfo;
@property (nonatomic, assign) BOOL flutterInited;
@property (nonatomic, strong) NSString *currentPage;
@property (nonatomic, strong) NSString *errorLog;
@property (nonatomic, strong) NSMutableArray<MXFlutterContainerHolder *> *displayedViews;
@property (nonatomic, assign) BOOL lifecycleUpdated;
@end


@implementation MXStackExchange

+ (MXStackExchange *)shared {
  static dispatch_once_t onceQueue;
  static MXStackExchange *_sharedInstance = nil;
  dispatch_once(&onceQueue, ^{
    _sharedInstance = [[self alloc] init];
  });
  return _sharedInstance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _views = [NSHashTable weakObjectsHashTable];
    _displayedViews = [NSMutableArray array];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(applicationBecameActive:)
                   name:UIApplicationDidBecomeActiveNotification
                 object:nil];

    [center addObserver:self
               selector:@selector(applicationWillResignActive:)
                   name:UIApplicationWillResignActiveNotification
                 object:nil];

    [center addObserver:self
               selector:@selector(applicationDidEnterBackground:)
                   name:UIApplicationDidEnterBackgroundNotification
                 object:nil];

    [center addObserver:self
               selector:@selector(applicationWillEnterForeground:)
                   name:UIApplicationWillEnterForegroundNotification
                 object:nil];
  }
  _errorLog = @"";
  return self;
}

- (void)forceRefresh:(BOOL)updated {
  for (UIViewController<MXViewControllerProtocol> *vc in _views) {
    if (vc.viewLoaded) {
      if (_engine.viewController == vc.flutterViewController) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [vc.flutterViewController
          performSelector:NSSelectorFromString(@"surfaceUpdated:")
               withObject:@(updated)];
#pragma clang diagnostic pop
      } else {
        [vc markDirty];
      }
    }
  }
}

- (void)applicationBecameActive:(NSNotification *)notification {
  [self updateLifecycle:@"resumed"];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
  if (self.engine.viewController == nil) {
    self.engine.viewController = [[self previousFlutterContainer:nil] flutterViewController];
  }
  [self updateLifecycle:@"inactive"];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
  [self updateLifecycle:@"paused"];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
  [self updateLifecycle:@"inactive"];
}

- (void)updateLifecycle:(NSString *)state {
  [MixStackPlugin
    invoke:@"updateLifecycle"
     query:@{ @"lifecycle" : state }
    result:^(id _Nullable result) {
      if (result != FlutterMethodNotImplemented) {
        self.lifecycleUpdated = YES;
      }
    }];
}

- (void)viewWillAppear:
  (UIViewController<MXViewControllerProtocol> *)flutterView {
  [_views addObject:flutterView];
  NSUInteger index = [_displayedViews indexOfObjectPassingTest:^BOOL(MXFlutterContainerHolder *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
    return obj.viewController == flutterView;
  }];
  if (index != NSNotFound) {
    [_displayedViews removeObjectAtIndex:index];
  }
  [_displayedViews addObject:[[MXFlutterContainerHolder alloc] initWithContainer:flutterView]];
  self.currentPage = MXPageAddress(flutterView);
  if (self.engine.viewController != flutterView.flutterViewController) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [self.engine.viewController performSelector:@selector(flushOngoingTouches)];
#pragma clang diagnostic pop
    self.engine.viewController = nil;
    self.engine.viewController = flutterView.flutterViewController;
  }
  [self updatePages];
  [[MXStackExchange shared] updateLifecycle:@"resumed"];
}

- (void)viewController:(UIViewController<MXViewControllerProtocol> *)flutterView
             sendEvent:(NSString *)eventName
                 query:(NSDictionary<NSString *, id> *)query {
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  dict[@"addr"] = MXPageAddress(flutterView);
  if (eventName.length > 0) {
    dict[@"event"] = eventName;
  }
  if (query != nil) {
    dict[@"query"] = query;
  }
  [MixStackPlugin invoke:@"pageEvent" query:dict];
}

- (void)viewDidDisappear:
  (UIViewController<MXViewControllerProtocol> *)flutterView {
  if (flutterView.navigationController == nil) {
    [_views removeObject:flutterView];
    NSIndexSet *set = [_displayedViews indexesOfObjectsPassingTest:^BOOL(MXFlutterContainerHolder *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
      return (obj.viewController == flutterView) || (obj.viewController == nil);
    }];
    [_displayedViews removeObjectsAtIndexes:set];
    NSString *oldPage = MXPageAddress(flutterView);
    // Means no new flutter page being placed for now
    if ([self.currentPage isEqualToString:oldPage]) {
      self.currentPage = @"";
    }
    [self updatePages];
  }
  if (flutterView.flutterViewController.engine.viewController == flutterView.flutterViewController) {
    [self updateLifecycle:@"paused"];
  }
}

- (void)updatePages {
  NSMutableArray *arr = [NSMutableArray array];
  for (UIViewController<MXViewControllerProtocol> *vc in _views) {
    if (vc.viewLoaded) {
      [arr addObject:MXPageAddress(vc)];
    }
  }
  NSDictionary *query = @{ @"pages" : arr,
                           @"current" : self.currentPage };
  [MixStackPlugin
    invoke:@"setPages"
     query:query
    result:^(id _Nullable result) {
      if ([result isEqual:FlutterMethodNotImplemented]) {
        self.errorLog = [NSString
          stringWithFormat:@"%@\nReboot:%@", self.errorLog, result];
        dispatch_after(
          dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
          dispatch_get_main_queue(), ^{
            [self updatePages];
          });
      }
    }];
  if (!_flutterInited) {
    self.unusedInfo = query;
  }
}

- (UIViewController<MXViewControllerProtocol> *)previousFlutterContainer:(UIViewController<MXViewControllerProtocol> *)current {
  NSIndexSet *set = [_displayedViews indexesOfObjectsPassingTest:^BOOL(MXFlutterContainerHolder *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
    return obj.viewController == nil;
  }];
  [_displayedViews removeObjectsAtIndexes:set];
  NSUInteger index = [_displayedViews indexOfObjectPassingTest:^BOOL(MXFlutterContainerHolder *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
    return obj.viewController == current;
  }];
  if (index == NSNotFound) {
    return _displayedViews.lastObject.viewController;
  } else {
    if (index - 1 >= 0) {
      return _displayedViews[index - 1].viewController;
    } else {
      return _displayedViews.lastObject.viewController;
    }
  }
}

- (void)initPages {
  if (_flutterInited) {
    return;
  }
  _flutterInited = YES;
  if (self.unusedInfo != nil) {
    if (!self.lifecycleUpdated) {
      if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        [self updateLifecycle:@"resumed"];
      } else if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        [self updateLifecycle:@"paused"];
      } else if ([UIApplication sharedApplication].applicationState == UIApplicationStateInactive) {
        [self updateLifecycle:@"inactive"];
      }
    }
    [MixStackPlugin invoke:@"setPages"
                     query:self.unusedInfo
                    result:^(id _Nullable result) {
                      if ([result isEqual:FlutterMethodNotImplemented]) {
                        self.errorLog = [NSString
                          stringWithFormat:@"%@\n%@", self.errorLog, result];
                      }
                    }];
    self.unusedInfo = nil;
  }
}

- (void)updateContainer:
          (UIViewController<MXViewControllerProtocol> *)flutterView
                   info:(MXContainerInfo *)info {
  NSString *currentPage = MXPageAddress(flutterView);
  [MixStackPlugin
    invoke:@"containerInfoUpdate"
     query:@{ @"target" : currentPage,
              @"info" : info.representation }];
}

- (UIViewController *)controllerForAddress:(NSString *)addr {
  UIViewController *container = nil;
  for (UIViewController *vc in _views) {
    if ([[NSString stringWithFormat:@"%p", vc] isEqualToString:addr]) {
      container = vc;
    } else if ([vc isKindOfClass:[MXAbstractTabBarController class]]) {
      MXAbstractTabBarController *tab = (MXAbstractTabBarController *)vc;
      for (UIViewController *child in tab.childViewControllers) {
        if ([[NSString stringWithFormat:@"%p", child] isEqualToString:addr]) {
          container = child;
          break;
        }
      }
    }
    if (container != nil) {
      break;
    }
  }
  return container;
}

- (BOOL)popPage {
  NSDictionary *query = @{ @"current" : self.currentPage };
  __block BOOL popFlutterSuccess = false;
  [MixStackPlugin invoke:@"popPage"
                   query:query
                  result:^(id result) {
                    if ([result isKindOfClass:[NSDictionary class]]) {
                      NSDictionary *dict = result;
                      popFlutterSuccess =
                        [[dict objectForKey:@"result"] boolValue];
                    }
                  }];
  [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                           beforeDate:[NSDate distantPast]];
  return popFlutterSuccess;
}

- (NSString *)debugInfo {
  NSMutableArray *array = [NSMutableArray array];
  [self.views.allObjects
    enumerateObjectsUsingBlock:^(
      UIViewController<MXViewControllerProtocol> *_Nonnull obj,
      NSUInteger idx, BOOL *_Nonnull stop) {
      [array addObject:MXPageAddress(obj)];
    }];
  return [NSString stringWithFormat:@"%@\nR->%@\n->%@\n\nError:%@",
                                    self.unusedInfo,
                                    [array componentsJoinedByString:@", "],
                                    _currentPage, _errorLog];
}

@end
