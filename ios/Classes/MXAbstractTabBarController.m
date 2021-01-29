//
//  TabViewController.m
//  Runner
//
//  Created by pepsin on 2020/6/8.
//

#import "MXAbstractTabBarController.h"
#import "MXContainerViewController.h"
#import "MXStackExchange.h"
#import "MixStackPlugin.h"
#import "UIViewController+FlutterViewHint.h"
@import Flutter;


@interface MXAbstractTabBarController () <UITabBarControllerDelegate>
@property (nonatomic, readonly) NSInteger index;
@property (nonatomic, assign) BOOL needsRefreshTabs;
@end


@implementation MXAbstractTabBarController

- (void)setViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers {
  [super setViewControllers:viewControllers];
  [self updateFlutterViewControllerInsets];
}

- (void)updateFlutterViewControllerInsets {
  for (UIViewController *vc in self.viewControllers) {
    if (@available(iOS 11.0, *)) {
      if (vc.containsFlutter) {
        vc.additionalSafeAreaInsets = [[self ignoreSafeareaInsetsConfig] ignoreSafeareaInsetsForOverlayHandler:self];
        [vc viewSafeAreaInsetsDidChange];
      }
    }
  }
}

#pragma mark MXOverlayHandlerProtocol
- (NSArray<NSString *> *)overlayNames {
  return @[ @"navigationBar", @"tabBar" ];
}

- (UIView *)overlayView:(NSString *)name {
  if ([name isEqualToString:@"navigationBar"]) {
    return self.navigationController.navigationBar;
  }
  if ([name isEqualToString:@"tabBar"]) {
    return self.tabBar;
  }
  NSAssert(false, @"This should not be nil");
  return nil;
}

- (NSDictionary<NSString *, UIView *> *)overlayViewsForNames:(NSArray<NSString *> *)overlayNames {
  NSMutableDictionary *views = [NSMutableDictionary dictionary];
  for (NSString *name in overlayNames) {
    UIView *view = [self overlayView:name];
    if (view != nil) {
      views[name] = view;
    }
  }
  return views;
}

- (NSArray<UIView *> *)overlayViews {
  return [self overlayViewsForNames:[self overlayNames]].allValues;
}

- (UIViewController *)flutterContainerViewController {
  return [self selectedViewController];
}

- (void)configOverlay:(NSDictionary<NSString *, MXViewConfig *> *)overlayNames completion:(void (^)(void))completion {
  NSArray<NSString *> *names = overlayNames.allKeys;
  typedef void (^viewSettingBlock)(UIView *view, MXViewConfig *obj, NSString *key);
  viewSettingBlock settingBlock = ^void(UIView *view, MXViewConfig *obj, NSString *key) {
    view.hidden = obj.hidden;
    view.alpha = obj.alpha;
    if ([names indexOfObject:key] == (names.count - 1)) {
      if (completion) {
        completion();
        if ([self selectedViewController].viewLoaded) {
          [[self selectedViewController].view setNeedsLayout];
          if ([self selectedViewController].childViewControllers.count > 0) {
            for (UIViewController *vc in [self selectedViewController].childViewControllers) {
              if (vc.viewLoaded) {
                [vc.view setNeedsLayout];
              }
            }
          }
        }
      }
    }
  };
  for (NSString *key in names) {
    MXViewConfig *obj = [overlayNames objectForKey:key];
    UIView *view = [self overlayView:key];
    if (obj.needsAnimation) {
      if (obj.alpha < view.alpha) {
        [UIView animateWithDuration:0.15 animations:^{
          view.alpha = obj.alpha;
        } completion:^(BOOL finished) {
          settingBlock(view, obj, key);
        }];
      } else {
        view.hidden = NO;
        [UIView animateWithDuration:0.15 animations:^{
          view.alpha = obj.alpha;
        } completion:^(BOOL finished) {
          settingBlock(view, obj, key);
        }];
      }
    } else {
      settingBlock(view, obj, key);
    }
  };
}

- (MXIgnoreSafeAreaInsetsConfig *)ignoreSafeareaInsetsConfig {
  return [[MXIgnoreSafeAreaInsetsConfig alloc] initWithTopNames:nil leftNames:nil bottomNames:@[ @"tabBar" ] rightNames:nil];
}

@end
