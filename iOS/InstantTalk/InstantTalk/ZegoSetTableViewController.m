//
//  ZegoSetTableViewController.m
//  LiveDemo3
//
//  Created by Strong on 16/6/22.
//  Copyright © 2016年 ZEGO. All rights reserved.
//

#import "ZegoSetTableViewController.h"
#import "ZegoAVKitManager.h"
#import "ZegoSettings.h"
#import "ZegoDataCenter.h"

@interface ZegoSetTableViewController ()
@property (weak, nonatomic) IBOutlet UILabel *version;

@property (weak, nonatomic) IBOutlet UITextField *userID;
@property (weak, nonatomic) IBOutlet UITextField *userName;

@property (weak, nonatomic) IBOutlet UIPickerView *presetPicker;
@property (weak, nonatomic) IBOutlet UILabel *videoResolution;
@property (weak, nonatomic) IBOutlet UILabel *videoFrameRate;
@property (weak, nonatomic) IBOutlet UILabel *videoBitRate;
@property (weak, nonatomic) IBOutlet UISlider *videoResolutionSlider;
@property (weak, nonatomic) IBOutlet UISlider *videoFrameRateSlider;
@property (weak, nonatomic) IBOutlet UISlider *videoBitRateSlider;

@property (weak, nonatomic) IBOutlet UIImageView *avatarView;

@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@end

@implementation ZegoSetTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.videoResolutionSlider.maximumValue = 5;
    [self loadVideoSettings];
    [self loadAccountSettings];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [ZegoSettings sharedInstance].userID = self.userID.text;
    [ZegoSettings sharedInstance].userName = self.userName.text;
    
    [super viewWillDisappear:animated];
}

- (IBAction)onContactUs:(id)sender
{
    [[ZegoDataCenter sharedInstance] contactUs];
}

#pragma mark -- UIPickerViewDelegate, UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [ZegoSettings sharedInstance].presetVideoQualityList.count;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (row >= [ZegoSettings sharedInstance].presetVideoQualityList.count) {
        return ;
    }
    
    NSLog(@"%s: %@", __func__, [ZegoSettings sharedInstance].presetVideoQualityList[row]);
    
    [[ZegoSettings sharedInstance] selectPresetQuality:row];
    
    [self updateViedoSettingUI];
}

//返回当前行的内容,此处是将数组中数值添加到滚动的那个显示栏上
-(NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (row >= [ZegoSettings sharedInstance].presetVideoQualityList.count) {
        return @"ERROR";
    }
    
    return [[ZegoSettings sharedInstance].presetVideoQualityList objectAtIndex:row];
}


- (void)loadAccountSettings {
    NSUInteger userIDInteger = [[ZegoSettings sharedInstance].userID integerValue];
    if (userIDInteger == 0)
    {
        [[ZegoSettings sharedInstance] cleanLocalUser];
    }
    
    self.userID.text = [ZegoSettings sharedInstance].userID;
    self.userName.text = [ZegoSettings sharedInstance].userName;
    NSString *imageName = [[ZegoSettings sharedInstance] getAvatarName:self.userID.text];
    UIImage *avatar = [UIImage imageNamed:imageName];
    [self.avatarView setImage:avatar];
}

- (void)loadVideoSettings {
    self.version.text = ZegoGetSDKVersion();
    [self.presetPicker selectRow:[ZegoSettings sharedInstance].presetIndex inComponent:0 animated:YES];
    [self updateViedoSettingUI];
}

- (IBAction)sliderDidChange:(id)sender {
    [self.presetPicker selectRow:[ZegoSettings sharedInstance].presetVideoQualityList.count - 1 inComponent:0 animated:YES];
    
    ZegoAVConfig *config = [ZegoSettings sharedInstance].currentConfig;
    
    if (sender == self.videoResolutionSlider) {
        int v = (int)self.videoResolutionSlider.value;
        ZegoAVConfigVideoResolution resolution = ZegoAVConfigVideoResolution_640x360;
        if (v == 0)
            resolution = ZegoAVConfigVideoResolution_320x240;
        else if (v == 1)
            resolution = ZegoAVConfigVideoResolution_352x288;
        else if (v == 2)
            resolution = ZegoAVConfigVideoResolution_640x360;
        else if (v == 3)
            resolution = ZegoAVConfigVideoResolution_640x480;
        else if (v == 4)
            resolution = ZegoAVConfigVideoResolution_1280x720;
        else if (v == 5)
            resolution = ZegoAVConfigVideoResolution_1920x1080;
        [config setVideoResolution:resolution];
    } else if (sender == self.videoFrameRateSlider) {
        int v = (int)self.videoFrameRateSlider.value;
        [config setVideoFPS:v];
    } else if (sender == self.videoBitRateSlider) {
        int v = (int)self.videoBitRateSlider.value;
        [config setVideoBitrate:v];
    }
    
    [ZegoSettings sharedInstance].currentConfig = config;
    
    [self updateViedoSettingUI];
}


