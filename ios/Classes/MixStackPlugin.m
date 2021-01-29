#import "MixStackPlugin.h"
#import "MXOverlayHandlerProtocol.h"
#import "MXContainerViewController.h"
#import "MXStackExchange.h"
#import <objc/runtime.h>

static FlutterMethodChannel *_mxChannel;


@implementation MixStackPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    FlutterMethodChannel *channel = [FlutterMethodChannel
      methodChannelWithName:@"mix_stack"
            binaryMessenger:[registrar messenger]];
    _mxChannel = channel;
    MixStackPlugin *instance = [[MixStackPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
  });
}

+ (void)invoke:(NSString *)method query:(NSDictionary *)query {
  [self invoke:method query:query result:nil];
}

+ (void)invoke:(NSString *)method query:(NSDictionary *)query result:(FlutterResult _Nullable)callback {
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  if (method.length == 0) {
    return;
  }
  if (query != nil) {
    dict[@"query"] = query;
  }
  [_mxChannel invokeMethod:method arguments:dict result:callback];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([call.method isEqualToString:@"enablePanNavigation"]) {
    [self enablePanNavigation:call result:result];
  } else if ([call.method isEqualToString:@"currentOverlayTexture"]) {
    [self getOverlayTexture:call result:result];
  } else if ([call.method isEqualToString:@"configOverlays"]) {
    [self configOverlays:call result:result];
  } else if ([call.method isEqualToString:@"overlayNames"]) {
    [self overlayNames:call result:result];
  } else if ([call.method isEqualToString:@"overlayInfos"]) {
    [self overlayInfos:call result:result];
  } else if ([call.method isEqualToString:@"popNative"]) {
    [self popNative:call result:result];
  } else if ([call.method isEqualToString:@"updatePages"]) {
    [[MXStackExchange shared] updatePages];
  }
}

