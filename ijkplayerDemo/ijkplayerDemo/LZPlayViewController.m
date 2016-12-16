//
//  ViewController.m
//  ijkplayerDemo
//
//  Created by mac on 16/11/8.
//  Copyright © 2016年 youshixiu. All rights reserved.
//

#import "LZPlayViewController.h"
#import "LZVideoPlayer.h"

typedef NS_ENUM(NSUInteger, LZVideoStatus) {
    LZVideoStatusUnKnow,
    LZVideoStatusReadyToPlay,
    LZVideoStatusPlaying,
    LZVideoStatusFailed,
    LZVideoStatusEnded,
    LZVideoStatusWiFiWarning
};

@interface LZPlayViewController ()<UIGestureRecognizerDelegate,
UITextFieldDelegate, LZVideoPlayerDelegate>

//导航栏
@property (nonatomic, weak) IBOutlet UIView *navigationView;
@property (nonatomic, weak) IBOutlet UIButton *leftButton;

//control Pannel
@property (nonatomic, weak) IBOutlet UIView *controlPannelView;
@property (nonatomic, weak) IBOutlet UIButton *playButton;
@property (nonatomic, weak) IBOutlet UILabel *leftTimeLabel;
@property (nonatomic, weak) IBOutlet UIView *durationView;
@property (nonatomic, weak) IBOutlet UIButton *seekButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *seekViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *loadViewWidthConstraint;
@property (nonatomic, weak) IBOutlet UILabel *rightTimeLabel;

@property (weak, nonatomic) IBOutlet UIView *statusView;
@property (weak, nonatomic) IBOutlet UIView *InteractionView;//交互View
@property (nonatomic, assign) LZVideoStatus videoStatus;

///播放结束
@property (weak, nonatomic) IBOutlet UIView *playEndView;
@property (weak, nonatomic) IBOutlet UILabel *numLabel;
@property (weak, nonatomic) IBOutlet UIButton *playEndBackBurron;
@property (weak, nonatomic) IBOutlet UIImageView *playEndBGImageView;

@property (nonatomic,assign) BOOL isPlaying;
@property (nonatomic, assign) float rate;
@property (nonatomic,assign) BOOL isLoading;
@property (nonatomic, assign) BOOL controlHidden;  //是否隐藏控制器
@property (nonatomic, assign) NSTimeInterval currentSecond; //当前播放时间
@property (nonatomic, assign) NSTimeInterval totalSecond;   //总时长
@property (nonatomic, assign) NSTimeInterval loadSecond; //缓冲时长

@property (nonatomic, strong) LZVideoPlayer *videoPlayer;

@property (weak, nonatomic) IBOutlet UIScrollView *baseScrollerView;

@property (weak, nonatomic) IBOutlet UIView *videoView;

@end

@implementation LZPlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = YES;
    
    self.baseScrollerView.contentSize = CGSizeMake(CGRectGetWidth([UIScreen mainScreen].bounds) * 2, 0);
    
    //初始化播放器
    self.videoPlayer = [[LZVideoPlayer alloc] initWithParentView:self.videoView];
    self.videoPlayer.delegate = self;
    NSURL *url = [NSURL URLWithString:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];
    [self.videoPlayer setURL:url];
    //    self.videoPlayer.player.view.frame = self.videoView.bounds;
    //    [self.videoView addSubview:self.videoPlayer.player.view];
    //    self.view.autoresizesSubviews = YES;
    //    [self.videoView insertSubview:self.videoPlayer.player.view atIndex:0];
    
    [self prepareToPlay];
    
    [self initControl];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
     [self.videoPlayer shutdown];
}

- (void)dealloc {
    NSLog(@"死了");
}

