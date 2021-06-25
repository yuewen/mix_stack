//
//  FlutterPageViewController.h
//  Runner
//
//  Created by 万福 周 on 2021/4/16.
//

#import <UIKit/UIKit.h>
@import mix_stack;
NS_ASSUME_NONNULL_BEGIN

@interface FlutterPageViewController : UIViewController

- (instancetype)initWithControllers:(NSArray <UIViewController *> *)controllers;

@end

NS_ASSUME_NONNULL_END