- (void)enablePanNavigation:(FlutterMethodCall *)call result:(FlutterResult)result {
  UINavigationController *rootNavigationController = [self nearestNavigationControllerForCall:call];
  NSDictionary *query = call.arguments;
  rootNavigationController.interactivePopGestureRecognizer.enabled = [query[@"enable"] boolValue];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
  UIPanGestureRecognizer *panGestureRecognizer = objc_getAssociatedObject(rootNavigationController, @selector(fd_fullscreenPopGestureRecognizer));
#pragma clang diagnostic pop
  if (panGestureRecognizer != nil && [panGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
    panGestureRecognizer.enabled = [query[@"enable"] boolValue];
  }
}

- (void)getOverlayTexture:(FlutterMethodCall *)call result:(FlutterResult)result {
  UIResponder<MXOverlayHandlerProtocol> *obj = [self nearestOverlayControllerForCall:call];
  if (obj != nil) {
    NSArray<NSString *> *query = call.arguments[@"names"];
    NSError *error = nil;
    NSArray<NSString *> *names = [self getTopOverlayNamesFromInput:query overlayHandler:obj error:&error];
    if (error != nil) {
      result([NSData data]);
      return;
    }
    NSArray<UIView *> *rawViews = [obj overlayViewsForNames:names].allValues;
    NSMutableArray<UIView *> *views = [NSMutableArray array];
    for (UIView *v in rawViews) {
      if (!v.hidden && v.alpha > 0) {
        [views addObject:v];
      }
    }
    if (views.count == 0) {
      result([NSData data]);
      return;
    }
    CGSize size = [UIScreen mainScreen].bounds.size;
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGContextSaveGState(ctx);

    for (UIView *view in views) {
      if ([view isKindOfClass:[UINavigationBar class]]) {
        for (UIView *obj in [view subviews]) {
          [obj drawViewHierarchyInRect:[view convertRect:obj.frame toView:view.superview] afterScreenUpdates:NO];
        }
      } else {
        [view drawViewHierarchyInRect:view.frame afterScreenUpdates:NO];
      }
    }

    CGContextRestoreGState(ctx);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    result(UIImagePNGRepresentation(image));
    return;
  }

  result([NSData data]);
}

- (void)configOverlays:(FlutterMethodCall *)call result:(FlutterResult)result {
  UIResponder<MXOverlayHandlerProtocol> *obj = [self nearestOverlayControllerForCall:call];
  if (obj != nil) {
    NSDictionary *query = call.arguments[@"configs"];
    NSMutableDictionary<NSString *, MXViewConfig *> *dict = [NSMutableDictionary dictionary];
    [query.allKeys enumerateObjectsUsingBlock:^(id _Nonnull key, NSUInteger idx, BOOL *_Nonnull stop) {
      if ([key isKindOfClass:[NSString class]]) {
        NSDictionary *value = [query objectForKey:key];
        if ([value isKindOfClass:[NSDictionary class]]) {
          NSArray *couple = [key componentsSeparatedByString:@"-"];
          if (couple.count != 2) {
            NSAssert(false, @"This should be a couple");
          }
          dict[couple.lastObject] = [[MXViewConfig alloc] initWithHidden:[value[@"hidden"] boolValue] alpha:[value[@"alpha"] doubleValue] animation:[value[@"animation"] boolValue]];
        }
      }
    }];
    [obj configOverlay:dict completion:^{

    }];
  }
  result(@(YES));
}

- (void)overlayNames:(FlutterMethodCall *)call result:(FlutterResult)result {
  UIResponder<MXOverlayHandlerProtocol> *obj = [self nearestOverlayControllerForCall:call];
  if (obj != nil) {
    NSMutableArray *names = [NSMutableArray array];
    for (NSString *name in obj.overlayNames) {
      //Decoracte the name for uniqueness
      [names addObject:[NSString stringWithFormat:@"%p-%@", obj, name]];
    }
    result(names);
  } else {
    result(@[]);
  }
}

- (void)overlayInfos:(FlutterMethodCall *)call result:(FlutterResult)result {
  UIResponder<MXOverlayHandlerProtocol> *obj = [self nearestOverlayControllerForCall:call];
  if (obj != nil) {
    NSArray<NSString *> *names = call.arguments[@"names"];
    NSMutableDictionary *r = [NSMutableDictionary dictionary];
    NSDictionary<NSString *, UIView *> *views = [obj overlayViewsForNames:names];
    for (NSString *key in views.allKeys) {
      UIView *view = [views objectForKey:key];
      CGRect gp = [view.superview convertRect:view.frame toView:[UIApplication sharedApplication].keyWindow];
      r[key] = @{ @"x" : @(gp.origin.x),
                  @"y" : @(gp.origin.y),
                  @"width" : @(gp.size.width),
                  @"height" : @(gp.size.height),
                  @"hidden" : @(view.hidden) };
    }
    result(r);
  } else {
    result(@{});
  }
}

- (void)popNative:(FlutterMethodCall *)call result:(FlutterResult)result {
  UINavigationController *rootNavigationController = [self nearestNavigationControllerForCall:call];
  if (rootNavigationController == nil) {
    result(@(NO));
    return;
  }
  BOOL haveOnlyOneVC = rootNavigationController.viewControllers.count == 0;
  if (haveOnlyOneVC) {
    result(@(NO));
    return;
  }
  if (call.arguments[@"needsAnimation"] != nil) {
    [rootNavigationController popViewControllerAnimated:[call.arguments[@"needsAnimation"] boolValue]];
  } else {
    [rootNavigationController popViewControllerAnimated:YES];
  }
  result(@(YES));
}

#pragma mark Helper Methods
- (UINavigationController *)nearestNavigationControllerForCall:(FlutterMethodCall *)call {
  NSString *pageAddress = call.arguments[@"addr"];
  UIViewController *controller = [[MXStackExchange shared] controllerForAddress:pageAddress];
  return controller.navigationController;
}

- (UIResponder<MXOverlayHandlerProtocol> *)nearestOverlayControllerForCall:(FlutterMethodCall *)call {
  NSString *pageAddress = call.arguments[@"addr"];
  UIViewController<MXOverlayHandlerProtocol> *controller = (UIViewController<MXOverlayHandlerProtocol> *)[[MXStackExchange shared] controllerForAddress:pageAddress];
  while ([controller parentViewController] != nil) {
    if ([controller conformsToProtocol:@protocol(MXOverlayHandlerProtocol)]) {
      break;
    } else {
      controller = (UIViewController<MXOverlayHandlerProtocol> *)[controller parentViewController];
    }
  }
  if (![controller conformsToProtocol:@protocol(MXOverlayHandlerProtocol)]) {
    controller = nil;
  }
  return controller;
}

- (NSArray<NSString *> *)getTopOverlayNamesFromInput:(NSArray<NSString *> *)inputNames overlayHandler:(id<MXOverlayHandlerProtocol>)obj error:(NSError **)error {
  NSString *hexStr = [NSString stringWithFormat:@"%p", obj];
  NSMutableArray<NSString *> *names = [NSMutableArray array];
  for (NSString *name in inputNames) {
    NSArray *couple = [name componentsSeparatedByString:@"-"];
    if (couple.count != 2) {
      NSAssert(false, @"This should be a couple");
      *error = [NSError errorWithDomain:NSURLErrorDomain code:-1 userInfo:nil];
      break;
    }
    if (![couple[0] isEqualToString:hexStr]) {
      NSAssert(false, @"This should be target at top view");
      *error = [NSError errorWithDomain:NSURLErrorDomain code:-1 userInfo:nil];
      break;
    }
    [names addObject:couple[1]];
  }
  return names;
}
@end