- (void)initControl {
    _controlHidden = NO;
    self.seekButton.enabled = NO;
    self.playButton.enabled = NO;
    
//    UITapGestureRecognizer  *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backTap)];
//    tap.numberOfTapsRequired = 1;
//    tap.delegate = self;
//    [self.view addGestureRecognizer:tap];
    
    //双击,全屏/退出全屏
//    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTaped)];
//    doubleTap.numberOfTapsRequired = 2;
//    doubleTap.delegate = self;
//    [self.view addGestureRecognizer:doubleTap];
//    [tap requireGestureRecognizerToFail:doubleTap];
    
    UIPanGestureRecognizer *seekButtonPanRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(seekButtonPan:)];
    [self.seekButton addGestureRecognizer:seekButtonPanRecognizer];
    
    //    [self initTitleLabel];
}

//- (void)backTap {
//    self.controlHidden = !self.controlHidden;
//}

//- (void)doubleTaped {
    //    AVPlayerLayer *layer = (AVPlayerLayer *)self.videoView.layer;
    //    if (layer.videoGravity == AVLayerVideoGravityResizeAspect) {
    //        layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    //    }
    //    else if (layer.videoGravity == AVLayerVideoGravityResizeAspectFill){
    //        layer.videoGravity = AVLayerVideoGravityResizeAspect;
    //    }
//}

- (void)prepareToPlay {
    [self.videoPlayer prepareToPlay];
}

- (void)play {
    self.isPlaying = YES;
    self.isLoading = YES;
    [self.videoPlayer play];
    self.playButton.selected = YES;
}

- (void)pause {
    self.isPlaying = NO;
    [self.videoPlayer pause];
    self.playButton.selected = NO;
}

- (void)seekButtonPan:(UIPanGestureRecognizer *)recognizer {
    CGPoint point = [recognizer translationInView:self.view];
    CGFloat x = point.x;
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self pause];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        
        self.seekViewWidthConstraint.constant += x;
        if (self.seekViewWidthConstraint.constant < 0) {
            self.seekViewWidthConstraint.constant = 0;
        }
        else if (self.seekViewWidthConstraint.constant > CGRectGetWidth(self.durationView.frame) ) {
            self.seekViewWidthConstraint.constant = CGRectGetWidth(self.durationView.frame);
        }
        CGFloat progress = (self.seekViewWidthConstraint.constant) * 1.0 / CGRectGetWidth(self.durationView.frame);
        _currentSecond = self.totalSecond * progress;
        
    } else if (recognizer.state == UIGestureRecognizerStateEnded){
        [self.videoPlayer seekToTime:self.currentSecond];
        [self play];
    }
    
    [recognizer setTranslation:CGPointZero inView:self.view];
}

- (void)setControlHidden:(BOOL)controlHidden {
    _controlHidden = controlHidden;
    if (_controlHidden) {
        self.controlPannelView.hidden = YES;
    } else {
        self.controlPannelView.hidden = NO;
    }
    
    [self prefersStatusBarHidden];
}

- (IBAction)backButtonClick:(id)sender {
//    [self.navigationController popViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)playButtonClick:(UIButton *)sender {
    if (sender.selected) {
        [self pause];
    } else {
        [self play];
    }
}

#pragma mark - LZVideoPlayerDelegate -
- (void)videoPlayerIsReadyToPlayVideo:(LZVideoPlayer *)videoPlayer {
    self.videoStatue = LZVideoStatusReadyToPlay;
//    AVPlayerItem *playerItem = self.videoPlayer.player.currentItem;
    NSInteger duration   = self.videoPlayer.player.duration;
    self.totalSecond = duration;// 转换成秒
}

- (void)videoPlayerDidReachEnd:(LZVideoPlayer *)videoPlayer {
    self.videoStatue = LZVideoStatusEnded;
}

- (void)videoPlayer:(LZVideoPlayer *)videoPlayer timeDidChange:(NSTimeInterval)currentTime {
//    CGFloat timeFloat = cmTime.value/cmTime.timescale;
    self.currentSecond = currentTime;
}

- (void)videoPlayer:(LZVideoPlayer *)videoPlayer rateDidChange:(float)rate {
    self.rate = rate;
}

- (void)videoPlayer:(LZVideoPlayer *)videoPlayer loadedTimeRangeDidChange:(float)duration {
    self.loadSecond = duration;
}

- (void)videoPlayerPlaybackBufferEmpty:(LZVideoPlayer *)videoPlayer {
    self.videoStatue = LZVideoStatusUnKnow;
}

