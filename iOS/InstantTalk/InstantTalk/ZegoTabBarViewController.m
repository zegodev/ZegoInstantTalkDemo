//
//  ZegoTabBarViewController.m
//  InstantTalk
//
//  Created by Strong on 16/7/7.
//  Copyright © 2016年 ZEGO. All rights reserved.
//

#import "ZegoTabBarViewController.h"
#import "ZegoDataCenter.h"
#import "ZegoVideoCommand.h"
#import "ZegoVideoTalkViewController.h"
#import "ZegoMessage.h"
#import "ZegoSettings.h"

@interface ZegoTabBarViewController () <UIAlertViewDelegate>

@property (nonatomic, strong) NSMutableDictionary *requestAlertDict;
@property (nonatomic, strong) NSMutableDictionary *requestAlertContextDict;

@end

@implementation ZegoTabBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setViewControllersTapGesture];
    
    [[ZegoDataCenter sharedInstance] loginRoom];
    [self setViewControllersTitle:NSLocalizedString(@"ZEGO(登录中...)", nil)];
    
    if ([[ZegoSettings sharedInstance] isDeviceiOS7])
        self.requestAlertContextDict = [NSMutableDictionary dictionary];
    else
        self.requestAlertDict = [NSMutableDictionary dictionary];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLoginResult:) name:kUserLoginNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDisconneted:) name:kUserDisconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAcceptVideoTalk:) name:kUserAcceptVideoTalkNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReceiveCancelVideoTalk:) name:kUserCancelVideoTalkNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUnreadCountUpdate:) name:kUserUnreadCountUpdateNotification object:nil];
    [self addObserver];
}

- (void)onLoginResult:(NSNotification *)notification
{
    [self setViewControllersTitle:NSLocalizedString(@"ZEGO", nil)];
}

- (void)onDisconneted:(NSNotification *)notification
{
    [self setViewControllersTitle:NSLocalizedString(@"ZEGO(离线)", nil)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setUnreadBadge];
}

- (void)addObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReceiveRequestVideoTalk:) name:kUserRequestVideoTalkNotification object:nil];
}

- (void)removeObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kUserRequestVideoTalkNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)setViewControllersTapGesture
{
    for (UIViewController *viewController in self.viewControllers)
    {
        UINavigationController *navigationController = (UINavigationController *)viewController;
        UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(navigationTitleTap:)];
        if (navigationController.navigationBar.subviews.count > 1)
        {
            [[navigationController.navigationBar.subviews objectAtIndex:1] setUserInteractionEnabled:YES];
            [[navigationController.navigationBar.subviews objectAtIndex:1] addGestureRecognizer:singleTapGesture];
        }
        
    }
}

- (void)navigationTitleTap:(UIGestureRecognizer *)gestureRecognizer
{
    if (![ZegoDataCenter sharedInstance].isLogin)
        [[ZegoDataCenter sharedInstance] loginRoom];
}

- (void)setViewControllersTitle:(NSString *)title
{
    for (UIViewController *viewController in self.viewControllers)
    {
        if ([viewController isKindOfClass:[UINavigationController class]])
        {
            UINavigationController *navigationController = (UINavigationController *)viewController;
            UIViewController *rootViewController = [navigationController.viewControllers firstObject];
            rootViewController.navigationItem.title = title;
        }
    }
}

