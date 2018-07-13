//
//  ZegoLiveViewController.m
//  LiveDemo3
//
//  Created by Strong on 16/6/28.
//  Copyright © 2016年 ZEGO. All rights reserved.
//

#import "ZegoLiveViewController.h"
#import "ZegoAnchorOptionViewController.h"
#import "ZegoSettings.h"

@interface ZegoLiveViewController ()

@end

@implementation ZegoLiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.useFrontCamera = YES;
    self.enableTorch = NO;
    self.beautifyFeature = ZEGO_BEAUTIFY_POLISH | ZEGO_BEAUTIFY_WHITEN;
    self.filter = ZEGO_FILTER_NONE;
    
    self.enableMicrophone = YES;
    self.viewMode = ZegoVideoViewModeScaleAspectFill;
    self.enableCamera = YES;
    
    self.logArray = [NSMutableArray array];
    
    // 设置当前的手机姿势
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    [self setRotateFromInterfaceOrientation:orientation];
    
    // 监听电话事件
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionWasInterrupted:) name:AVAudioSessionInterruptionNotification object:nil];
    
#if SUPPORT_SIX_STREAM
    NSLog(@"support six stream");
#else
    NSLog(@"don't support six stream");
#endif
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setIdelTimerDisable:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self setIdelTimerDisable:NO];
    
    if (self.isBeingDismissed)
        [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//由子类来处理不同的业务逻辑
- (void)audioSessionWasInterrupted:(NSNotification *)notification
{
    
}

#pragma mark option delegate
- (void)onUseFrontCamera:(BOOL)use
{
    self.useFrontCamera = use;
}

- (void)onEnableMicrophone:(BOOL)enabled
{
    self.enableMicrophone = enabled;
}

- (void)onEnableTorch:(BOOL)enable
{
    self.enableTorch = enable;
}

- (void)onSelectedBeautify:(NSInteger)row
{
    self.beautifyFeature = row;
}

- (void)onSelectedFilter:(NSInteger)row
{
    self.filter = row;
}

- (void)onEnableCamera:(BOOL)enabled
{
    self.enableCamera = enabled;
}

#pragma mark setter
- (void)setBeautifyFeature:(ZegoBeautifyFeature)beautifyFeature
{
    if (_beautifyFeature == beautifyFeature)
        return;
    
    _beautifyFeature = beautifyFeature;
    [getZegoAV_ShareInstance() enableBeautifying:beautifyFeature];
}

- (void)setFilter:(ZegoFilter)filter
{
    if (_filter == filter)
        return;
    
    _filter = filter;
    [getZegoAV_ShareInstance() setFilter:filter];
}

- (void)setUseFrontCamera:(BOOL)useFrontCamera
{
    if (_useFrontCamera == useFrontCamera)
        return;
    
    _useFrontCamera = useFrontCamera;
    [getZegoAV_ShareInstance() setFrontCam:useFrontCamera];
}

- (void)setEnableMicrophone:(BOOL)enableMicrophone
{
    if (_enableMicrophone == enableMicrophone)
        return;
    
    _enableMicrophone = enableMicrophone;
    [getZegoAV_ShareInstance() enableMic:enableMicrophone];
}

- (void)setEnableTorch:(BOOL)enableTorch
{
    if (_enableTorch == enableTorch)
        return;
    
    _enableTorch = enableTorch;
    [getZegoAV_ShareInstance() enableTorch:enableTorch];
}

- (void)setEnableCamera:(BOOL)enableCamera
{
    if (_enableCamera == enableCamera)
        return;
    
    _enableCamera = enableCamera;
    [getZegoAV_ShareInstance() enableCamera:enableCamera];
}

- (void)setAnchorConfig:(UIView *)publishView
{
    int ret = [getZegoAV_ShareInstance() setAVConfig:[ZegoSettings sharedInstance].currentConfig];
    assert(ret == 0);
    
    bool b = [getZegoAV_ShareInstance() setFrontCam:self.useFrontCamera];
    assert(b);
    
    b = [getZegoAV_ShareInstance() enableMic:self.enableMicrophone];
    assert(b);
    
    b = [getZegoAV_ShareInstance() enableBeautifying:self.beautifyFeature];
    assert(b);
    
    [self enablePreview:YES LocalView:publishView];
    [getZegoAV_ShareInstance() setLocalViewMode:self.viewMode];
}

- (void)enablePreview:(BOOL)enable LocalView:(UIView *)view
{
    if (enable && view)
    {
        [getZegoAV_ShareInstance() setLocalView:view];
        [getZegoAV_ShareInstance() startPreview];
    }
    else
    {
        [getZegoAV_ShareInstance() setLocalView:nil];
        [getZegoAV_ShareInstance() stopPreview];
    }
}

- (void)reportStreamAction:(BOOL)success streamID:(NSString *)streamID
{
    ZegoUser *user = [[ZegoSettings sharedInstance] getZegoUser];
    if (success)
        [getBizRoomInstance() reportStreamAction:1 streamID:streamID userID:user.userID isPublicRoom:NO];
    else
        [getBizRoomInstance() reportStreamAction:2 streamID:streamID userID:user.userID isPublicRoom:NO];
}

- (void)addFirstPlayViewConstraints:(UIView *)firstView containerView:(UIView *)containerView
{
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[firstView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(firstView)]];
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[firstView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(firstView)]];
}