- (void)videoPlayer:(LZVideoPlayer *)videoPlayer didFailWithError:(NSError *)error {
    self.videoStatue = LZVideoStatusFailed;
}

- (IBAction)playBackClick:(id)sender {
    self.playEndView.hidden = YES;
    
    [self play];
}

- (void)setVideoStatue:(LZVideoStatus)videoStatus {
    _videoStatus = videoStatus;
    
    switch (videoStatus) {
        case LZVideoStatusReadyToPlay: {
            self.seekButton.enabled = YES;
            self.playButton.enabled = YES;

            break;
        }
            
        case LZVideoStatusFailed: {
            
            self.seekButton.enabled = YES;
            self.playButton.enabled = YES;
            
            self.statusView.hidden = NO;
            break;
        }
            
        case LZVideoStatusEnded: {
            self.seekButton.enabled = YES;
            self.playButton.enabled = YES;
            
            [self iOS8blurView:self.playEndBGImageView Frame:[UIScreen mainScreen].bounds];
            
            self.playEndView.hidden = NO;
            
            break;
        }
            
        case LZVideoStatusPlaying: {
            self.seekButton.enabled = YES;
            self.playButton.enabled = YES;
            
            break;
        }
            
        case LZVideoStatusWiFiWarning: {
            self.seekButton.enabled = NO;
            self.playButton.enabled = NO;
            
            self.statusView.hidden = NO;

        }
        default:
            break;
    }
}

- (void)setTotalSecond:(NSTimeInterval)totalSecond {
    _totalSecond = totalSecond;
    if (_totalSecond) {
        self.seekButton.userInteractionEnabled = YES;
        self.rightTimeLabel.text = [self longTimeStringWithTimeInterval:_totalSecond];
    } else {
        self.rightTimeLabel.text = @"--:--";
        self.seekButton.userInteractionEnabled = NO;
    }
}

- (void)setCurrentSecond:(NSTimeInterval)currentSecond {
    _currentSecond = currentSecond;
    if (_totalSecond <= 0) {
        return;
    }
    
    if (_currentSecond >= 0) {
        self.leftTimeLabel.text = [self longTimeStringWithTimeInterval:_currentSecond];
        
        CGFloat progress = _currentSecond * 1.0 / _totalSecond;
        progress = progress > 1.0 ? 1.0 : progress;
        
        CGFloat durationViewWidth = CGRectGetWidth(self.durationView.frame);
        self.seekViewWidthConstraint.constant = durationViewWidth * progress;
    } else {
        self.leftTimeLabel.text = @"--:--";
    }
}

- (void)setLoadSecond:(NSTimeInterval)loadSecond {
    _loadSecond = loadSecond;
    if (_totalSecond <= 0) {
        return;
    }
    CGFloat progress = _loadSecond * 1.0 / _totalSecond;
    progress = progress > 1.0 ? 1.0 : progress;
    CGFloat durationViewWidth = CGRectGetWidth(self.durationView.frame);
    self.loadViewWidthConstraint.constant = durationViewWidth * progress;
}

- (void)iOS8blurView:(UIView *)view Frame:(CGRect)frame {
    
    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    
    UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    
    visualEffectView.frame = frame;
    
    [view addSubview:visualEffectView];
}

//根据时间转换为对应的时间字符串00:00:00
- (NSString *)longTimeStringWithTimeInterval:(NSTimeInterval)interval {
    //四舍五入
    int totalTime = round(interval);
    int hour = totalTime / 3600;
    int min = totalTime % 3600 / 60;
    int second = totalTime % 60;
    
    NSString *resultStr = nil;
    if (hour <= 0) {
        resultStr = [NSString stringWithFormat:@"%02d:%02d", min, second];
    } else if (hour > 60) {
        resultStr = [NSString stringWithFormat:@"%d:%02d:%02d", hour, min, second];
    } else {
        resultStr = [NSString stringWithFormat:@"%02d:%02d:%02d", hour, min, second];
    }
    
    return resultStr;
}

@end
