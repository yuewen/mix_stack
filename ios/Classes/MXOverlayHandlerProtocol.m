//
//  MixStack.h
//  Runner
//
//  Created by pepsin on 2020/7/2.
//

#import <UIKit/UIKit.h>
#import "MXOverlayHandlerProtocol.h"


@implementation MXViewConfig

- (instancetype)initWithHidden:(BOOL)hidden alpha:(CGFloat)alpha animation:(BOOL)needsAnimation {
  self = [super init];
  if (self) {
    _hidden = hidden;
    _alpha = alpha;
    _needsAnimation = needsAnimation;
  }
  return self;
}

@end


@interface MXIgnoreSafeAreaInsetsConfig ()
@property (nonatomic, strong, readonly) NSArray<NSString *> *topIgnoreNames;
@property (nonatomic, strong, readonly) NSArray<NSString *> *leftIgnoreNames;
@property (nonatomic, strong, readonly) NSArray<NSString *> *bottomIgnoreNames;
@property (nonatomic, strong, readonly) NSArray<NSString *> *rightIgnoreNames;
@end


@implementation MXIgnoreSafeAreaInsetsConfig

- (instancetype)initWithTopNames:(NSArray<NSString *> *)topIgnoreNames
                       leftNames:(NSArray<NSString *> *)leftIgnoreNames
                     bottomNames:(NSArray<NSString *> *)bottomIgnoreNames
                      rightNames:(NSArray<NSString *> *)rightIgnoreNames {
  self = [super init];
  if (self) {
    _topIgnoreNames = topIgnoreNames;
    _leftIgnoreNames = leftIgnoreNames;
    _bottomIgnoreNames = bottomIgnoreNames;
    _rightIgnoreNames = rightIgnoreNames;
  }
  return self;
}

- (UIEdgeInsets)ignoreSafeareaInsetsForOverlayHandler:(id<MXOverlayHandlerProtocol>)handler {
  CGFloat topInset = 0;
  for (NSString *name in self.topIgnoreNames) {
    UIView *view = [handler overlayView:name];
    if (!view.hidden) {
      topInset = MAX(topInset, CGRectGetMaxY(view.frame));
    }
  }
  CGFloat leftInset = 0;
  for (NSString *name in self.leftIgnoreNames) {
    UIView *view = [handler overlayView:name];
    if (!view.hidden) {
      leftInset = MAX(leftInset, CGRectGetMaxX(view.frame));
    }
  }
  CGFloat bottomInset = CGFLOAT_MAX;
  int bottomCount = 0;
  for (NSString *name in self.bottomIgnoreNames) {
    UIView *view = [handler overlayView:name];
    if (!view.hidden) {
      bottomInset = MIN(bottomInset, CGRectGetMinY(view.frame));
      bottomCount += 1;
    }
  }
  if (bottomCount > 0) {
    bottomInset = [UIScreen mainScreen].bounds.size.height - bottomInset;
  } else {
    bottomInset = 0;
  }
  CGFloat rightInset = CGFLOAT_MAX;
  int rightCount = 0;
  for (NSString *name in self.rightIgnoreNames) {
    UIView *view = [handler overlayView:name];
    if (!view.hidden) {
      rightInset = MIN(rightInset, CGRectGetMinX(view.frame));
      rightCount += 1;
    }
  }
  if (rightCount > 0) {
    rightInset = [UIScreen mainScreen].bounds.size.width - rightInset;
  } else {
    rightInset = 0;
  }
  return UIEdgeInsetsMake(-topInset, -leftInset, -bottomInset, -rightInset);
}

@end
