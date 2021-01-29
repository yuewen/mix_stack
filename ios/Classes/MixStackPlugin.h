#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN


@interface MixStackPlugin : NSObject <FlutterPlugin>
+ (void)invoke:(NSString *)method query:(nullable NSDictionary *)query;
+ (void)invoke:(NSString *)method query:(nullable NSDictionary *)query result:(FlutterResult _Nullable)callback;
@end
NS_ASSUME_NONNULL_END
