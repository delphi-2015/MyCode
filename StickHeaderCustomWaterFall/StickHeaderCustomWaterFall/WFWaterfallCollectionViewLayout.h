//
//  WFWaterfallCollectionViewLayout.h
//  StickHeaderCustomWaterFall
//
//  Created by delphiwu on 16/7/4.
//  Copyright © 2016年 delphi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WFWaterfallCollectionViewLayout;

@protocol WFWaterfallCollectionViewLayoutDelegate <NSObject>

@required

-(CGFloat)waterfallLayout:(WFWaterfallCollectionViewLayout *)layout heightFotItemAtIndexPath:(NSIndexPath *)indexPath;

@optional

-(NSInteger)waterfallLayout:(WFWaterfallCollectionViewLayout *)layout columnCountInSection:(NSInteger)section;

-(CGFloat)waterfallLayout:(WFWaterfallCollectionViewLayout *)layout heightFotHeaderAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface WFWaterfallCollectionViewLayout : UICollectionViewLayout

@property (weak, nonatomic) id<WFWaterfallCollectionViewLayoutDelegate> delegate;

@property (assign, nonatomic) CGFloat topInset;
@property (assign, nonatomic) CGFloat bottomInset;
@property (assign, nonatomic) CGFloat columnMargin;
@property (assign, nonatomic) CGFloat headerMarginToTop;

@property (assign, nonatomic) BOOL stickyHeader;

@end
