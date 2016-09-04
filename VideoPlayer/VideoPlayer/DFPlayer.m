//
//  DFPlayer.m
//  VideoPlayer
//
//  Created by delphiwu on 16/9/2.
//  Copyright © 2016年 delphi. All rights reserved.
//

#import "DFPlayer.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

static void *PlayViewStatusObservationContext = &PlayViewStatusObservationContext;

@interface DFPlayer ()
//播放器
@property(nonatomic, strong)AVPlayer *player;
@property(nonatomic, strong)AVPlayerLayer *playerLayer;
/* playItem */
@property(nonatomic, strong)AVPlayerItem *playerItem;
@property(nonatomic, strong)NSDateFormatter *dateFormatter;
@property(nonatomic, strong)NSTimer *handleBackTime;
@property(nonatomic, assign)BOOL isTouchDownProgress;
@property(nonatomic, assign)BOOL isBufferToPlay;

//背景及相关操控元素
@property(nonatomic, strong)UIView *backView;
@property(nonatomic, strong)UIView *bottomView;
@property(nonatomic, strong)UISlider *progressSlider;
@property(nonatomic, strong)UILabel *rightTimeLabel;
@property(nonatomic, strong)UILabel *leftTimeLabel;
@property(nonatomic, strong)UIButton *playOrPauseBtn;

@property(nonatomic, strong)UIImageView *loadingView;
@property(nonatomic, strong)CABasicAnimation *loadingAnim;

@end

@implementation DFPlayer

NSString *const DFPlayerFinishedPlayNotificationKey  = @"DFPlayerFinishedPlayNotificationKey";

#pragma mark - system Life

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

-(void)setup {
    [self addSubview:self.backView];
    [_backView addSubview:self.bottomView];
    [_backView addSubview:self.playOrPauseBtn];
    [self addSubview:self.loadingView];
    
    [self addConstraints];
    
    //单击显示或者隐藏工具栏
    UITapGestureRecognizer* singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap)];
    singleTap.numberOfTapsRequired = 1;
    [self addGestureRecognizer:singleTap];
}

-(void)dealloc{
    [_player.currentItem cancelPendingSeeks];
    [_player.currentItem.asset cancelLoading];
    [_player pause];
    
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    
    [_playerItem removeObserver:self forKeyPath:@"status"];
    [_playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [_playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [_playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];

    if(_handleBackTime) [_handleBackTime invalidate];
}

#pragma mark - public

-(void)playWithVideoUrl:(NSString *)videoUrl {
    if (_playerItem) {
        [self.player play];
         _playOrPauseBtn.selected = NO;
        return;
    }
    
    [self startAnimationLoadingView];
    _playerItem = [self getPlayItemWithURLString:videoUrl];
    [self addObserverFromPlayerItem:_playerItem];
    [self.player replaceCurrentItemWithPlayerItem:_playerItem];
    
    if (_player.rate != 1.f) {
        if ([self currentTime] == CMTimeGetSeconds([[_playerItem asset] duration])) [self setCurrentTime:0.f];
        [self.player play];
        _playOrPauseBtn.selected = NO;
    }
}

#pragma mark - private

-(AVPlayerItem *)getPlayItemWithURLString:(NSString *)urlString{
    if ([urlString containsString:@"http"]) {
        AVPlayerItem *playerItem=[AVPlayerItem playerItemWithURL:[NSURL URLWithString:urlString]];
        return playerItem;
    }else{
        AVAsset *movieAsset  = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:urlString] options:nil];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
        return playerItem;
    }
}

-(void)addObserverFromPlayerItem:(AVPlayerItem *)playerItem{
    //监听播放状态的变化
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:PlayViewStatusObservationContext];
    //监控网络加载情况属性
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
    //监听 buffer 状态
    [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    //播放结束通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
    //转屏通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(deviceOrientationDidChanged) name:UIDeviceOrientationDidChangeNotification object:nil];
}

-(void)playerStatusChanged:(DFPlayerStatusChangeType)status {
    if (self.status) self.status(status);
    
    if (status == DFPlayerStatusReadyToPlayType) {
        [self stopAnimation];
    }else if (status == DFPlayerStatusLoadingType) {
        [self startAnimationLoadingView];
    }
}

