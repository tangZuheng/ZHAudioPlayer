//  ZHAudioPlayer
//  ZHAudioPlayerDemo
//
//  播放的网络音频文件缓存为caf格式的文件
//
//  Created by 唐祖恒 on 16/10/8.

//

#import "ZHAudioPlayer.h"
#import <UIKit/UIKit.h>

@implementation ZHAudioPlayer

+ (ZHAudioPlayer *)sharedInstance {
    static ZHAudioPlayer *instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ZHAudioPlayer alloc]init];
    });
    
    return instance;
}

- (id)init {
    if (self = [super init]) {
        //        [self changeProximityMonitorEnableState:NO];
    }
    return self;
}

- (void)dealloc {
    //    [self changeProximityMonitorEnableState:NO];
}

#pragma mark - 近距离传感器

- (void)changeProximityMonitorEnableState:(BOOL)enable {
    [[UIDevice currentDevice] setProximityMonitoringEnabled:enable];
    if ([UIDevice currentDevice].proximityMonitoringEnabled == YES) {
        if (enable) {
            //添加近距离事件监听，添加前先设置为YES，如果设置完后还是NO的读话，说明当前设备没有近距离传感器
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sensorStateChange:) name:UIDeviceProximityStateDidChangeNotification object:nil];
        } else {
            //删除近距离事件监听
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceProximityStateDidChangeNotification object:nil];
            [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
        }
    }
}

/**
 *  传感器状态改变时，接受到通知响应方法
 *
 *  @param notification 通知中心
 */
- (void)sensorStateChange:(NSNotificationCenter *)notification {
    //如果此时手机靠近面部放在耳朵旁，那么声音将通过听筒输出，并将屏幕变暗
    if ([[UIDevice currentDevice] proximityState] == YES) {
        //黑屏 NSLog(@"Device is close to user");
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        
    } else {
        //没黑屏幕  NSLog(@"Device is not close to user");
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        if (!_audioPlayer || !_audioPlayer.isPlaying) {
            //没有播放了，也没有在黑屏状态下，就可以把距离传感器关了
            [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
        }
    }
}

//获取保存地址
- (NSString *) getSaveAudioPath:(NSString *)filePath{
    //这里自己写需要保存数据的路径
    NSString *dirPath = [NSString stringWithFormat:@"%@/audio/", [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]];
    [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *cachePath = [NSString stringWithFormat:@"%@/%@", dirPath, filePath];
    return cachePath;
}

- (void)manageAudioWithUrlPath:(NSString *)urlPath playOrPause:(BOOL)isPlaying {
    //这里自己写需要保存数据的路径
    NSString *cachePath = [self getSaveAudioPath: [urlPath lastPathComponent]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
        if (isPlaying) {
            [self playAudioWithPath:cachePath whiteType:ZHAudioFileType_Local];
        } else {
            [self pausePlayingAudio];
        }
    } else {
        if (isPlaying) {
            [self playAudioWithPath:urlPath whiteType:ZHAudioFileType_Network];
        } else {
            [self pausePlayingAudio];
        }
    }
}

- (void)manageAudioWithLocalPath:(NSString *)localPath playOrPause:(BOOL)isPlaying {
    if (isPlaying) {
        [self playAudioWithPath:localPath whiteType:ZHAudioFileType_Local];
    } else {
        [self pausePlayingAudio];
    }
}

- (void)pausePlayingAudio {
    if (_audioPlayer) {
        [_audioPlayer pause];
        if ([self.delegate respondsToSelector:@selector(didAudioPlayerPausePlay:)]) {
            [self.delegate didAudioPlayerPausePlay:_audioPlayer];
        }
        if (_displayLink) {
            _displayLink.paused = YES;
        }
    }
}

- (void)resetVoice {
    //    _audioPlayer.volume = 0.4;
}

- (void)noVoice {
    //    _audioPlayer.volume = 0.0;
}

- (void)stopAudio {
    self.pathName = @"";
    if (_audioPlayer && _audioPlayer.isPlaying) {
        [_audioPlayer stop];
    }
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
    if ([self.delegate respondsToSelector:@selector(didAudioPlayerStopPlay:)]) {
        [self.delegate didAudioPlayerStopPlay:_audioPlayer];
    }
    if (_displayLink) {
        _displayLink = nil;
    }
}

#pragma mark - AVAudioPlayer播放结束代理方法
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if(flag){
        
        if (_isRepeat) {
            _stopBool = NO;
            [self playAudio];
            return;
        }
        //响应播放结束方法
        if ([self.delegate respondsToSelector:@selector(didAudioPlayerFinishPlay:)]) {
            [self.delegate didAudioPlayerFinishPlay:_audioPlayer];
        }
    }
}

//播放进度
- (void) audioPlayerUpdateProgess
{
    //响应播放进度
    if (_audioPlayer && [self.delegate respondsToSelector:@selector(didAudioPlayerUpdateProgess:)]) {
        [self.delegate didAudioPlayerUpdateProgess:_audioPlayer];
    }
}


#pragma mark - Setter Getter方法

- (AVAudioPlayer *)getAudioPlayer:(NSString *)path witeType:(HCDAudioFileType)type {
    
    __block NSURL *fileUrl;
    
    switch (type) {
            case ZHAudioFileType_Network: {
                dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                dispatch_async(globalQueue, ^{
                    
                    NSURL *url = [[NSURL alloc]initWithString:path];
                    NSData *audioData = [NSData dataWithContentsOfURL:url];
                    
                    NSString *fileName = [path lastPathComponent];
                    
                    //将数据保存在本地指定位置Cache中
                    NSString *filePath = [self getSaveAudioPath: fileName];
                    [audioData writeToFile:filePath atomically:YES];
                    
                    fileUrl = [NSURL fileURLWithPath:filePath];
                    if ([NSThread isMainThread]) {
                        self.audioPlayer = [self getAudioPlayer:fileUrl];
                        [self playAudio];
                    }
                    else {
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            self.audioPlayer = [self getAudioPlayer:fileUrl];
                            [self playAudio];
                        });
                    }
                    
                });
            }
            break;
            case ZHAudioFileType_Local: {
                fileUrl = [NSURL fileURLWithPath:path];
                return [self getAudioPlayer:fileUrl];
            }
            break;
        default: {
            fileUrl = [NSURL fileURLWithPath:path];
            return [self getAudioPlayer:fileUrl];
        }
            break;
    }
    return nil;
}

