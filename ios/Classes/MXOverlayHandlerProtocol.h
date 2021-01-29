//
//  MixStack.h
//  Runner
//
//  Created by pepsin on 2020/7/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface MXViewConfig : NSObject
@property (nonatomic, assign, readonly) BOOL hidden;
@property (nonatomic, assign, readonly) CGFloat alpha;
@property (nonatomic, assign, readonly) BOOL needsAnimation;
- (instancetype)initWithHidden:(BOOL)hidden alpha:(CGFloat)alpha animation:(BOOL)needsAnimation NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@class MXIgnoreSafeAreaInsetsConfig;
@protocol MXOverlayHandlerProtocol <NSObject>
- (NSArray<NSString *> *)overlayNames;
- (UIView *)overlayView:(NSString *)name;
- (NSDictionary<NSString *, UIView *> *)overlayViewsForNames:(NSArray<NSString *> *)overlayNames;
- (void)configOverlay:(NSDictionary<NSString *, MXViewConfig *> *)overlayNames completion:(void (^)(void))completion;
- (UIViewController *)flutterContainerViewController;
- (MXIgnoreSafeAreaInsetsConfig *)ignoreSafeareaInsetsConfig;
@end


@interface MXIgnoreSafeAreaInsetsConfig : NSObject
- (instancetype)initWithTopNames:(nullable NSArray<NSString *> *)topIgnoreNames
                       leftNames:(nullable NSArray<NSString *> *)leftIgnoreNames
                     bottomNames:(nullable NSArray<NSString *> *)bottomIgnoreNames
                      rightNames:(nullable NSArray<NSString *> *)rightIgnoreNames NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (UIEdgeInsets)ignoreSafeareaInsetsForOverlayHandler:(id<MXOverlayHandlerProtocol>)handler;
@end

NS_ASSUME_NONNULL_END