- (void)showRequestVideoAlert:(ZegoVideoRequestInfo *)requestInfo
{
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"%@ 请求与你视频聊天", nil), requestInfo.fromUser.userName];
    if ([[ZegoSettings sharedInstance] isDeviceiOS7])
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:self cancelButtonTitle:NSLocalizedString(@"取消", nil) otherButtonTitles:NSLocalizedString(@"允许", nil), nil];
        self.requestAlertContextDict[requestInfo.magicNumber] = alertView;
        [alertView show];
    }
    else
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:message preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"取消", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [[ZegoDataCenter sharedInstance] agreedVideoTalk:NO magicNumber:requestInfo.magicNumber];
            [self.requestAlertDict removeObjectForKey:requestInfo.magicNumber];
        }];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"允许", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[ZegoDataCenter sharedInstance] agreedVideoTalk:YES magicNumber:requestInfo.magicNumber];
            [self.requestAlertDict removeObjectForKey:requestInfo.magicNumber];
        }];
        
        [alertController addAction:cancelAction];
        [alertController addAction:okAction];
        
        self.requestAlertDict[requestInfo.magicNumber] = alertController;
        
        if (self.presentedViewController)
            [self.presentedViewController presentViewController:alertController animated:YES completion:nil];
        else
            [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)onReceiveRequestVideoTalk:(NSNotification *)notification
{
    ZegoVideoRequestInfo *requestInfo = notification.userInfo[@"requestInfo"];
    if (requestInfo == nil)
        return;
    
    BOOL isTalking = [notification.userInfo[@"isTalking"] boolValue];
    
    if (isTalking == NO)
        [self showRequestVideoAlert:requestInfo];
    else if ([self.presentedViewController isKindOfClass:[ZegoVideoTalkViewController class]])
    {
        ZegoVideoTalkViewController *videoViewController = (ZegoVideoTalkViewController *)self.presentedViewController;
        [videoViewController showRequestVideoAlert:requestInfo];
    }
}

- (void)onReceiveCancelVideoTalk:(NSNotification *)notification
{
    NSString *magicNumber = notification.userInfo[@"magicNumber"];
    if (magicNumber.length == 0)
        return;
    
    UIAlertController *alertController = [self.requestAlertDict objectForKey:magicNumber];
    if (alertController)
        [alertController dismissViewControllerAnimated:YES completion:nil];
    
    [self.requestAlertDict removeObjectForKey:magicNumber];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onAcceptVideoTalk:(NSNotification *)notification
{
    unsigned int roomID = [notification.userInfo[@"roomID"] unsignedIntValue];
    if (roomID == 0)
        return;
    
    if (self.presentedViewController)
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZegoVideoTalkViewController *videoController = (ZegoVideoTalkViewController *)[storyboard instantiateViewControllerWithIdentifier:@"videoTalkStoryboardID"];
    videoController.isRequester = NO;
    videoController.privateRoomID = roomID;
    
    [self presentViewController:videoController animated:YES completion:nil];
    
    //已经同意了一个视频通话的请求，拒绝其他的请求
    if ([[ZegoSettings sharedInstance] isDeviceiOS7])
    {
        for (NSString *magicNumber in self.requestAlertContextDict.allKeys)
        {
            UIAlertView *alertView = self.requestAlertContextDict[magicNumber];
            if (alertView)
                [alertView dismissWithClickedButtonIndex:0 animated:YES];
        }
        
        [self.requestAlertContextDict removeAllObjects];
    }
    else
    {
        for (NSString *magicNumber in self.requestAlertDict.allKeys)
        {
            UIAlertController *controller = self.requestAlertDict[magicNumber];
            if (controller)
            {
                [controller dismissViewControllerAnimated:NO completion:nil];
                [[ZegoDataCenter sharedInstance] agreedVideoTalk:NO magicNumber:magicNumber];
            }
        }
        
        [self.requestAlertDict removeAllObjects];
    }
    
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSArray *keys = [self.requestAlertContextDict allKeysForObject:alertView];
    if (keys.count != 1)
        return;
    
    NSString *magicNumber = [keys firstObject];
    if (buttonIndex == 0)
        [[ZegoDataCenter sharedInstance] agreedVideoTalk:NO magicNumber:magicNumber];
    else if (buttonIndex == 1)
        [[ZegoDataCenter sharedInstance] agreedVideoTalk:YES magicNumber:magicNumber];
    
    [self.requestAlertContextDict removeObjectForKey:magicNumber];
}

- (void)onUnreadCountUpdate:(NSNotification *)notification
{
    [self setUnreadBadge];
}

- (void)setUnreadBadge
{
    for (UIViewController *viewController in self.viewControllers)
    {
        if (viewController.tabBarItem.tag == 1)
        {
            NSUInteger unreadCount = [[ZegoDataCenter sharedInstance] getTotalUnreadCount];
            
            if (unreadCount == 0)
                viewController.tabBarItem.badgeValue = nil;
            else
                viewController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%lu", (unsigned long)unreadCount];
            
            //            NSLog(@"receive unread count update notification");
        }
    }
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