-(void)removeHandleBackTime {
    if (self.handleBackTime) {
        [self.handleBackTime invalidate];
        self.handleBackTime = nil;
    }
}

-(double)currentTime{
    return CMTimeGetSeconds([_player currentTime]);
}

-(void)setCurrentTime:(double)time{
    [_player seekToTime:CMTimeMakeWithSeconds(time, 1)];
}

-(void)initTimer{
    __weak __typeof(self) weakSelf = self;
    double interval = .1f;
    CMTime playerDuration = _playerItem.duration;
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        CGFloat width = CGRectGetWidth([self.progressSlider bounds]);
        interval = 0.5f * duration / width;
    }
    //定时循环执行。
    [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        [weakSelf syncScrubber];
    }];
}

- (void)syncScrubber{
    
    CMTime playerDuration = _playerItem.duration;
    if (CMTIME_IS_INVALID(playerDuration)){
        self.progressSlider.minimumValue = 0.0; //设置进度为0
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)){
        float minValue = [self.progressSlider minimumValue];
        float maxValue = [self.progressSlider maximumValue];
        double time = CMTimeGetSeconds([self.player currentTime]);
        
        _leftTimeLabel.text = [self convertTime:time];
        _rightTimeLabel.text =  [self convertTime:duration];
        
        float value = (maxValue - minValue) * time / duration + minValue;
        if (!_isTouchDownProgress) {
            [self.progressSlider setValue:value];
        }
    }
}

//转换时间
- (NSString *)convertTime:(CGFloat)second{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    if (second/3600 >= 1) {
        [[self dateFormatter] setDateFormat:@"HH:mm:ss"];
        [self dateFormatter].timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    } else {
        [[self dateFormatter] setDateFormat:@"mm:ss"];
    }
    NSString *newTime = [[self dateFormatter] stringFromDate:d];
    return newTime;
}

#pragma mark - loadingAnimation
- (void)stopAnimation {
    _loadingView.hidden = YES;
    
    [_loadingView.layer removeAllAnimations];
    _loadingAnim = nil;
}

-(void)startAnimationLoadingView {
    _loadingView.hidden = NO;
    
    _loadingAnim = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    _loadingAnim.removedOnCompletion = NO;
    _loadingAnim.delegate = self;
    _loadingAnim.fillMode = kCAFillModeBoth;
    _loadingAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    _loadingAnim.speed = 1;
    _loadingAnim.duration = 1.5f;
    _loadingAnim.fromValue = [NSNumber numberWithDouble:0.0];
    _loadingAnim.toValue = [NSNumber numberWithDouble:2 * M_PI];
    _loadingAnim.repeatCount = HUGE_VALF;
    
    [self.loadingView.layer addAnimation:_loadingAnim forKey:@"transform.rotation"];
}

#pragma mark - observer 

-(void)deviceOrientationDidChanged {
    _playerLayer.frame = self.layer.bounds;
}

- (void)moviePlayDidEnd:(NSNotification *)notification {
    __weak __typeof(self) weakSelf = self;
    [self.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        
        [weakSelf.progressSlider setValue:0.0 animated:YES];
        weakSelf.playOrPauseBtn.selected = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:DFPlayerFinishedPlayNotificationKey object:nil];
    }];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    
    AVPlayerItem *playerItem=object;
    
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status= [[change objectForKey:@"new"] intValue];
        if(status==AVPlayerStatusReadyToPlay){
            if (CMTimeGetSeconds(_playerItem.duration)) {
                self.progressSlider.maximumValue = CMTimeGetSeconds(_playerItem.duration);
            }
            [self initTimer];
            [self playerStatusChanged:DFPlayerStatusReadyToPlayType];
        }
    }else if([keyPath isEqualToString:@"loadedTimeRanges"]){
        if (self.alpha == 0.00) {
            [self playerStatusChanged:DFPlayerStatusrLoadedTimeRangesType];
            [UIView animateWithDuration:0.5 animations:^{
                self.alpha = 1.0;
            }];
        }
    }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]){
        if (playerItem.playbackBufferEmpty) {
            if (!_isBufferToPlay) {
                [self PlayOrPauseBtnPressed:_playOrPauseBtn];
                [self playerStatusChanged:DFPlayerStatusLoadingType];
                _isBufferToPlay = YES;
            }
        }
    }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]){
        if (playerItem.playbackLikelyToKeepUp) {
            if (_isBufferToPlay) {
                [self playerStatusChanged:DFPlayerStatusReadyToPlayType];
                [self PlayOrPauseBtnPressed:_playOrPauseBtn];
                _isBufferToPlay = NO;
            }
        }
    }
}

