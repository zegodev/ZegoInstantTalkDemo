//
//  ZegoVideoTalkViewController.m
//  InstantTalk
//
//  Created by Strong on 16/7/11.
//  Copyright © 2016年 ZEGO. All rights reserved.
//

#import "ZegoVideoTalkViewController.h"
#import "ZegoAVKitManager.h"
#import "ZegoDataCenter.h"
#import "ZegoStreamInfo.h"
#import "ZegoLogTableViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ZegoVideoTalkViewController () <ZegoLiveApiDelegate, BizRoomStreamDelegate, UIAlertViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *playContainerView;
@property (nonatomic, weak) IBOutlet UILabel *tipsLabel;

@property (nonatomic, strong) NSMutableArray *playStreamList;
@property (nonatomic, strong) NSMutableDictionary *viewContainersDict;
@property (nonatomic, strong) NSMutableDictionary *viewIndexDict;

@property (nonatomic, copy) NSString *liveChannel;
@property (nonatomic, copy) NSString *liveStreamID;
@property (nonatomic, copy) NSString *liveTitle;

@property (nonatomic, strong) UIView *publishView;

@property (nonatomic, assign) BOOL firstPlayStream;
@property (nonatomic, assign) BOOL loginChannelSuccess;
@property (nonatomic, assign) BOOL loginPrivateRoomSuccess;

//@property (nonatomic, strong) NSTimer *checkTimer;
@property (nonatomic, assign) NSUInteger refuseUserNumber;

@property (nonatomic, assign) BOOL isPublishing;
@property (nonatomic, assign) BOOL shouldInterrutped;

@property (nonatomic, strong) NSMutableArray *retryStreamList;
@property (nonatomic, strong) NSMutableArray *failedStreamList;

@property (nonatomic, strong) NSMutableDictionary *requestAlertDict;
@property (nonatomic, strong) NSMutableDictionary *requestAlertContextDict;

@end

@implementation ZegoVideoTalkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (self.isRequester)
    {
        [[ZegoDataCenter sharedInstance] requestVideoTalk:self.userList];
    }
    
    _viewContainersDict = [[NSMutableDictionary alloc] initWithCapacity:MAX_STREAM_COUNT];
    _viewIndexDict = [[NSMutableDictionary alloc] initWithCapacity:MAX_STREAM_COUNT];
    _playStreamList = [[NSMutableArray alloc] init];
    _retryStreamList = [[NSMutableArray alloc] init];
    _failedStreamList = [[NSMutableArray alloc] init];
    
    if ([[ZegoSettings sharedInstance] isDeviceiOS7])
        self.requestAlertContextDict = [NSMutableDictionary dictionary];
    else
        self.requestAlertDict = [NSMutableDictionary dictionary];
    
    BOOL videoAuthorization = [self checkVideoAuthorization];
    BOOL audioAuthorization = [self checkAudioAuthorization];
    
    if (videoAuthorization == YES)
    {
        if (audioAuthorization == NO)
        {
            [self showAuthorizationAlert:NSLocalizedString(@"直播视频,访问麦克风", nil) title:NSLocalizedString(@"需要访问麦克风", nil)];
        }
    }
    else
    {
        [self showAuthorizationAlert:NSLocalizedString(@"直播视频,访问相机", nil) title:NSLocalizedString(@"需要访问相机", nil)];
    }
    
    [self setupLiveKit];
    
    //先创建一个小view进行preview
    UIView *publishView = [self createPublishView];
    if (publishView)
    {
        [self setAnchorConfig:publishView];
        [getZegoAV_ShareInstance() startPreview];
        self.publishView = publishView;
    }

    if (self.isRequester)
    {
        //监听消息
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRespondVideoTalk:) name:kUserRespondVideoTalkNotification object:nil];
        self.tipsLabel.text = NSLocalizedString(@"等待对方同意...", nil);
    }
    else
    {
        //退出大厅，进入私有房间
        [self loginPrivateRoom];
        self.tipsLabel.text = NSLocalizedString(@"开始登录私有房间...", nil);
        
        [self.logArray addObject:[NSString stringWithFormat:NSLocalizedString(@"退出大厅,开始登录私有房间", nil)]];
    }