- (void)addSecondBigPlayViewConstraints:(UIView *)secondView containerView:(UIView *)containerView
{
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[secondView(==210)]-(10)-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(secondView)]];
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[secondView(==140)]-(10)-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(secondView)]];
}

- (void)addSecondPlayViewConstraints:(UIView *)secondView containerView:(UIView *)containerView
{
#if SUPPORT_SIX_STREAM
    if (containerView.subviews.count > 3)
    {
        [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[secondView(==135)]-(10)-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(secondView)]];
        [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[secondView(==90)]-(10)-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(secondView)]];
    }
    else
    {
        [self addSecondBigPlayViewConstraints:secondView containerView:containerView];
    }
#else
    [self addSecondBigPlayViewConstraints:secondView containerView:containerView];
    
#endif
}

- (void)addThirdBigPlayViewConstraints:(UIView *)thirdView secondView:(UIView *)secondView containerView:(UIView *)containerView
{
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[thirdView(==210)]-(10)-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(thirdView)]];
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[thirdView(==140)]-(10)-[secondView]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(thirdView, secondView)]];
}

- (void)addThirdPlayViewConstraints:(UIView *)thirdView secondView:(UIView *)secondView containerView:(UIView *)containerView
{
#if SUPPORT_SIX_STREAM
    if (containerView.subviews.count > 3)
    {
        [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[thirdView(==135)]-(10)-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(thirdView)]];
        [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[thirdView(==90)]-(10)-[secondView]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(thirdView, secondView)]];
    }
    else
    {
        [self addThirdBigPlayViewConstraints:thirdView secondView:secondView containerView:containerView];
    }
#else
    [self addThirdBigPlayViewConstraints:thirdView secondView:secondView containerView:containerView];
#endif
}

- (void)addFourthPlayViewConstraints:(UIView *)fourthView thirdView:(UIView *)thirdView containerView:(UIView *)containerView
{
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[fourthView(==135)]-(10)-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(fourthView)]];
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[fourthView(==90)]-(10)-[thirdView]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(fourthView, thirdView)]];
}

- (void)addFifthPlayViewConstraints:(UIView *)fifthView secondView:(UIView *)secondView containerView:(UIView *)containerView
{
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[fifthView(==135)]-(10)-[secondView]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(fifthView, secondView)]];
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[fifthView(==90)]-(10)-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(fifthView)]];
}

