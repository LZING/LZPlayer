//
//  LZPlayerViewController.m
//  ijkplayerDemo
//
//  Created by mac on 16/11/8.
//  Copyright © 2016年 youshixiu. All rights reserved.
//

#import "LZPlayerViewController.h"
#import <IJKMediaFramework/IJKMediaFramework.h>
#import <AVFoundation/AVFoundation.h>

@interface LZPlayerViewController ()

@property (atomic, retain) id <IJKMediaPlayback> player;

@property (nonatomic, copy) NSString *liveUrlString;

@property (strong, nonatomic) UILabel * timer;

@property (nonatomic, assign) BOOL isLive;

@end

@implementation LZPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _timer = [[UILabel alloc] initWithFrame:CGRectMake(200, 100, 200, 100)];
    _timer.backgroundColor = [UIColor clearColor];
    _timer.textColor = [UIColor whiteColor];
    _timer.adjustsFontSizeToFitWidth = NO;
    _timer.textAlignment = NSTextAlignmentLeft;
    _timer.text = @"--:--";
    _timer.font = [UIFont systemFontOfSize:20];
    [self.view addSubview:_timer];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    self.isLive = YES;
    [self preparePlay];
}

- (NSString *)liveUrlString {
    if (_liveUrlString == nil) {
        _liveUrlString = @"http://source-netcenter.malazhibo.lashou.com/malazhibo-z1.lashou-live.58057b485e77b0969f2836df--20161104231840.mp4";
    }
    return _liveUrlString;
}

- (void)refreshPlayerControl {
    NSTimeInterval position = self.player.currentPlaybackTime;
    NSInteger intPositon = position + 0.5;
    NSInteger duration   = self.player.duration;
    if (intPositon > 0) {
//        self.slider.maximumValue = position;
        self.timer.text = [NSString stringWithFormat:@"%02d:%02d / %02d:%02d",(int)(intPositon/60),(int)(intPositon%60), (int)(duration/60),(int)(duration%60)];
    } else {
//        self.slider.maximumValue = 1.0f;
        self.timer.text = @"直播--:--";
    }
    
    BOOL isPlaying = [self.player isPlaying];

    //    self.overlay.hidden = YES;
    if (isPlaying) {
//        [self.indicator stopAnimating];
        
//        NSLog(@"-----------------------------------playing");
    }else if(!isPlaying){
//        [self.indicator startAnimating];
//        NSLog(@"----------------------------------no");
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshPlayerControl) object:nil];
//    if (!self.overlay.hidden) {
        [self performSelector:@selector(refreshPlayerControl) withObject:nil afterDelay:0.5];
//    }
}

- (void)preparePlay {
    if ([self.player isPlaying]) {
        return;
    }
    
    if (self.liveUrlString == nil || [self.liveUrlString isEqualToString:@""]) {
        return;
    }
    
    if (self.player == nil) {
        [IJKFFMoviePlayerController checkIfFFmpegVersionMatch:YES];
        
        IJKFFOptions *options = [IJKFFOptions optionsByDefault];
        // Set param
        [options setPlayerOptionIntValue:0 forKey:@"videotoolbox"];
        [options setCodecOptionIntValue:IJK_AVDISCARD_DEFAULT forKey:@"skip_loop_filter"];
        [options setCodecOptionIntValue:IJK_AVDISCARD_DEFAULT forKey:@"skip_frame"];
        
        if (_isLive) {
            // Param for living
            [options setFormatOptionIntValue:1024 * 4 forKey:@"probsize"];
            [options setFormatOptionIntValue:50000 forKey:@"analyzeduration"];
            [options setPlayerOptionIntValue:3000 forKey:@"max_cached_duration"];
            [options setPlayerOptionIntValue:20000 forKey:@"max_read_frame_duration"];
            [options setPlayerOptionIntValue:1 forKey:@"infbuf"];
            [options setPlayerOptionIntValue:0 forKey:@"packet-buffering"];
        } else {
            // Param for playback
            [options setFormatOptionIntValue:1024 * 16 forKey:@"probsize"];
            [options setFormatOptionIntValue:50000 forKey:@"analyzeduration"];
            [options setPlayerOptionIntValue:0 forKey:@"max_cached_duration"];
            [options setPlayerOptionIntValue:0 forKey:@"max_read_frame_duration"];
            [options setPlayerOptionIntValue:0 forKey:@"infbuf"];
            [options setPlayerOptionIntValue:1 forKey:@"packet-buffering"];
        }
        
        NSURL * liveUrl = [NSURL URLWithString:self.liveUrlString];
        self.player = [[IJKFFMoviePlayerController alloc] initWithContentURL:liveUrl withOptions:options];
#ifdef DEBUG
        [IJKFFMoviePlayerController setLogReport:NO];
        [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_INFO];
#else
        [IJKFFMoviePlayerController setLogReport:NO];
        [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_INFO];
#endif
        self.player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        
        self.player.view.frame = self.view.bounds;
        self.player.scalingMode = IJKMPMovieScalingModeAspectFit;
        self.view.autoresizesSubviews = YES;
        [self.view insertSubview:self.player.view atIndex:0];
        [self installMovieNotificationObservers];
        [self installNotificationObservers];
        [self.player setPauseInBackground:NO];
    }
    
    [self.player prepareToPlay];
    
    [self refreshPlayerControl];
    
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
}