//    self.checkTimer = [NSTimer scheduledTimerWithTimeInterval:120 target:self selector:@selector(onCheckUser) userInfo:nil repeats:NO];
}

- (void)openSetting
{
    NSURL *settingURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:settingURL])
        [[UIApplication sharedApplication] openURL:settingURL];
}

- (void)showAuthorizationAlert:(NSString *)message title:(NSString *)title
{
    if ([self isDeviceiOS7])
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:NSLocalizedString(@"取消", nil) otherButtonTitles:NSLocalizedString(@"设置权限", nil), nil];
        [alertView show];
    }
    else
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"取消", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        UIAlertAction *settingAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"设置权限", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self openSetting];
        }];
        
        [alertController addAction:settingAction];
        [alertController addAction:cancelAction];
        
        alertController.preferredAction = settingAction;
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

#pragma mark alert view delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    UIAlertView *view = nil;
    NSString *magicNumber = nil;
    for (NSString *key in self.requestAlertContextDict.allKeys)
    {
        if (self.requestAlertContextDict[key] == alertView)
        {
            view = alertView;
            magicNumber = key;
            break;
        }
    }
    
    if (buttonIndex == 1 && view == nil)
    {
        [self openSetting];
        return;
    }
    
    if (buttonIndex == 0)
        [[ZegoDataCenter sharedInstance] agreedVideoTalk:NO magicNumber:magicNumber];
    else if (buttonIndex == 1)
    {
        [[ZegoDataCenter sharedInstance] agreedVideoTalk:YES magicNumber:magicNumber];
        [self closeView:nil];
    }
    
    [self.requestAlertContextDict removeObjectForKey:magicNumber];
}

#pragma mark audiosessionInterrupted notification
- (void)audioSessionWasInterrupted:(NSNotification *)notification
{
    if (AVAudioSessionInterruptionTypeBegan == [notification.userInfo[AVAudioSessionInterruptionTypeKey] intValue])
    {
        if (!self.isPublishing)
        {
            self.shouldInterrutped = NO;
            return;
        }
        else
        {
            self.shouldInterrutped = YES;
        }
        
        [self closeAllStream];
        
        [getZegoAV_ShareInstance() logoutChannel];
    }
    else if (AVAudioSessionInterruptionTypeEnded == [notification.userInfo[AVAudioSessionInterruptionTypeKey] intValue])
    {
        if (!self.shouldInterrutped)
            return;
        
        [getBizRoomInstance() cteateStreamInRoom:self.liveTitle preferredStreamID:self.liveStreamID isPublicRoom:NO];
        
        NSString *logString = [NSString stringWithFormat:NSLocalizedString(@"创建断开之前相同的流", nil)];
        [self addLogString:logString];
    }
}

- (void)onRequestVideoTalk:(NSNotification *)notification
{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
//    if (self.isMovingFromParentViewController)
//    {
//        [self.checkTimer invalidate];
//        self.checkTimer = nil;
//    }
}

//检查相机权限
- (BOOL)checkVideoAuthorization
{
    AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (videoAuthStatus == AVAuthorizationStatusDenied || videoAuthStatus == AVAuthorizationStatusRestricted)
        return NO;
    if (videoAuthStatus == AVAuthorizationStatusNotDetermined)
    {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        }];
    }
    return YES;
}

- (BOOL)checkAudioAuthorization
{
    AVAuthorizationStatus audioAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (audioAuthStatus == AVAuthorizationStatusDenied || audioAuthStatus == AVAuthorizationStatusRestricted)
        return NO;
    if (audioAuthStatus == AVAuthorizationStatusNotDetermined)
    {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
        }];
    }
    
    return YES;
}

- (void)setupLiveKit
{
    getZegoAV_ShareInstance().delegate = self;
    
    [[ZegoDataCenter sharedInstance] registerPrivateRoomDelegate:self];
}