- (void)addSixthPlayViewConstraints:(UIView *)sixthView fifthView:(UIView *)fifthView containerView:(UIView *)containerView
{
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[sixthView(==135)]-(10)-[fifthView]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(sixthView, fifthView)]];
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[sixthView(==90)]-(10)-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(sixthView)]];
}

- (UIView *)getFirstViewInContainer:(UIView *)containerView
{
    for (UIView *subview in containerView.subviews)
    {
        if (CGRectGetWidth(subview.frame) == CGRectGetWidth(containerView.frame))
            return subview;
    }
    
    return nil;
}

- (UIView *)getSecondViewInContainer:(UIView *)containerView
{
    for (UIView *subView in containerView.subviews)
    {
        if (CGRectGetMaxY(subView.frame) + 10 == CGRectGetMaxY(containerView.frame) &&
            CGRectGetMaxX(subView.frame) + 10 == CGRectGetMaxX(containerView.frame))
            return subView;
    }
    
    return nil;
}

- (UIView *)getThirdViewInContainer:(UIView *)containerView
{
    for (UIView *subview in containerView.subviews)
    {
        if (CGRectGetMaxX(subview.frame) + CGRectGetWidth(subview.frame) + 20 == CGRectGetMaxX(containerView.frame))
            return subview;
    }
    
    return nil;
}

- (UIView *)getFourthViewInContainer:(UIView *)containerView
{
    for (UIView *subview in containerView.subviews)
    {
        if (CGRectGetMaxX(subview.frame) + 2 * CGRectGetWidth(subview.frame) + 30 == CGRectGetMaxX(containerView.frame))
            return subview;
    }
    
    return nil;
}

- (UIView *)getFifthViewInContainer:(UIView *)containerView
{
    for (UIView *subview in containerView.subviews)
    {
        if (CGRectGetMaxY(subview.frame) + CGRectGetHeight(subview.frame) + 20 == CGRectGetMaxY(containerView.frame))
            return subview;
    }
    
    return nil;
}

- (UIView *)getSixthViewInContainer:(UIView *)containerView
{
    for (UIView *subview in containerView.subviews)
    {
        if (CGRectGetMaxY(subview.frame) + 2 * CGRectGetHeight(subview.frame) + 30 == CGRectGetMaxY(containerView.frame))
            return subview;
    }
    
    return nil;
}

