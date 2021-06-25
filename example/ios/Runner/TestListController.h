//
//  PageManagerController.h
//  Runner
//
//  Created by 万福 周 on 2021/4/15.
//

#import "MXAbstractTabBarController.h"

NS_ASSUME_NONNULL_BEGIN

@interface TestListController : UIViewController

- (instancetype)initWithFlutterRoute:(NSString *)route;

- (void)goFuncDismissFlutter;

@end

NS_ASSUME_NONNULL_END