//- (void)onCheckUser
//{
//    if (self.liveStreamID == nil || self.playStreamList.count == 0)
//    {
//        if (self.isPublishing)
//            self.tipsLabel.text = NSLocalizedString(@"所有人都退出了聊天", nil);
//        else
//            self.tipsLabel.text = NSLocalizedString(@"对方可能无法响应", nil);
//    }
//}

- (void)loginPrivateRoom
{
    if (self.privateRoomID == 0)
    {
        NSLog(@"token is 0, not a private room");
        return;
    }
    
    ZegoUser *user = [[ZegoSettings sharedInstance] getZegoUser];
    [getBizRoomInstance() loginLiveRoom:user.userID userName:user.userName bizToken:0 bizID:self.privateRoomID isPublicRoom:NO];
    
    [self addLogString:[NSString stringWithFormat:NSLocalizedString(@"开始登录私有房间,房间ID: 0x%x", nil), self.privateRoomID]];
}

- (void)onRespondVideoTalk:(NSNotification *)notification
{
    BOOL agreed = [notification.userInfo[@"result"] boolValue];
    if (agreed)
    {
        //退出大厅，进入私有房间
        self.privateRoomID = [notification.userInfo[@"roomID"] unsignedIntValue];
        [self loginPrivateRoom];
    }
    else
    {
        //有用户拒绝
        self.refuseUserNumber += 1;
        if (self.refuseUserNumber == self.userList.count - 1)
        {
            //所有用户都拒绝了
            if (self.userList.count == 2)
                self.tipsLabel.text = NSLocalizedString(@"对方拒绝了您的请求", nil);
            else
                self.tipsLabel.text = NSLocalizedString(@"所有人都拒绝了您的请求", nil);
        }
    }
}

- (void)dismissViewController
{
    self.loginPrivateRoomSuccess = NO;
    
    //发广播,让dataCenter开始重新登录公共房间
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)closeAllStream
{
    [getZegoAV_ShareInstance() stopPreview];
    [getZegoAV_ShareInstance() setLocalView:nil];
    [getZegoAV_ShareInstance() stopPublishing];
    
    [self reportStreamAction:NO streamID:self.liveStreamID];
    [self removeStreamViewContainer:self.liveStreamID];
    self.publishView = nil;
    self.firstPlayStream = NO;
    
    for (ZegoStreamInfo *info in self.playStreamList)
    {
        NSLog(@"stop Play Stream: %@", info.streamID);
        [getZegoAV_ShareInstance() stopPlayStream:info.streamID];
        [self removeStreamViewContainer:info.streamID];
    }
    
    [self.viewContainersDict removeAllObjects];
    [self.viewIndexDict removeAllObjects];
    [self.retryStreamList removeAllObjects];
}

- (IBAction)closeView:(id)sender
{
    self.tipsLabel.text = NSLocalizedString(@"退出视频聊天...", nil);
    
    [getZegoAV_ShareInstance() stopPreview];
    [getZegoAV_ShareInstance() setLocalView:nil];
    
    if (self.loginChannelSuccess)
    {
        [self closeAllStream];
    
        [getZegoAV_ShareInstance() logoutChannel];
    }
    
    if (self.loginPrivateRoomSuccess)
    {
        [getBizRoomInstance() leaveLiveRoom:NO];
        self.loginPrivateRoomSuccess = NO;
    }
    else
    {
        [self dismissViewController];
        if (self.isRequester)
        {
            //请求方在还没有应答时就退出了页面
            [[ZegoDataCenter sharedInstance] cancelVideoTalk:self.userList];
        }
        
        [[ZegoDataCenter sharedInstance] registerPrivateRoomDelegate:nil];
    }
    
    [[ZegoDataCenter sharedInstance] stopVideoTalk];
    
}

- (IBAction)onShowPublishOption:(id)sender
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
- (UIView *)createPublishView
{
    UIView *publishView = [[UIView alloc] init];
    publishView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.playContainerView addSubview:publishView];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapView:)];
    [publishView addGestureRecognizer:tapGesture];
    
    BOOL bResult = [self setContainerConstraints:publishView containerView:self.playContainerView viewCount:0];
    if (bResult == NO)
    {
        [publishView removeFromSuperview];
        return nil;
    }
    
    [self.playContainerView bringSubviewToFront:publishView];
    
    return publishView;
}

