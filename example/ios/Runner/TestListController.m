//
//  PageManagerController.m
//  Runner
//
//  Created by 万福 周 on 2021/4/15.
//

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define CELLHEIGHT 70

#import "TestListController.h"
#import "NativeExmpleViewController.h"
#import <mix_stack/mix_stack.h>
#import "FlutterPageViewController.h"

@interface TestListController ()<UITableViewDelegate,UITableViewDataSource,UIPageViewControllerDelegate>

@property (nonatomic, copy) NSString *flutterRoute;
@property (nonatomic, strong) NSArray <NSString *> *dataSource;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) MXContainerViewController *flutterViewVC;

@end

@implementation TestListController


- (instancetype)initWithFlutterRoute:(NSString *)route {
    self = [super init];
    if (self) {
        _flutterRoute = route;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initDataSource];
    [self initUI];
}

- (void)initUI {
    self.tableView = [[UITableView alloc] initWithFrame:[self getSafeFrame]];
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
}

- (CGRect)getSafeFrame {
    CGRect rect = CGRectZero;
    if (@available(iOS 11.0, *)) {
        if ([[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom > 0) {
            rect = CGRectMake(0,44 + 44, SCREEN_WIDTH, SCREEN_HEIGHT - 83 - 44 - 44);
        }else {
            rect = CGRectMake(0, 20 + 44, SCREEN_WIDTH, SCREEN_HEIGHT - 20 - 44 - 49);
        }
    } else {
        rect = CGRectMake(0, 20 + 44, SCREEN_WIDTH, SCREEN_HEIGHT - 20 - 44 - 49);
    }
    return rect;
}

- (void)initDataSource{
    self.dataSource = @[@"pageViewControl: Flutter | Native",
                        @"pageViewControl: Flutter | Flutter",
                        @"Modal Jump"];
}

#pragma TableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataSource.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CELLHEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell.textLabel setText:self.dataSource[indexPath.row]];
    [cell.textLabel setFont:[UIFont systemFontOfSize:18]];
    [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
            [self gotoPageControllerFlutterWithNative];
            break;
        case 1:
            [self gotoPageControllerFlutterWithFlutter];
            break;
        case 2:
            [self gotoModalPresentWithNOFullScreen];
            break;
        default:
            break;
    }
}

#pragma  getViewControllerExample

- (UIViewController *)getFLutterPage {
    MXContainerViewController *flutterPage =
    [[MXContainerViewController alloc] initWithRoute:self.flutterRoute];
    return flutterPage;
}

- (UIViewController *)getNativePage {
    UIViewController *nativePage =  [[NativeExmpleViewController alloc] init];
    return nativePage;
}

#pragma TestMethod

- (void)gotoPageControllerFlutterWithNative {
    NSArray *controllers = @[
        [[NativeExmpleViewController alloc] init],
        [self getFLutterPage],
        [[NativeExmpleViewController alloc] init],
        [self getFLutterPage],];
    FlutterPageViewController *pageControl = [[FlutterPageViewController alloc] initWithControllers:controllers];
    pageControl.navigationController.navigationBarHidden = YES;
    [self.navigationController pushViewController:pageControl animated:YES];
}

- (void)gotoPageControllerFlutterWithFlutter {
    NSArray *controllers = @[
        [[NativeExmpleViewController alloc] init],
        [self getFLutterPage],
        [self getFLutterPage],
        [[NativeExmpleViewController alloc] init],];
    FlutterPageViewController *pageControl = [[FlutterPageViewController alloc] initWithControllers:controllers];
    [self.navigationController pushViewController:pageControl animated:YES];
}

- (void)goFuncDismissFlutter {
    [self.flutterViewVC currentHistory:^(NSArray<NSString *> * _Nullable history) {
        if (history.count <= 1) {
            [self.flutterViewVC dismissViewControllerAnimated:YES completion:nil];
        }else {
            [[MXStackExchange shared] popPage:nil];
        }
    }];
}

- (void)gotoModalPresentWithNOFullScreen {
    self.flutterViewVC = [[MXContainerViewController alloc] initWithRoute:@"/present_flutter"];
    self.flutterViewVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:self.flutterViewVC animated:YES completion:nil];
}

@end
