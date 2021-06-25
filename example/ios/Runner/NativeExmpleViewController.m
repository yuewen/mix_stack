//
//  ExmpleViewController.m
//  Runner
//
//  Created by 万福 周 on 2021/4/15.
//


#import "NativeExmpleViewController.h"

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)

@interface NativeExmpleViewController ()

@property (nonatomic, strong) UIImageView *animationBgView;

@end

@implementation NativeExmpleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Native View";
    self.view.backgroundColor = [UIColor whiteColor];
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake((SCREEN_WIDTH - 250) / 2.0, (SCREEN_HEIGHT - 80) / 2.0, 250, 80)];
    bgView.layer.cornerRadius = 10;
    bgView.backgroundColor = [self randomColor];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake( 0, 0, 250, 50)];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"NatiVe Page";
    label.textColor = [UIColor whiteColor];
    label.font =[UIFont boldSystemFontOfSize:25];
    
    UILabel *hashLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, 250, 30)];
    hashLabel.textAlignment = NSTextAlignmentCenter;
    hashLabel.text = [NSString stringWithFormat:@"hashCode:%lu", self.hash];
    hashLabel.font = [UIFont systemFontOfSize:18];
    hashLabel.textColor = [UIColor whiteColor];
    
    UIButton *backButton = [[UIButton alloc]initWithFrame:CGRectMake((SCREEN_WIDTH - 50) / 2, bgView.frame.origin.y + 80 + 50, 50, 26)];
    [backButton setTitle:@"Back" forState:UIControlStateNormal];
    [backButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    backButton.backgroundColor = [UIColor grayColor];
    [backButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    
    [bgView addSubview:label];
    [bgView addSubview:hashLabel];
    [self.view addSubview:bgView];
    [self.view addSubview:backButton];
}

- (void)goBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (UIColor *)randomColor {
    CGFloat red = arc4random_uniform(256) / 255.0;
    CGFloat green = arc4random_uniform(256) / 255.0;
    CGFloat blue = arc4random_uniform(256) / 255.0;
    UIColor *color = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
    return color;
}


@end