- (void)onTapView:(UIGestureRecognizer *)recognizer
{
    if (self.playContainerView.subviews.count < 2)
        return;
    
    UIView *view = recognizer.view;
    if (view == nil)
        return;
    
    [self updateContainerConstraintsForTap:view containerView:self.playContainerView];
}

- (void)createStream
{
    self.liveTitle = [NSString stringWithFormat:@"Hello-%@", [ZegoSettings sharedInstance].userName];
    [getBizRoomInstance() cteateStreamInRoom:self.liveTitle preferredStreamID:nil isPublicRoom:NO];
    
    NSString *logString = [NSString stringWithFormat:NSLocalizedString(@"创建流", nil)];
    [self addLogString:logString];
}

- (void)getStreamList
{
    [getBizRoomInstance() getStreamList:NO];
    
    NSString *logString = [NSString stringWithFormat:NSLocalizedString(@"开始获取直播流列表", nil)];
    [self addLogString:logString];
}

- (UIView *)createPlayView:(NSString *)streamID
{
    UIView *playView = [[UIView alloc] init];
    playView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.playContainerView addSubview:playView];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapView:)];
    [playView addGestureRecognizer:tapGesture];
    
    NSUInteger count = self.viewContainersDict.count;
    if (self.viewContainersDict.count == 0)
        count = 1;
    
    BOOL bResult = [self setContainerConstraints:playView containerView:self.playContainerView viewCount:count];
    if (bResult == NO)
    {
        [playView removeFromSuperview];
        return nil;
    }
    
    self.viewContainersDict[streamID] = playView;
    [self.playContainerView bringSubviewToFront:playView];
    
    return playView;
    
}

- (int)getRemoteViewIndex
{
    int index = 0;
    for (; index < MAX_STREAM_COUNT; index++)
    {
        if ([self.viewIndexDict allKeysForObject:@(index)].count == 0)
            return index;
    }
    
    if (index == MAX_STREAM_COUNT)
        NSLog(@"cannot find indx to add view");
    
    return index;
}

- (void)createPlayStream:(NSString *)streamID
{
    UIView *playView = [self createPlayView:streamID];
    
    RemoteViewIndex index = (RemoteViewIndex)[self getRemoteViewIndex];
    self.viewIndexDict[streamID] = @(index);
    
    [getZegoAV_ShareInstance() setRemoteView:index view:playView];
    [getZegoAV_ShareInstance() setRemoteViewMode:index mode:ZegoVideoViewModeScaleAspectFill];
    bool ret = [getZegoAV_ShareInstance() startPlayStream:streamID viewIndex:index];
    assert(ret);
    
    if (self.firstPlayStream == NO)
    {
        self.firstPlayStream = YES;
        [self updateContainerConstraintsForTap:playView containerView:self.playContainerView];
    }
}

- (void)onStreamUpdateForAdd:(NSArray<NSDictionary *> *)streamList
{
    for (NSDictionary *dic in streamList)
    {
        NSString *streamID = dic[kRoomStreamIDKey];
        if ([self isStreamIDExist:streamID])
        {
            continue;
        }
        
        ZegoStreamInfo *streamInfo = [ZegoStreamInfo getStreamInfo:dic];
        [self.playStreamList addObject:streamInfo];
        [self createPlayStream:streamID];
        
        NSString *logString = [NSString stringWithFormat:NSLocalizedString(@"新增一条流, 流ID:%@", nil), streamID];
        [self addLogString:logString];
        
        if (self.isPublishing)
            self.tipsLabel.text = NSLocalizedString(@"视频聊天中...", nil);
        
        if (self.viewContainersDict.count >= MAX_STREAM_COUNT)
            break;
    }
}

