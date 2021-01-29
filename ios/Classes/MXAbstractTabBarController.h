//
//  TabViewController.h
//  Runner
//
//  Created by pepsin on 2020/6/8.
//

#import <UIKit/UIKit.h>
#import "MXOverlayHandlerProtocol.h"

NS_ASSUME_NONNULL_BEGIN


@interface MXAbstractTabBarController : UITabBarController <MXOverlayHandlerProtocol>
- (void)updateFlutterViewControllerInsets;
@end

NS_ASSUME_NONNULL_END
