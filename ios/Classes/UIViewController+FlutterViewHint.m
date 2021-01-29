//
//  UIViewController+FlutterViewHint.m
//  mix_stack
//
//  Created by pepsin on 2020/8/27.
//

#import "UIViewController+FlutterViewHint.h"
#import <objc/runtime.h>

@implementation UIViewController (FlutterViewHint)

static char kContainsFlutterKey;
- (void)setContainsFlutter:(BOOL)containsFlutter {
  objc_setAssociatedObject(self, &kContainsFlutterKey, @(containsFlutter), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isContainsFlutter {
  NSNumber *result = objc_getAssociatedObject(self, &kContainsFlutterKey);
  return [result boolValue];
}

@end
