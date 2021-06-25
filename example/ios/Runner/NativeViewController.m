//
//  NativeViewController.m
//  Runner
//
//  Created by julis.wang on 2021/1/22.
//

#import "NativeViewController.h"
#import <mix_stack/mix_stack.h>


@interface NativeViewController ()
@property (nonatomic, strong, readonly) NSString *route;
@end


@implementation NativeViewController

- (instancetype)initWithRoute:(NSString *)route {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _route = route;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor whiteColor];
  CGFloat screenWidth = self.view.frame.size.width;
  CGFloat mainBoardWidth = screenWidth - 40;
  UIView *mainBoard =
    [[UIView alloc] initWithFrame:CGRectMake(20, 100, mainBoardWidth, 70)];
  mainBoard.backgroundColor = [self randomColor];

  UILabel *tip1 = [self getUILabel:@"Native page"];
  tip1.frame = CGRectMake(0, 10, mainBoardWidth, 30);
  tip1.font = [tip1.font fontWithSize:25];

  UILabel *tip2 =
    [self getUILabel:[NSString stringWithFormat:@"hashCode:%lu", self.hash]];
  tip2.frame = CGRectMake(0, tip1.frame.origin.y + 30, mainBoardWidth, 20);
  tip2.font = [tip1.font fontWithSize:15];
  [mainBoard addSubview:tip1];
  [mainBoard addSubview:tip2];
  [self.view addSubview:mainBoard];

  CGFloat buttonY = mainBoard.frame.origin.y + 70 + 70;
  CGFloat buttonX = screenWidth / 2 - 64;
  CGFloat buttonHeight = 44;

  UIButton *btnOpenFlutter =
    [self generateButton:@"Open Flutter" event:@selector(goToFlutterPage)];
  btnOpenFlutter.frame = CGRectMake(buttonX, buttonY, 128, buttonHeight);

  UIButton *btnOpenNative =
    [self generateButton:@"Open Native" event:@selector(goToNativePage)];
  btnOpenNative.frame =
    CGRectMake(buttonX, buttonY + 50 + 15, 128, buttonHeight);

  UIButton *btnGoBack =
    [self generateButton:@"Pop current" event:@selector(goBack)];
  btnGoBack.frame =
    CGRectMake(buttonX, buttonY + 50 + 50 + 30, 128, buttonHeight);

  [self.view addSubview:btnOpenFlutter];
  [self.view addSubview:btnOpenNative];
  [self.view addSubview:btnGoBack];
}

- (void)goToFlutterPage {
  NSString *tempRoute = @"/simple_flutter_page";
  if ([_route isEqual:@"/clear_stack"]) {
    tempRoute = _route;
  }
  MXContainerViewController *simpleFlutter =
    [[MXContainerViewController alloc] initWithRoute:tempRoute];
  [self.navigationController pushViewController:simpleFlutter animated:YES];
}

- (void)goToNativePage {
  NativeViewController *native = [[NativeViewController alloc] init];
  [self.navigationController pushViewController:native animated:YES];
}

- (void)goBack {
  [[MXStackExchange shared] popPage:^(BOOL popSuccess) {
    if (!popSuccess) {
      [self.navigationController popViewControllerAnimated:YES];
    }
  }];
}

- (UIButton *)generateButton:(NSString *)title event:(SEL)action {
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  [button setAttributedTitle:[[NSAttributedString alloc]
                               initWithString:title
                                   attributes:@{
                                     NSForegroundColorAttributeName :
                                       [UIColor systemBlueColor]
                                   }]
                    forState:UIControlStateNormal];
  [button setTitleColor:[UIColor blueColor] forState:(UIControlStateNormal)];
  [button setTitleColor:[UIColor lightGrayColor]
               forState:(UIControlStateHighlighted)];
  [button addTarget:self
              action:action
    forControlEvents:UIControlEventTouchUpInside];
  button.titleLabel.font = [UIFont systemFontOfSize:16];
  button.layer.cornerRadius = 6;
  return button;
}

- (UILabel *)getUILabel:(NSString *)text {
  UILabel *uiLabel = [[UILabel alloc] init];
  uiLabel.text = text;
  uiLabel.textColor = [UIColor whiteColor];
  uiLabel.textAlignment = NSTextAlignmentCenter;
  return uiLabel;
}

- (UIColor *)randomColor {
  CGFloat red = arc4random_uniform(256) / 255.0;
  CGFloat green = arc4random_uniform(256) / 255.0;
  CGFloat blue = arc4random_uniform(256) / 255.0;
  UIColor *color = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
  return color;
}

@end
