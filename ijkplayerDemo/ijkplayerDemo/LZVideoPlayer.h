//
//  LZVideoPlayer.h
//  ijkplayerDemo
//
//  Created by mac on 16/11/8.
//  Copyright © 2016年 youshixiu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <IJKMediaFramework/IJKMediaFramework.h>
@class LZVideoPlayer;

@protocol LZVideoPlayerDelegate <NSObject>

@optional
//准备开始播放
- (void)videoPlayerIsReadyToPlayVideo:(LZVideoPlayer *)videoPlayer;
//播放结束
- (void)videoPlayerDidReachEnd:(LZVideoPlayer *)videoPlayer;
//时间发生改变
- (void)videoPlayer:(LZVideoPlayer *)videoPlayer timeDidChange:(NSTimeInterval)currentTime;
//播放速率发生改变
- (void)videoPlayer:(LZVideoPlayer *)videoPlayer rateDidChange:(float)rate;
//缓存时间范围发生改变
- (void)videoPlayer:(LZVideoPlayer *)videoPlayer loadedTimeRangeDidChange:(float)duration;
//回放缓冲为空
- (void)videoPlayerPlaybackBufferEmpty:(LZVideoPlayer *)videoPlayer;
//加载失败
- (void)videoPlayer:(LZVideoPlayer *)videoPlayer didFailWithError:(NSError *)error;

@end

@interface LZVideoPlayer : NSObject

@property (nonatomic, weak) id<LZVideoPlayerDelegate> delegate;

@property (atomic, retain, readonly) id <IJKMediaPlayback> player;

//是否正在播放
@property (nonatomic, assign, getter=isPlaying, readonly) BOOL playing;
//是否循环播放
@property (nonatomic, assign, getter=isLooping) BOOL looping;
//是否开启静音
@property (nonatomic, assign, getter=isMuted) BOOL muted;
//是否是直播
@property (nonatomic, assign) BOOL isLive;

//设置播放地址
- (void)setURL:(NSURL *)URL;

- (void)prepareToPlay;
//播放
- (void)play;
//暂停
- (void)pause;
//快进到某个时间轴
- (void)seekToTime:(NSTimeInterval)time;
//重置
- (void)reset;
//关闭(退出播放器一定要调用)
- (void)shutdown;

//初始化播放器
- (instancetype)initWithParentView:(UIView *)view;

@end

@interface YSXVideoPlayer : NSObject

//AirPlay
- (void)enableAirPlay;
- (void)disableAirPlay;
- (BOOL)isAirplayEnabled;

//Time Updates
- (void)enableTimeUpdates;
- (void)disableTimeUpdates;

//Scrubbing
- (void)startScrubbing;
- (void)scrub:(float)time;
- (void)stopScrubbing;

//Volume
- (void)setVolume:(float)volume;
- (void)fadeInVolume;
- (void)fadeOutVolume;

@end