- (void)updateViedoSettingUI {
    ZegoAVConfig *config = [[ZegoSettings sharedInstance] currentConfig];
    
    float value = 3;
    ZegoAVConfigVideoResolution resolution = [ZegoSettings sharedInstance].currentResolution;
    if (resolution == ZegoAVConfigVideoResolution_320x240)
        value = 0;
    else if (resolution == ZegoAVConfigVideoResolution_352x288)
        value = 1;
    else if (resolution == ZegoAVConfigVideoResolution_640x360)
        value = 2;
    else if (resolution == ZegoAVConfigVideoResolution_640x480)
        value = 3;
    else if (resolution == ZegoAVConfigVideoResolution_1280x720)
        value = 4;
    else if (resolution == ZegoAVConfigVideoResolution_1920x1080)
        value = 5;
    else
        value = 2;
    self.videoResolutionSlider.value = value;
    
    CGSize r = [config getVideoResolution];
    self.videoResolution.text = [NSString stringWithFormat:@"%d X %d", (int)r.width, (int)r.height];
    
    self.videoFrameRateSlider.value = [config getVideoFPS];
    self.videoFrameRate.text = [NSString stringWithFormat:@"%d", [config getVideoFPS]];
    
    self.videoBitRateSlider.value = [config getVideoBitrate];
    self.videoBitRate.text = [NSString stringWithFormat:@"%d", [config getVideoBitrate]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0 && indexPath.row == 1)
    {
        [getZegoAV_ShareInstance() uploadLog];
        [self showUploadAlertView];
    }
}

- (void)showUploadAlertView
{
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"日志上传成功", nil)];
//    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 3 || indexPath.section == 4)
        return YES;
    
    if (indexPath.section == 0 && indexPath.row == 1)
        return YES;
    return NO;
}

- (IBAction)changeAvatar:(id)sender
{
#if TARGET_OS_SIMULATOR
    NSString *defaultUserName = [NSString stringWithFormat:@"simulator-%@", [ZegoSettings sharedInstance].userID];
#else
    NSString *defaultUserName = [NSString stringWithFormat:@"iphone-%@", [ZegoSettings sharedInstance].userID];
#endif
    
    NSString *originUserName = nil;
    if (![defaultUserName isEqualToString:self.userName.text])
        originUserName = self.userName.text;
    
    [[ZegoSettings sharedInstance] cleanLocalUser];
    
    self.userID.text = [ZegoSettings sharedInstance].userID;
    if (originUserName == nil)
        self.userName.text = [ZegoSettings sharedInstance].userName;
    else
        [ZegoSettings sharedInstance].userName = originUserName;
    
    NSString *imageName = [[ZegoSettings sharedInstance] getAvatarName:self.userID.text];
    UIImage *avatar = [UIImage imageNamed:imageName];
    
    [self.avatarView setImage:avatar];
    
    //头像改变时，ID发生变化。需要重新登录
    [self reloginRoom];
    //ID发生变化，需要把历史记录给删除
    [[ZegoDataCenter sharedInstance] clearAllSession];
}

- (void)onTapTableView:(UIGestureRecognizer *)gesture
{
    if (!self.userName.isEditing)
        [self.view endEditing:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.text.length != 0)
    {
        [textField resignFirstResponder];
        return YES;
    }
    
    return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (self.tapGesture == nil)
        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapTableView:)];
    
    [self.tableView addGestureRecognizer:self.tapGesture];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (self.tapGesture)
    {
        [self.tableView removeGestureRecognizer:self.tapGesture];
        self.tapGesture = nil;
    }
    
    if (textField == self.userName && ![self.userName.text isEqualToString:[ZegoSettings sharedInstance].userName])
    {
        [self reloginRoom];
    }
}

- (void)reloginRoom
{
    [ZegoSettings sharedInstance].userID = self.userID.text;
    [ZegoSettings sharedInstance].userName = self.userName.text;
    
    [[ZegoDataCenter sharedInstance] leaveRoom];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLeaveRoom:) name:kUserLeaveRoomNotification object:nil];
    
    if (self.indicatorView)
        self.indicatorView = nil;
    
    _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.indicatorView.translatesAutoresizingMaskIntoConstraints = YES;
    self.indicatorView.frame = CGRectMake((CGRectGetWidth(self.view.bounds) - 40)/2, (CGRectGetHeight(self.view.bounds) - 40)/2, 40, 40);
    [self.view addSubview:self.indicatorView];
    [self.indicatorView startAnimating];
}

- (void)onLeaveRoom:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kUserLeaveRoomNotification object:nil];
    
    [[ZegoDataCenter sharedInstance] loginRoom];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLoginRoom:) name:kUserLoginNotification object:nil];
}

- (void)onLoginRoom:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kUserLoginNotification object:nil];
    [self.indicatorView stopAnimating];
    [self.indicatorView removeFromSuperview];
    self.indicatorView = nil;
}

@end
