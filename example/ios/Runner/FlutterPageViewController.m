//
//  FlutterPageViewController.m
//  Runner
//
//  Created by 万福 周 on 2021/4/16.
//

#import "FlutterPageViewController.h"
#import "NativeExmpleViewController.h"

@interface FlutterPageViewController ()<UIPageViewControllerDelegate, UIPageViewControllerDataSource>

@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (nonatomic, assign) NSUInteger currentIndex;
@property (nonatomic, strong) NSArray <UIViewController *> *controllers;
@property (nonatomic, strong) UIPageControl *pageControl;

@end

@implementation FlutterPageViewController

- (instancetype)initWithControllers:(NSArray <UIViewController *> *)controllers {
    self = [super init];
    _controllers = controllers;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUI];
}

- (void)initUI {
    CGFloat screenWidth = self.view.frame.size.width;
    CGFloat screenHeight = self.view.frame.size.height;
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                       navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                     options:nil];
    self.pageViewController.delegate = self;
    self.pageViewController.dataSource = self;
    UIViewController *vc = [self.controllers objectAtIndex:0];
    __weak typeof(self) weakSelf = self;
    [weakSelf.pageViewController setViewControllers:@[vc] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    self.currentIndex = 0;
    [self addChildViewController:self.pageViewController];
    
    CGFloat pageControlWith = 200;
    CGFloat pageControlHeight = 30;
    CGFloat bottomSafeHeight  = 0;
    if (@available(iOS 11.0, *)) {
        UIEdgeInsets safeArea = [[UIApplication sharedApplication] keyWindow].safeAreaInsets;
        bottomSafeHeight = safeArea.bottom;
    }
    self.pageControl = [[UIPageControl alloc]initWithFrame:CGRectMake((screenWidth - pageControlWith) / 2.0, screenHeight - pageControlHeight - 20 - bottomSafeHeight, pageControlWith, pageControlHeight)];
    self.pageControl.numberOfPages = _controllers.count;
    self.pageControl.currentPage = 0;
    self.pageControl.currentPageIndicatorTintColor = [UIColor redColor];
    self.pageControl.pageIndicatorTintColor = [UIColor grayColor];
    
    [self.view addSubview:self.pageViewController.view];
    [self.view addSubview:self.pageControl];
}

#pragma UIPageViewControllerDelegate

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSInteger index = [self.controllers indexOfObject:viewController];
    if (index == 0 || (index == NSNotFound)) {
        return nil;
    }
    index --;
    UIViewController *vc = [self.controllers objectAtIndex:index];
    return vc;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSInteger index = [self.controllers indexOfObject:viewController];
    if (index == self.controllers.count - 1 || (index == NSNotFound)) {
        return nil;
    }
    index ++;
    UIViewController *vc = [self.controllers objectAtIndex:index];
    return vc;
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
    UIViewController *currentVC = [self.pageViewController.viewControllers lastObject];
    self.currentIndex = [_controllers indexOfObject:currentVC];
}

-(void)setCurrentIndex:(NSUInteger)currentIndex {
    _currentIndex = currentIndex;
    self.pageControl.currentPage = _currentIndex;
    
}

@end