- (void)onStreamUpdateForDelete:(NSArray<NSDictionary *> *)streamList
{
    for (NSDictionary *dic in streamList)
    {
        NSString *streamID = dic[kRoomStreamIDKey];
        if (![self isStreamIDExist:streamID])
            continue;
        
        [getZegoAV_ShareInstance() stopPlayStream:streamID];
        [self removeStreamViewContainer:streamID];
        [self removeStreamInfo:streamID];
        
        NSString *logString = [NSString stringWithFormat:NSLocalizedString(@"删除一条流, 流ID:%@", nil), streamID];
        [self addLogString:logString];
    }
    
    if (self.playStreamList.count == 0)
    {
        self.tipsLabel.text = NSLocalizedString(@"对方退出视频聊天", nil);
        self.firstPlayStream = NO;
    }
}

- (BOOL)isStreamIDExist:(NSString *)streamID
{
    if ([self.liveStreamID isEqualToString:streamID])
        return YES;
    
    for (ZegoStreamInfo *info in self.playStreamList)
    {
        if ([info.streamID isEqualToString:streamID])
            return YES;
    }
    
    return NO;
}

- (void)removeStreamInfo:(NSString *)streamID
{
    NSInteger index = NSNotFound;
    for (ZegoStreamInfo *info in self.playStreamList)
    {
        if ([info.streamID isEqualToString:streamID])
        {
            index = [self.playStreamList indexOfObject:info];
            break;
        }
    }
    
    if (index != NSNotFound)
        [self.playStreamList removeObjectAtIndex:index];
}

#pragma mark BizStreamRoom Delegate
- (void)onLoginRoom:(int)err bizID:(unsigned int)bizID bizToken:(unsigned int)bizToken isPublicRoom:(bool)isPublicRoom
{
    NSLog(@"%s, error: %d", __func__, err);
    if (isPublicRoom)
        return;
    
    if (err == 0)
    {
        if (bizID != self.privateRoomID)
        {
            NSString *logString = [NSString stringWithFormat:@"%@ %@ token 0x%x, id 0x%x", NSLocalizedString(@"登录私有房间成功", nil), NSLocalizedString(@"ID不同", nil), bizToken, bizID];
            [self addLogString:logString];
            return;
        }
        
        NSString *logString = [NSString stringWithFormat:@"%@ token 0x%x, id 0x%x", NSLocalizedString(@"登录私有房间成功", nil), bizToken, bizID];
        [self addLogString:logString];
        
        self.liveChannel = [[ZegoSettings sharedInstance] getChannelID:bizToken bizID:bizID];
        [self createStream];
        
        self.loginPrivateRoomSuccess = YES;
        self.tipsLabel.text = NSLocalizedString(@"与对方连接中...", nil);
    }
    else
    {
        NSString *logString = [NSString stringWithFormat:@"%@ token 0x%x, id 0x%x, privateID 0x%x. error: %d", NSLocalizedString(@"登录私有房间失败", nil), bizToken, bizID, self.privateRoomID, err];
        [self addLogString:logString];
        self.tipsLabel.text = NSLocalizedString(@"登录私有房间失败", nil);
    }
}

- (void)onDisconnected:(int)err bizID:(unsigned int)bizID bizToken:(unsigned int)bizToken isPublicRoom:(bool)isPublicRoom
{
    NSLog(@"%s, error: %d", __func__, err);
}

- (void)onLeaveRoom:(int)err isPublicRoom:(bool)isPublicRoom
{
    NSLog(@"%s, error: %d", __func__, err);
    NSString *logString = [NSString stringWithFormat:NSLocalizedString(@"退出房间, error: %d", nil), err];
    [self addLogString:logString];
    
    [self dismissViewController];
    [[ZegoDataCenter sharedInstance] registerPrivateRoomDelegate:nil];
}

- (void)onStreamCreate:(NSString *)streamID url:(NSString *)url isPublicRoom:(bool)isPublicRoom
{
    if (isPublicRoom)
        return;
    
    if (streamID.length != 0)
    {
        NSString *logString = [NSString stringWithFormat:NSLocalizedString(@"创建流成功, streamID:%@", nil), streamID];
        [self addLogString:logString];
        
        self.liveStreamID = streamID;
        [self loginChannel];
    }
    else
    {
        NSString *logString = [NSString stringWithFormat:NSLocalizedString(@"创建流失败", nil)];
        [self addLogString:logString];
    }
}