#pragma mark - Action selector

-(void)PlayOrPauseBtnPressed:(UIButton *)btn {
    btn.selected = !btn.selected;
    if (self.player.rate != 1.f) {
        if ([self currentTime] == CMTimeGetSeconds([[_playerItem asset] duration]))
            [self setCurrentTime:0.f];
        [self.player play];
    } else {
        [self.player pause];
    }
}

-(void)TouchBeganProgress:(UISlider *)slider {
    [self removeHandleBackTime];
}

-(void)changeProgress:(UISlider *)slider {
    _isTouchDownProgress = YES;
}

-(void)TouchEndProgress:(UISlider *)slider {
    [_player seekToTime:CMTimeMakeWithSeconds(slider.value, 1)];
    _isTouchDownProgress = NO;
    [UIView animateWithDuration:0.5 animations:^{
        _backView.alpha = 0.0;
    }];
}

- (void)handleSingleTap{
    [UIView animateWithDuration:0.5 animations:^{
        if (self.backView.alpha == 0.0) {
            self.backView.alpha = 1.0;
        }else{
            self.backView.alpha = 0.0;
        }
        
    } completion:^(BOOL finished) {
        // 显示之后，3.5秒钟隐藏
        if (self.backView.alpha == 1.0) {
            [self removeHandleBackTime];
            self.handleBackTime = [NSTimer timerWithTimeInterval:3.5 target:self selector:@selector(handleSingleTap) userInfo:nil repeats:NO];
            [[NSRunLoop mainRunLoop] addTimer:self.handleBackTime forMode:NSDefaultRunLoopMode];
        }else{
            [self.handleBackTime invalidate];
            self.handleBackTime = nil;
        }
    }];
}

#pragma mark - Constraints

