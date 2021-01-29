//
//  UIViewController+FlutterViewHint.h
//  mix_stack
//
//  Created by pepsin on 2020/8/27.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (FlutterViewHint)
@property (nonatomic, assign, getter=isContainsFlutter) BOOL containsFlutter;
@end

NS_ASSUME_NONNULL_END