- (void)onStreamUpdate:(NSArray<NSDictionary *> *)streamList flag:(int)flag isPublicRoom:(bool)isPublicRoom
{
    if (isPublicRoom)
        return;
    
    if (!self.loginChannelSuccess)
    {
        NSString *logString = [NSString stringWithFormat:NSLocalizedString(@"流列表有更新,先缓存", nil)];
        [self addLogString:logString];
        
        if (flag == 1)
            return;
        
        //先把流缓存起来
        for (NSDictionary *dic in streamList)
        {
            NSString *streamID = dic[kRoomStreamIDKey];
            if ([self isStreamIDExist:streamID])
            {
                continue;
            }
            
            ZegoStreamInfo *streamInfo = [ZegoStreamInfo getStreamInfo:dic];
            [self.playStreamList addObject:streamInfo];
        }
        
        return;
    }
    
    if (streamList.count == 0)
    {
        NSString *logString = [NSString stringWithFormat:NSLocalizedString(@"流更新列表为空", nil)];
        [self addLogString:logString];
        return;
    }
    
    if (flag == 0)
        [self onStreamUpdateForAdd:streamList];
    else if (flag == 1)
        [self onStreamUpdateForDelete:streamList];
}

#pragma mark ZegoLiveAPI
- (void)loginChannel
{
    ZegoUser *user = [[ZegoSettings sharedInstance] getZegoUser];
    bool ret = [getZegoAV_ShareInstance() loginChannel:self.liveChannel user:user];
    assert(ret);
    
    NSLog(@"%s, ret: %d", __func__, ret);
    
    NSString *logString = [NSString stringWithFormat:NSLocalizedString(@"登录channel", nil)];
    [self addLogString:logString];
}

- (void)removeStreamViewContainer:(NSString *)streamID
{
    UIView *view = self.viewContainersDict[streamID];
    if (view == nil)
        return;
    
    [self updateContainerConstraintsForRemove:view containerView:self.playContainerView];
    
    [self.viewContainersDict removeObjectForKey:streamID];
    [self.viewIndexDict removeObjectForKey:streamID];
}

#pragma mark ZegoLiveApiDelegate
- (void)onLoginChannel:(NSString *)channel error:(uint32)err
{
    NSLog(@"%s, err: %u", __func__, err);
    if (err != 0)
    {
        //TODO: error warning
        NSString *logString = [NSString stringWithFormat:NSLocalizedString(@"登录channel失败, error:%d", nil), err];
        [self addLogString:logString];
        return;
    }
    
    NSString *logString = [NSString stringWithFormat:NSLocalizedString(@"登录channel成功, streamID: %s", nil), channel];
    [self addLogString:logString];
    
    if (self.publishView == nil)
    {
        self.publishView = [self createPublishView];
        if (self.publishView)
        {
            [self setAnchorConfig:self.publishView];
            [getZegoAV_ShareInstance() startPreview];
        }
    }
    
    self.viewContainersDict[self.liveStreamID] = self.publishView;
    
    //开始直播
    bool b = [getZegoAV_ShareInstance() startPublishingWithTitle:self.liveTitle streamID:self.liveStreamID];
    assert(b);
    NSLog(@"%s, ret: %d", __func__, b);

    [self addLogString:[NSString stringWithFormat:NSLocalizedString(@"开始直播，流ID:%@", nil), self.liveStreamID]];
    
    //同时开始拉流
    if (self.playStreamList.count == 0)
        [self getStreamList];
    else
    {
        for (ZegoStreamInfo *info in self.playStreamList)
        {
            if (self.viewContainersDict[info.streamID] != nil)
                return;
            
            [self createPlayStream:info.streamID];
            
            NSString *logString = [NSString stringWithFormat:NSLocalizedString(@"继续播放之前的流, 流ID:%@", nil), info.streamID];
            [self addLogString:logString];
            
            if (self.isPublishing)
                self.tipsLabel.text = NSLocalizedString(@"视频聊天中...", nil);
        }
    }
    
    self.loginChannelSuccess = YES;
}

