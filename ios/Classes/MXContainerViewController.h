//
//  CustomFlutterViewController.h
//  Runner
//
//  Created by pepsin on 2020/6/8.
//

#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN


@interface MXContainerViewController : UIViewController
@property (nonatomic, strong, readonly) NSString *route;
@property (nonatomic, strong) UITabBarItem *barItem;
@property (nonatomic, strong) UIView *background;
@property (nonatomic, assign, getter=isShowingSnapshot) BOOL showSnapshot;
- (instancetype)initWithRoute:(NSString *)route barItem:(nullable UITabBarItem *)item NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithRoute:(NSString *)route;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (void)currentHistory:(void (^)(NSArray<NSString *> *_Nullable history))resultCallback;
- (void)sendEvent:(NSString *)eventName query:(NSDictionary<NSString *, id> *)query;
@end

NS_ASSUME_NONNULL_END
