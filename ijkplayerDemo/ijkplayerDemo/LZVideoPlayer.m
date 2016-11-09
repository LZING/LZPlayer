//
//  LZVideoPlayer.m
//  ijkplayerDemo
//
//  Created by mac on 16/11/8.
//  Copyright © 2016年 youshixiu. All rights reserved.
//

#import "LZVideoPlayer.h"

@interface LZVideoPlayer ()

@property (atomic, retain) id <IJKMediaPlayback> player;

@property (nonatomic, strong) NSURL *liveUrl;

@property (nonatomic, assign, getter=isPlaying, readwrite) BOOL playing;
@property (nonatomic, assign, getter=isScrubbing) BOOL scrubbing;
@property (nonatomic, assign, getter=isSeeking) BOOL seeking;

@property (nonatomic, strong) UIView *view;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation LZVideoPlayer

- (instancetype)initWithParentView:(UIView *)view {
    if (self = [super init]) {
        self.view = view;
    }
    return self;
}

- (void)preparePlay {
    if ([self.player isPlaying]) {
        NSLog(@"正在播放");
        return;
    }
    
    if (self.liveUrl == nil || [self.liveUrl isEqual:@""]) {
        NSLog(@"请先初始化URL");
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
        
//        NSURL * liveUrl = [NSURL URLWithString:self.liveUrlString];
        self.player = [[IJKFFMoviePlayerController alloc] initWithContentURL:self.liveUrl withOptions:options];
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
        [self installTimer];
        [self.player setPauseInBackground:NO];
    }
    
    [self.player prepareToPlay];
    
//    [self refreshPlayerControl];
    
    //修改音频播放
//    NSError *error = nil;
//    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
//    [[AVAudioSession sharedInstance] setActive:YES error:&error];
}

//设置播放地址
- (void)setURL:(NSURL *)URL {
    _liveUrl = URL;
}

- (void)prepareToPlay {
    [self preparePlay];
}

//播放
- (void)play {
    [self.player play];
}

//暂停
- (void)pause {
    [self.player pause];
}

//关闭
- (void)shutdown {
    [self.player.view removeFromSuperview];
    [self removeMovieNotificationObservers];
    [self removeTimer];
    [self.player shutdown];
    self.player = nil;
}

//快进到某个时间轴
- (void)seekToTime:(NSTimeInterval)time {
    self.player.currentPlaybackTime = time;
}

//重置
- (void)reset {
    [self.player stop];
    [self.player play];
}

#pragma mark - notification
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

- (void)installTimer {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(observeCurrentPlaybackTime) userInfo:nil repeats:YES];
}

- (void)removeMovieNotificationObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:IJKMPMoviePlayerLoadStateDidChangeNotification object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:IJKMPMoviePlayerPlaybackDidFinishNotification object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:IJKMPMoviePlayerPlaybackStateDidChangeNotification object:_player];
}

- (void)removeTimer {
    self.timer = nil;
    [self.timer invalidate];
}

///离开APP
- (void)onWillResignActive {
    //播放器在播放视频的时候，给予后台权限
    if ([self.player isPlaying]) {
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
//        [self becomeFirstResponder];
    }
}

///APP处于活跃状态
- (void)onDidBecomeActive {
    //关闭后台权限
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

- (void)observeCurrentPlaybackTime {
    if ([self.delegate respondsToSelector:@selector(videoPlayer:timeDidChange:)]) {
        [self.delegate videoPlayer:self timeDidChange:self.player.currentPlaybackTime];
    }
    
    if ([self.delegate respondsToSelector:@selector(videoPlayer:loadedTimeRangeDidChange:)]) {
        [self.delegate videoPlayer:self loadedTimeRangeDidChange:self.player.bufferingProgress];
    }
}

#pragma mark - NOTIFICATION
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
            if ([self.delegate respondsToSelector:@selector(videoPlayerDidReachEnd:)]) {
                [self.delegate videoPlayerDidReachEnd:self];
            }
            break;
        }
        case IJKMPMoviePlaybackStatePlaying: {
            NSLog(@"moviePlayBackStateDidChange %d: playing", (int)_player.playbackState);
            if ([self.delegate respondsToSelector:@selector(videoPlayerIsReadyToPlayVideo:)]) {
                [self.delegate videoPlayerIsReadyToPlayVideo:self];
            }
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


#pragma mark - getter & setter
- (BOOL)isPlaying {
    return self.player.isPlaying;
}

@end