- (void)onPublishSucc:(NSString *)streamID channel:(NSString *)channel streamInfo:(NSDictionary *)info
{
    NSLog(@"%s, stream: %@", __func__, streamID);
    
    [self reportStreamAction:YES streamID:self.liveStreamID];
    
    if (self.playStreamList.count != 0)
        self.tipsLabel.text = NSLocalizedString(@"视频聊天中...", nil);
    
    self.isPublishing = YES;
    self.shouldInterrutped = YES;
    
    NSString *logString = [NSString stringWithFormat:NSLocalizedString(@"发布直播成功,流ID:%@", nil), streamID];
    [self addLogString:logString];
}

- (void)onPublishStop:(uint32)err stream:(NSString *)streamID channel:(NSString *)channel
{
    NSLog(@"%s, stream: %@, err: %u", __func__, streamID, err);
//    assert(streamID.length != 0);
    
    if (err == 1)
    {
        NSString *logString = [NSString stringWithFormat:NSLocalizedString(@"视频结束,流ID:%@", nil), streamID];
        [self addLogString:logString];
    }
    else
    {
        NSString *logString = [NSString stringWithFormat:NSLocalizedString(@"视频结束,流ID：%@, error:%d", nil), streamID, err];
        [self addLogString:logString];
    }
    
    [self reportStreamAction:NO streamID:self.liveStreamID];
    [self removeStreamViewContainer:self.liveStreamID];
    
    self.isPublishing = NO;
    if (self.playStreamList.count == 0)
        self.tipsLabel.text = NSLocalizedString(@"与对方连接中断...", nil);
}

- (void)onPlaySucc:(NSString *)streamID channel:(NSString *)channel
{
    NSLog(@"%s, streamID:%@", __func__, streamID);
    
    NSString *logString = [NSString stringWithFormat:NSLocalizedString(@"播放流成功, 流ID: %@", nil), streamID];
    [self addLogString:logString];
}

- (void)onPlayStop:(uint32)err streamID:(NSString *)streamID channel:(NSString *)channel
{
    NSLog(@"%s, streamID:%@", __func__, streamID);
//    assert(streamID.length != 0);
    
    NSString *logString = [NSString stringWithFormat:NSLocalizedString(@"播放流失败, 流ID:%@, error: %d", nil), streamID, err];
    [self addLogString:logString];
    
    if (streamID.length == 0)
        return;
    
    if (err == 2)
    {
        if (![self isRetryStreamStop:streamID] && [self.viewIndexDict objectForKey:streamID] != nil)
        {
            
            NSString *logString = [NSString stringWithFormat:NSLocalizedString(@"重新播放, 流ID:%@", nil), streamID];
            [self addLogString:logString];
            
            [self.retryStreamList addObject:streamID];
            //尝试重新play
            RemoteViewIndex index = [self.viewIndexDict[streamID] unsignedIntValue];
            [getZegoAV_ShareInstance() startPlayStream:streamID viewIndex:index];
        }
        else
        {
            [self.failedStreamList addObject:streamID];
        }
    }
    
    if (err != 0)
    {
        [self.failedStreamList addObject:streamID];
    }
    
    if (self.failedStreamList.count == self.playStreamList.count)
        self.tipsLabel.text = NSLocalizedString(@"与对方连接中断...", nil);
}

- (BOOL)isRetryStreamStop:(NSString *)streamID
{
    for (NSString *stream in self.retryStreamList)
    {
        if ([streamID isEqualToString:stream])
            return YES;
    }
    
    return NO;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"logSegueIdentifier"])
    {
        UINavigationController *navigationController = [segue destinationViewController];
        ZegoLogTableViewController *logViewController = (ZegoLogTableViewController *)[navigationController.viewControllers firstObject];
        logViewController.logArray = self.logArray;
    }
}

#pragma mark - request video
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
            [self closeView:nil];
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

- (void)requestOtherVideo
{
    [self closeView:nil];
}

@end