- (AVAudioPlayer *)getAudioPlayer:(NSURL *)fileUrl
{
    //初始化播放器并播放
    NSError *error;
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileUrl error:&error];
    player.delegate = self;
    [player prepareToPlay];
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(audioPlayerUpdateProgess)];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    if(error){
        NSLog(@"file error %@",error.description);
        //响应播放结束方法
        if ([self.delegate respondsToSelector:@selector(didAudioPlayerFailPlay:)]) {
            [self.delegate didAudioPlayerFailPlay:_audioPlayer];
        }
        return nil;
    }
    return player;
}


#pragma mark - private

- (void)playAudioWithPath:(NSString *)path whiteType:(HCDAudioFileType)type {
    if (path && path.length > 0) {
        //不随着静音键和屏幕关闭而静音
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        //上次播放的录音
        if (_pathName && [path isEqualToString:_pathName]) {
            if (_audioPlayer.isPlaying) {
                //                [self pausePlayingAudio];
                [self playAudio];
            } else {
                [self playAudio];
            }
        } else {
            _pathName = path;
            
            if (_audioPlayer) {
                [_audioPlayer stop];
                _audioPlayer = nil;
            }
            
            //初始化播放器
            self.audioPlayer = [self getAudioPlayer:path witeType:type];
            if (self.audioPlayer != nil) {
                //                self.audioPlayer.volume = 0.4;
                [self playAudio];
            }
        }
    }
}

- (void)playAudio {
    if (_audioPlayer) {
        if (_stopBool == YES) {
            [_audioPlayer stop];
            self.audioPlayer = nil;
        } else {
            [_audioPlayer play];
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            [self configBreakObserver];
            [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
            if ([self.delegate respondsToSelector:@selector(didAudioPlayerBeginPlay:)]) {
                [self.delegate didAudioPlayerBeginPlay:_audioPlayer];
            }
        }
    }
}

//清空歌曲缓存文件夹
- (void) clearAudioDir {
    
    NSString *extension = @"caf";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSString stringWithFormat:@"%@/audio", [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]];
    
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:NULL];
    NSEnumerator *e= [contents objectEnumerator];
    NSString *filename;
    while ((filename = [e nextObject])) {
        if ([[filename pathExtension] isEqualToString:extension]) {
            [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:filename] error:NULL];
        }
    }
}

//  监听打断
-(void)configBreakObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruption:) name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRouteChange:) name:AVAudioSessionRouteChangeNotification object:[AVAudioSession sharedInstance]];
}


//来电打断
- (void) handleInterruption:(NSNotification *) noti
{
    if (noti.name == AVAudioSessionInterruptionNotification) {
        NSDictionary *info = noti.userInfo;
        NSUInteger typenumber = [[info objectForKey:@"AVAudioSessionInterruptionTypeKey"] unsignedIntegerValue];
        AVAudioSessionInterruptionType type = (AVAudioSessionInterruptionType)typenumber;
        switch (type) {
                case AVAudioSessionInterruptionTypeBegan:
            {
                [self stopAudio];
                break;
            }
                case AVAudioSessionInterruptionTypeEnded:
            {
                //                [self playAudio];
                break;
            }
            default:
                break;
        }
    }
}
//拔出耳机等设备变更操作
- (void)handleRouteChange:(NSNotification *)noti {
    if (noti.name == AVAudioSessionRouteChangeNotification) {
        NSDictionary *info = noti.userInfo;
        NSUInteger typenumber = [[info objectForKey:@"AVAudioSessionRouteChangeReasonKey"] unsignedIntegerValue];
        AVAudioSessionRouteChangeReason type = (AVAudioSessionRouteChangeReason)typenumber;
        switch (type) {
                case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"PauseAllPlayingNotification" object:nil];
                break;
            }
            default:
                break;
        }
    }
}


@end
