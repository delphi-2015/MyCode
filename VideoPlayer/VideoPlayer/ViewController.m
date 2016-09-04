//
//  ViewController.m
//  VideoPlayer
//
//  Created by delphiwu on 16/9/2.
//  Copyright © 2016年 delphi. All rights reserved.
//

#import "ViewController.h"
#import "DFPlayer.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet DFPlayer *dfPlayer;
@property (weak, nonatomic) IBOutlet UIImageView *cover;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(playerDidEndPlay) name:DFPlayerFinishedPlayNotificationKey object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)playBtnPressed {
    
    _cover.hidden = YES;
    _playBtn.hidden = YES;
    
    _dfPlayer.status = ^(DFPlayerStatusChangeType type){
        /*
         DFPlayerStatusLoadingType           = 0, //正在加载
         DFPlayerStatusReadyToPlayType       = 1, //开始播放
         DFPlayerStatusrLoadedTimeRangesType = 2  //开始缓存
         */
    };
    [_dfPlayer playWithVideoUrl:@"http://flv2.bn.netease.com/videolib3/1609/02/YJVxD6726/SD/YJVxD6726-mobile.mp4"];
    
}

-(void)playerDidEndPlay {
    _cover.hidden = NO;
    _playBtn.hidden = NO;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
