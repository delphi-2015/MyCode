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
/**
 *  每个item的高度
 *
 *  @param layout    WFWaterfallCollectionViewLayout
 *  @param indexPath NSIndexPath
 *
 *  @return CGFloat item高度
 */
-(CGFloat)waterfallLayout:(WFWaterfallCollectionViewLayout *)layout heightFotItemAtIndexPath:(NSIndexPath *)indexPath;

@optional

/**
 *  每个section的item列数
 *
 *  @param layout  WFWaterfallCollectionViewLayout
 *  @param section section
 *
 *  @return NSInteger 列数
 */
-(NSInteger)waterfallLayout:(WFWaterfallCollectionViewLayout *)layout columnCountInSection:(NSInteger)section;
/**
 *  每个section的header高度
 *
 *  @param layout    WFWaterfallCollectionViewLayout
 *  @param indexPath NSIndexPath
 *
 *  @return CGFloat header高度
 */
-(CGFloat)waterfallLayout:(WFWaterfallCollectionViewLayout *)layout heightFotHeaderAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface WFWaterfallCollectionViewLayout : UICollectionViewLayout

@property (weak, nonatomic) id<WFWaterfallCollectionViewLayoutDelegate> delegate;

@property (assign, nonatomic) CGFloat topInset;
@property (assign, nonatomic) CGFloat bottomInset;
@property (assign, nonatomic) CGFloat columnMargin;
@property (assign, nonatomic) CGFloat headerMarginToTop;

//是否悬停section header
@property (assign, nonatomic) BOOL stickyHeader;

@end