- (void)updateContainerConstraintsForTap:(UIView *)tapView containerView:(UIView *)containerView
{
    UIView *bigView = [self getFirstViewInContainer:containerView];
    if (bigView == tapView || tapView == nil)
        return;
    
    UIView *thirdView = [self getThirdViewInContainer:containerView];
    UIView *secondView = [self getSecondViewInContainer:containerView];
    
#if SUPPORT_SIX_STREAM
    UIView *fourthView = [self getFourthViewInContainer:containerView];
    UIView *fifthView = [self getFifthViewInContainer:containerView];
    UIView *sixthView = [self getSixthViewInContainer:containerView];
#endif
    
    [containerView removeConstraints:containerView.constraints];
    
    if (secondView == tapView)
    {
        //第二个和第一个view交换constraints
        [self addFirstPlayViewConstraints:tapView containerView:containerView];
        [self addSecondPlayViewConstraints:bigView containerView:containerView];
        if (thirdView)
            [self addThirdPlayViewConstraints:thirdView secondView:bigView containerView:containerView];
        
#if SUPPORT_SIX_STREAM
        if (fourthView)
            [self addFourthPlayViewConstraints:fourthView thirdView:thirdView containerView:containerView];
        if (fifthView)
            [self addFifthPlayViewConstraints:fifthView secondView:bigView containerView:containerView];
        if (sixthView)
            [self addSixthPlayViewConstraints:sixthView fifthView:fifthView containerView:containerView];
#endif
    }
    else if (tapView == thirdView)
    {
        //第三个view和第一个view交换constraints
        [self addFirstPlayViewConstraints:thirdView containerView:containerView];
        [self addSecondPlayViewConstraints:secondView containerView:containerView];
        [self addThirdPlayViewConstraints:bigView secondView:secondView containerView:containerView];
        
#if SUPPORT_SIX_STREAM
        if (fourthView)
            [self addFourthPlayViewConstraints:fourthView thirdView:bigView containerView:containerView];
        if (fifthView)
            [self addFifthPlayViewConstraints:fifthView secondView:secondView containerView:containerView];
        if (sixthView)
            [self addSixthPlayViewConstraints:sixthView fifthView:fifthView containerView:containerView];
#endif
    }
    
#if SUPPORT_SIX_STREAM
    else if (tapView == fourthView)
    {
        //第四个view和第一个view交换constraints
        [self addFirstPlayViewConstraints:fourthView containerView:containerView];
        [self addSecondPlayViewConstraints:secondView containerView:containerView];
        [self addThirdPlayViewConstraints:thirdView secondView:secondView containerView:containerView];
        [self addFourthPlayViewConstraints:bigView thirdView:thirdView containerView:containerView];
        if (fifthView)
            [self addFifthPlayViewConstraints:fifthView secondView:secondView containerView:containerView];
        if (sixthView)
            [self addSixthPlayViewConstraints:sixthView fifthView:fifthView containerView:containerView];
    }
    else if (tapView == fifthView)
    {
        [self addFirstPlayViewConstraints:fifthView containerView:containerView];
        [self addSecondPlayViewConstraints:secondView containerView:containerView];
        [self addThirdPlayViewConstraints:thirdView secondView:secondView containerView:containerView];
        [self addFourthPlayViewConstraints:fourthView thirdView:thirdView containerView:containerView];
        [self addFifthPlayViewConstraints:bigView secondView:secondView containerView:containerView];
        if (sixthView)
            [self addSixthPlayViewConstraints:sixthView fifthView:bigView containerView:containerView];
    }
    else if (tapView == sixthView)
    {
        [self addFirstPlayViewConstraints:sixthView containerView:containerView];
        [self addSecondPlayViewConstraints:secondView containerView:containerView];
        [self addThirdPlayViewConstraints:thirdView secondView:secondView containerView:containerView];
        [self addFourthPlayViewConstraints:fourthView thirdView:thirdView containerView:containerView];
        [self addFifthPlayViewConstraints:fifthView secondView:secondView containerView:containerView];
        [self addSixthPlayViewConstraints:bigView fifthView:fifthView containerView:containerView];
    }
#endif
    
    [containerView sendSubviewToBack:tapView];
    
    [UIView animateWithDuration:0.1 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)updateContainerConstraintsForRemove:(UIView *)removeView containerView:(UIView *)containerView
{
    if (removeView == nil)
        return;
    
    UIView *bigView = [self getFirstViewInContainer:containerView];
    UIView *secondeView = [self getSecondViewInContainer:containerView];
    UIView *thirdView = [self getThirdViewInContainer:containerView];
    
#if SUPPORT_SIX_STREAM
    UIView *fourthView = [self getFourthViewInContainer:containerView];
    UIView *fifthView = [self getFifthViewInContainer:containerView];
    UIView *sixthView = [self getSixthViewInContainer:containerView];
#endif
    
    [removeView removeFromSuperview];
    [containerView removeConstraints:containerView.constraints];
    if (removeView == bigView)
    {
        //删除大图时，更新第二个view为大图
        if (secondeView)
            [self addFirstPlayViewConstraints:secondeView containerView:containerView];
        if (thirdView)
            [self addSecondPlayViewConstraints:thirdView containerView:containerView];
        
#if SUPPORT_SIX_STREAM
        if (fourthView)
            [self addThirdPlayViewConstraints:fourthView secondView:thirdView containerView:containerView];
        if (fifthView)
            [self addFourthPlayViewConstraints:fifthView thirdView:fourthView containerView:containerView];
        if (sixthView)
            [self addFifthPlayViewConstraints:sixthView secondView:thirdView containerView:containerView];
#endif
        
        [containerView sendSubviewToBack:secondeView];
    }
    else if (removeView == secondeView)
    {
        [self addFirstPlayViewConstraints:bigView containerView:containerView];
        if (thirdView)
            [self addSecondPlayViewConstraints:thirdView containerView:containerView];
        
#if SUPPORT_SIX_STREAM
        if (fourthView)
            [self addThirdPlayViewConstraints:fourthView secondView:thirdView containerView:containerView];
        if (fifthView)
            [self addFourthPlayViewConstraints:fifthView thirdView:fourthView containerView:containerView];
        if (sixthView)
            [self addFifthPlayViewConstraints:sixthView secondView:thirdView containerView:containerView];
#endif
    
        [containerView sendSubviewToBack:bigView];
    }
    else if (removeView == thirdView)
    {
        [self addFirstPlayViewConstraints:bigView containerView:containerView];
        [self addSecondPlayViewConstraints:secondeView containerView:containerView];
        
#if SUPPORT_SIX_STREAM
        if (fourthView)
            [self addThirdPlayViewConstraints:fourthView secondView:secondeView containerView:containerView];
        if (fifthView)
            [self addFourthPlayViewConstraints:fifthView thirdView:fourthView containerView:containerView];
        if (sixthView)
            [self addFifthPlayViewConstraints:sixthView secondView:secondeView containerView:containerView];
#endif
        
        [containerView sendSubviewToBack:bigView];
    }
    
#if SUPPORT_SIX_STREAM
    else if (removeView == fourthView)
    {
        [self addFirstPlayViewConstraints:bigView containerView:containerView];
        [self addSecondPlayViewConstraints:secondeView containerView:containerView];
        [self addThirdPlayViewConstraints:thirdView secondView:secondeView containerView:containerView];
        if (fifthView)
            [self addFourthPlayViewConstraints:fifthView thirdView:thirdView containerView:containerView];
        if (sixthView)
            [self addFifthPlayViewConstraints:sixthView secondView:secondeView containerView:containerView];
        
        [containerView sendSubviewToBack:bigView];
    }
    else if (removeView == fifthView)
    {
        [self addFirstPlayViewConstraints:bigView containerView:containerView];
        [self addSecondPlayViewConstraints:secondeView containerView:containerView];
        [self addThirdPlayViewConstraints:thirdView secondView:secondeView containerView:containerView];
        [self addFourthPlayViewConstraints:fourthView thirdView:thirdView containerView:containerView];
        if (sixthView)
            [self addFifthPlayViewConstraints:sixthView secondView:secondeView containerView:containerView];
        
        [containerView sendSubviewToBack:bigView];
    }
    else if (removeView == sixthView)
    {
        [self addFirstPlayViewConstraints:bigView containerView:containerView];
        [self addSecondPlayViewConstraints:secondeView containerView:containerView];
        [self addThirdPlayViewConstraints:thirdView secondView:secondeView containerView:containerView];
        [self addFourthPlayViewConstraints:fourthView thirdView:thirdView containerView:containerView];
        [self addFifthPlayViewConstraints:fifthView secondView:secondeView containerView:containerView];
        
        [containerView sendSubviewToBack:bigView];
    }
#endif
    
    [UIView animateWithDuration:0.1 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (BOOL)setContainerConstraints:(UIView *)view containerView:(UIView *)containerView viewCount:(NSUInteger)viewCount
{
    if (viewCount == 0)
    {
        [self addFirstPlayViewConstraints:view containerView:containerView];
    }
    else if (viewCount == 1)
    {
        [self addSecondPlayViewConstraints:view containerView:containerView];
    }
    else if (viewCount == 2)
    {
        UIView *secondView = [self getSecondViewInContainer:containerView];
        if (secondView)
        {
            [self addThirdPlayViewConstraints:view secondView:secondView containerView:containerView];
        }
        else
        {
            assert(secondView);
            return NO;
        }
    }
    
#if SUPPORT_SIX_STREAM
    else if (viewCount == 3)
    {
        UIView *bigView = [self getFirstViewInContainer:containerView];
        UIView *secondView = [self getSecondViewInContainer:containerView];
        UIView *thirdView = [self getThirdViewInContainer:containerView];
        if (thirdView)
        {
            [containerView removeConstraints:containerView.constraints];
            [self addFirstPlayViewConstraints:bigView containerView:containerView];
            [self addSecondPlayViewConstraints:secondView containerView:containerView];
            [self addThirdPlayViewConstraints:thirdView secondView:secondView containerView:containerView];
            
            [self addFourthPlayViewConstraints:view thirdView:thirdView containerView:containerView];
        }
        else
        {
            assert(thirdView);
            return NO;
        }
    }
    else if (viewCount == 4)
    {
        UIView *secondView = [self getSecondViewInContainer:containerView];
        if (secondView)
            [self addFifthPlayViewConstraints:view secondView:secondView containerView:containerView];
        else
        {
            assert(secondView);
            return NO;
        }
    }
    else if (viewCount == 5)
    {
        UIView *fifthView = [self getFifthViewInContainer:containerView];
        if (fifthView)
            [self addSixthPlayViewConstraints:view fifthView:fifthView containerView:containerView];
        else
        {
            assert(fifthView);
            return NO;
        }
    }
#endif
    
    else
    {
        return NO;
    }
    
    [UIView animateWithDuration:0.1 animations:^{
        [self.view layoutIfNeeded];
    }];
    
    return YES;
}

- (BOOL)isDeviceiOS7
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0)
        return YES;
    
    return NO;
}

- (void)showPublishOption
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZegoAnchorOptionViewController *optionController = (ZegoAnchorOptionViewController *)[storyboard instantiateViewControllerWithIdentifier:@"anchorOptionID"];
    
    optionController.useFrontCamera = self.useFrontCamera;
    optionController.enableMicrophone = self.enableMicrophone;
    optionController.enableTorch = self.enableTorch;
    optionController.beautifyRow = self.beautifyFeature;
    optionController.filterRow = self.filter;
    optionController.enableCamera = self.enableCamera;
    
    optionController.delegate = self;
    
    self.definesPresentationContext = YES;
    if (![self isDeviceiOS7])
        optionController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    else
        optionController.modalPresentationStyle = UIModalPresentationCurrentContext;
    
    optionController.view.backgroundColor = [UIColor clearColor];
    [self presentViewController:optionController animated:YES completion:nil];
}


- (void)setIdelTimerDisable:(BOOL)disable
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:disable];
}


- (void)setRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    switch (fromInterfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            [getZegoAV_ShareInstance() setDisplayRotation:CAPTURE_ROTATE_0];
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            [getZegoAV_ShareInstance() setDisplayRotation:CAPTURE_ROTATE_180];
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            [getZegoAV_ShareInstance() setDisplayRotation:CAPTURE_ROTATE_270];
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            [getZegoAV_ShareInstance() setDisplayRotation:CAPTURE_ROTATE_90];
            break;
            
        default:
            break;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        [self setRotateFromInterfaceOrientation:orientation];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        
    }];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self setRotateFromInterfaceOrientation:toInterfaceOrientation];
    
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (NSString *)getCurrentTime
{
//    return [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970] * 1000];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"HH-mm-ss:SSS";
    return [formatter stringFromDate:[NSDate date]];
}

- (void)addLogString:(NSString *)logString
{
    if (logString.length != 0)
    {
        NSString *totalString = [NSString stringWithFormat:@"%@: %@", [self getCurrentTime], logString];
        [self.logArray insertObject:totalString atIndex:0];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"logUpdateNotification" object:self userInfo:nil];
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
