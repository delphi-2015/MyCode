//
//  DFPlayer.h
//  VideoPlayer
//
//  Created by delphiwu on 16/9/2.
//  Copyright © 2016年 delphi. All rights reserved.
//

#import <UIKit/UIKit.h>

#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height


typedef NS_ENUM(NSInteger, DFPlayerStatusChangeType) {
    DFPlayerStatusLoadingType           = 0, //正在加载
    DFPlayerStatusReadyToPlayType       = 1, //开始播放
    DFPlayerStatusrLoadedTimeRangesType = 2  //开始缓存
};

typedef void (^PlayerStatusChange) (DFPlayerStatusChangeType status);

extern NSString *const DFPlayerFinishedPlayNotificationKey; //播放完成通知

@interface DFPlayer : UIView

@property (strong, nonatomic)PlayerStatusChange status;

- (void)playWithVideoUrl:(NSString *)videoUrl;

@end