- (void)stopPlay {
    [self.player.view removeFromSuperview];
    [self removeMovieNotificationObservers];
    [self.player shutdown];
    self.player = nil;
}

- (void)installMovieNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackDidFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                 name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                               object:_player];
}

- (void)installNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)removeMovieNotificationObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:IJKMPMoviePlayerLoadStateDidChangeNotification object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:IJKMPMoviePlayerPlaybackDidFinishNotification object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:IJKMPMoviePlayerPlaybackStateDidChangeNotification object:_player];
}

///离开APP
- (void)onWillResignActive {
    //播放器在播放视频的时候，给予后台权限
    if ([self.player isPlaying]) {
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        [self becomeFirstResponder];
    }
}

///APP处于活跃状态
- (void)onDidBecomeActive {
    //关闭后台权限
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

- (void)loadStateDidChange:(NSNotification*)notification {
    //    MPMovieLoadStateUnknown        = 0,
    //    MPMovieLoadStatePlayable       = 1 << 0,
    //    MPMovieLoadStatePlaythroughOK  = 1 << 1, // Playback will be automatically started in this state when shouldAutoplay is YES
    //    MPMovieLoadStateStalled        = 1 << 2, // Playback will be automatically paused in this state, if started
    
    IJKMPMovieLoadState loadState = _player.loadState;
    
    if ((loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStatePlaythroughOK: %d\n", (int)loadState);
    } else if ((loadState & IJKMPMovieLoadStateStalled) != 0) {
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStateStalled: %d\n", (int)loadState);
    } else {
        NSLog(@"loadStateDidChange: ???: %d\n", (int)loadState);
    }
}

- (void)moviePlayBackDidFinish:(NSNotification*)notification {
    //    MPMovieFinishReasonPlaybackEnded,
    //    MPMovieFinishReasonPlaybackError,
    //    MPMovieFinishReasonUserExited
    int reason = [[[notification userInfo] valueForKey:IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    
    switch (reason) {
            ///这里是主播关闭了推流
        case IJKMPMovieFinishReasonPlaybackEnded:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackEnded: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonUserExited:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonUserExited: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonPlaybackError:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackError: %d\n", reason);
            break;
            
        default:
            NSLog(@"playbackPlayBackDidFinish: ???: %d\n", reason);
            break;
    }
}

- (void)mediaIsPreparedToPlayDidChange:(NSNotification*)notification {
    [self.player play];
    NSLog(@"mediaIsPreparedToPlayDidChange\n");
}

- (void)moviePlayBackStateDidChange:(NSNotification*)notification {
    //    MPMoviePlaybackStateStopped,
    //    MPMoviePlaybackStatePlaying,
    //    MPMoviePlaybackStatePaused,
    //    MPMoviePlaybackStateInterrupted,
    //    MPMoviePlaybackStateSeekingForward,
    //    MPMoviePlaybackStateSeekingBackward
    
    switch (_player.playbackState) {
        case IJKMPMoviePlaybackStateStopped: {
            NSLog(@"moviePlayBackStateDidChange %d: stoped", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStatePlaying: {
            NSLog(@"moviePlayBackStateDidChange %d: playing", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStatePaused: {
            NSLog(@"moviePlayBackStateDidChange %d: paused", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStateInterrupted: {
            NSLog(@"moviePlayBackStateDidChange %d: interrupted", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStateSeekingForward:
        case IJKMPMoviePlaybackStateSeekingBackward: {
            NSLog(@"moviePlayBackStateDidChange %d: seeking", (int)_player.playbackState);
            break;
        }
        default: {
            NSLog(@"moviePlayBackStateDidChange %d: unknown", (int)_player.playbackState);
            break;
        }
    }
}


@end
