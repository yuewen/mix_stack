//
//  MoreFunctionViewController.m
//  Runner
//
//  Created by julis.wang on 2021/1/22.
//

#import "MoreFunctionViewController.h"

@interface MoreFunctionViewController ()

@end

@implementation MoreFunctionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSString *route = ((MXContainerViewController *)self.selectedViewController).route;
    if ([route isEqualToString:@"/area_inset"]) {
        [self.view addSubview: [self generateControBar]];
    }
}

- (UIView *)generateControBar {
    CGFloat screenWidth = self.view.frame.size.width;
    CGFloat screenHeight = self.view.frame.size.height;
    UIView *mainBoard = [[UIView alloc] initWithFrame:CGRectMake(16, screenHeight - 300, screenWidth, 300)];
    
    UILabel *tips = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 32)];
    tips.text = @"Show/Hide native TabBar";
    tips.font =  [UIFont systemFontOfSize:16];
    tips.textColor = [UIColor grayColor];
    
    UIButton *btnShowTabBar = [self generateButton:@"Show" event:@selector(toggleBar:)];
    UIButton *btnHideTabBar = [self generateButton:@"Hide" event:@selector(toggleBar:)];
    btnShowTabBar.frame = CGRectMake(0, 32, 72, 40);
    btnHideTabBar.frame = CGRectMake(64 + 24, 32, 72, 40);
    [mainBoard addSubview:tips];
    [mainBoard addSubview:btnShowTabBar];
    [mainBoard addSubview:btnHideTabBar];
    return mainBoard;
}

- (void)toggleBar:(UIButton *)btn {
    if ([btn.titleLabel.text isEqualToString:@"Show"]) {
        self.tabBar.hidden = NO;
    } else {
        self.tabBar.hidden = YES;
    }
    [self.selectedViewController.view setNeedsLayout];
    [self.selectedViewController.view layoutIfNeeded];
}


- (UIButton *)generateButton:(NSString *)title event:(SEL)action {
    CGFloat rgbColor = 209/255.0;
    UIButton *uiButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [uiButton setTitle:title forState:UIControlStateNormal];
    [uiButton setTitleColor:[UIColor blackColor] forState:(UIControlStateNormal)];
    [uiButton addTarget:self action:action forControlEvents:UIControlEventTouchDown];
    uiButton.backgroundColor = [UIColor colorWithRed:rgbColor green:rgbColor  blue:rgbColor  alpha:1];
    uiButton.titleLabel.font = [UIFont systemFontOfSize:16];
    uiButton.layer.cornerRadius = 2;
    uiButton.layer.shadowPath = [UIBezierPath bezierPathWithRect:uiButton.bounds].CGPath;
    uiButton.layer.shadowColor = [UIColor grayColor].CGColor;
    uiButton.layer.shadowOffset = CGSizeMake(0, 50);
    uiButton.layer.shadowRadius = 5;
    uiButton.layer.shadowOpacity = 1;
    return uiButton;
}



@end