-(void)addConstraints {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_backView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_backView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_backView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_backView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_backView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:_bottomView attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_backView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:_bottomView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_backView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_bottomView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [_bottomView addConstraint:[NSLayoutConstraint constraintWithItem:_bottomView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:40]];
    
    [_leftTimeLabel addConstraint:[NSLayoutConstraint constraintWithItem:_leftTimeLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:60]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_leftTimeLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:_bottomView attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_leftTimeLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_bottomView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_leftTimeLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_bottomView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    
    [_rightTimeLabel addConstraint:[NSLayoutConstraint constraintWithItem:_rightTimeLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:60]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_rightTimeLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:_bottomView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_rightTimeLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_bottomView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_rightTimeLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_bottomView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_progressSlider attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:_leftTimeLabel attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_progressSlider attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:_rightTimeLabel attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_progressSlider attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_bottomView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_progressSlider attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_bottomView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    
    [_playOrPauseBtn addConstraint:[NSLayoutConstraint constraintWithItem:_playOrPauseBtn attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:64]];
    [_playOrPauseBtn addConstraint:[NSLayoutConstraint constraintWithItem:_playOrPauseBtn attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:64]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_playOrPauseBtn attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_backView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_playOrPauseBtn attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_backView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
    [_loadingView addConstraint:[NSLayoutConstraint constraintWithItem:_loadingView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:64]];
    [_loadingView addConstraint:[NSLayoutConstraint constraintWithItem:_loadingView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:64]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_loadingView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_loadingView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
}

#pragma mark - getter

-(AVPlayer *)player {
    if (_player) return _player;
    
    _player = [AVPlayer playerWithPlayerItem:_playerItem];
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _playerLayer.frame = self.layer.bounds;
    [self.layer insertSublayer:_playerLayer below:_backView.layer];
    
    return _player;
}

-(UIView *)backView {
    if (_backView) return _backView;
    
    _backView = [UIView new];
    _backView.alpha = 0;
    _backView.translatesAutoresizingMaskIntoConstraints = NO;
    
    return _backView;
}

-(UIView *)bottomView {
    if (_bottomView) return _bottomView;
    
    _bottomView = [[UIView alloc]initWithFrame:CGRectZero];
    _bottomView.backgroundColor = [[UIColor alloc]initWithRed:0 green:0 blue:0 alpha:0.4];
    _bottomView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_bottomView addSubview:self.leftTimeLabel];
    [_bottomView addSubview:self.progressSlider];
    [_bottomView addSubview:self.rightTimeLabel];
    
    return _bottomView;
}

-(UILabel *)leftTimeLabel {
    if (_leftTimeLabel) return  _leftTimeLabel;
    
    _leftTimeLabel = [[UILabel alloc]initWithFrame:CGRectZero];
    _leftTimeLabel.textAlignment = NSTextAlignmentCenter;
    _leftTimeLabel.textColor = [UIColor whiteColor];
    _leftTimeLabel.backgroundColor = [UIColor clearColor];
    _leftTimeLabel.font = [UIFont systemFontOfSize:11];
    _leftTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    return _leftTimeLabel;
}

-(UISlider *)progressSlider {
    if (_progressSlider) return _progressSlider;
        
    _progressSlider = [[UISlider alloc]init];
    _progressSlider.minimumValue = 0.0;
    [_progressSlider setThumbImage:[UIImage imageNamed:@"dot"] forState:UIControlStateNormal];
    _progressSlider.minimumTrackTintColor = [UIColor redColor];
    _progressSlider.value = 0.0;
    _progressSlider.translatesAutoresizingMaskIntoConstraints = NO;
    [_progressSlider addTarget:self action:@selector(TouchBeganProgress:) forControlEvents:UIControlEventTouchDown];
    [_progressSlider addTarget:self action:@selector(changeProgress:) forControlEvents:UIControlEventValueChanged];
    [_progressSlider addTarget:self action:@selector(TouchEndProgress:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
    
    return _progressSlider;
}

-(UILabel *)rightTimeLabel {
    if (_rightTimeLabel) return _rightTimeLabel;
    
    _rightTimeLabel = [[UILabel alloc]initWithFrame:CGRectZero];
    _rightTimeLabel.textAlignment = NSTextAlignmentCenter;
    _rightTimeLabel.textColor = [UIColor whiteColor];
    _rightTimeLabel.backgroundColor = [UIColor clearColor];
    _rightTimeLabel.font = [UIFont systemFontOfSize:11];
    _rightTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    return _rightTimeLabel;
}

-(UIButton *)playOrPauseBtn {
    if (_playOrPauseBtn) return _playOrPauseBtn;

    _playOrPauseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _playOrPauseBtn.showsTouchWhenHighlighted = YES;
    _playOrPauseBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [_playOrPauseBtn addTarget:self action:@selector(PlayOrPauseBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_playOrPauseBtn setImage:[UIImage imageNamed:@"video_pause_btn_bg"] forState:UIControlStateNormal];
    [_playOrPauseBtn setImage:[UIImage imageNamed:@"video_play_btn_bg"] forState:UIControlStateSelected];

    return _playOrPauseBtn;
}

-(NSDateFormatter *)dateFormatter {
    if (_dateFormatter) return _dateFormatter;
    
    _dateFormatter = [[NSDateFormatter alloc] init];

    return _dateFormatter;
}

-(UIImageView *)loadingView {
    if (_loadingView) return  _loadingView;
    
    _loadingView = [UIImageView new];
    _loadingView.translatesAutoresizingMaskIntoConstraints = NO;
    _loadingView.image = [UIImage imageNamed:@"loading_view"];
    _loadingView.hidden = YES;

    return _loadingView;
}

@end

