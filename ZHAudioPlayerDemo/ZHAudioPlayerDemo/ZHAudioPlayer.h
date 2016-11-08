//  ZHAudioPlayer
//  ZHAudioPlayerDemo
//
//  播放的网络音频文件缓存为caf格式的文件
//
//  Created by 唐祖恒 on 16/10/8.

//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>//需要添加AVFoundation.framework

typedef NS_ENUM (NSUInteger, HCDAudioFileType) {
    ZHAudioFileType_Network = 0,
    ZHAudioFileType_Local,
};

@protocol ZHAudioPlayerDelegate <NSObject>

@optional

/**
 *  开始播放
 *
 *  @param audioPlayer 音频播放器
 */
- (void)didAudioPlayerBeginPlay:(AVAudioPlayer *)audioPlayer;

/**
 *  停止播放
 *
 *  @param audioPlayer 音频播放器
 */
- (void)didAudioPlayerStopPlay:(AVAudioPlayer *)audioPlayer;

/**
 *  暂停播放
 *
 *  @param audioPlayer 音频播放器
 */
- (void)didAudioPlayerPausePlay:(AVAudioPlayer *)audioPlayer;

/**
 *  播放完成
 *
 *  @param audioPlayer 音频播放器
 */
- (void)didAudioPlayerFinishPlay:(AVAudioPlayer *)audioPlayer;

/**
 *  播放进度
 *
 *  @param audioPlayer 音频播放器
 */
- (void)didAudioPlayerUpdateProgess:(AVAudioPlayer *)audioPlayer;

/**
 *  播放错误
 *
 *  @param audioPlayer 音频播放器
 */
- (void)didAudioPlayerFailPlay:(AVAudioPlayer *)audioPlayer;

@end

@interface ZHAudioPlayer : NSObject<AVAudioPlayerDelegate>

+ (ZHAudioPlayer *)sharedInstance;

@property (nonatomic, assign) BOOL                  stopBool;
@property (nonatomic, strong) AVAudioPlayer         *audioPlayer;
@property (nonatomic, copy  ) NSString              *pathName;
@property (nonatomic, assign) BOOL                  isRepeat;//是否重复播放
@property (nonatomic, strong) CADisplayLink*        displayLink;//定时器


//声明协议代理
@property (nonatomic, retain) id<ZHAudioPlayerDelegate> delegate;

/**
 *  播放网络上的音频文件
 *
 *  @param urlPath   音频网络地址
 *  @param isPlaying 是否播放
 */
- (void)manageAudioWithUrlPath:(NSString *)urlPath
                   playOrPause:(BOOL)isPlaying;

/**
 *  播放本地的音频文件
 *
 *  @param localPath 本地音频文件
 *  @param isPlaying 是否播放
 */
- (void)manageAudioWithLocalPath:(NSString *)localPath
                     playOrPause:(BOOL)isPlaying;

/**
 *  暂停播放
 */
- (void)pausePlayingAudio;

/**
 *  停止播放
 */
- (void)stopAudio;

/**
 *  静音
 */
- (void)noVoice;

/**
 *  重置音量
 */
- (void)resetVoice;

//清空歌曲缓存文件夹
- (void) clearAudioDir;

@end
