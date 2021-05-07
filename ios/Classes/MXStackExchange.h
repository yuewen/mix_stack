//
//  MXStackExchange.h
//  Runner
//
//  Created by pepsin on 2020/8/5.
//

#import <UIKit/UIKit.h>
@import Flutter;

NS_ASSUME_NONNULL_BEGIN
@protocol MXViewControllerProtocol <NSObject>
- (NSString *)rootRoute;
- (FlutterViewController *)flutterViewController;
- (void)markDirty;
@end

NSString *MXPageAddress(id<MXViewControllerProtocol> vc);


@interface MXContainerInfo : NSObject
@property (nonatomic, assign) UIEdgeInsets insets;
@end


@interface MXStackExchange : NSObject
@property (nonatomic, strong) FlutterEngine *engine;
@property (nonatomic, strong, readonly) NSString *debugInfo;
//Every time this is used, will be set back to nil;
@property (nonatomic, copy, nullable) UIViewController<MXViewControllerProtocol> * (^engineViewControllerMissing)(NSString *previousRootRoute);
+ (MXStackExchange *)shared;
- (void)forceRefresh:(BOOL)updated;
- (void)initPages;
- (void)viewWillAppear:(UIViewController<MXViewControllerProtocol> *)flutterView;
- (void)viewDidDisappear:(UIViewController<MXViewControllerProtocol> *)flutterView;
- (void)updateContainer:(UIViewController<MXViewControllerProtocol> *)flutterView info:(MXContainerInfo *)info;
- (UIViewController *)controllerForAddress:(NSString *)addr;
- (void)popPage:(void (^)(BOOL popSuccess))completion;
- (void)viewController:(UIViewController<MXViewControllerProtocol> *)flutterView sendEvent:(NSString *)eventName query:(NSDictionary<NSString *, id> *)query;
- (UIViewController<MXViewControllerProtocol> *)previousFlutterContainer:(nullable UIViewController<MXViewControllerProtocol> *)current;
- (void)updatePages;
@end

NS_ASSUME_NONNULL_END
