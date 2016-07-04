//
//  WFWaterfallCollectionViewLayout.m
//  StickHeaderCustomWaterFall
//
//  Created by delphiwu on 16/7/4.
//  Copyright © 2016年 delphi. All rights reserved.
//

#import "WFWaterfallCollectionViewLayout.h"

NSString* const WFwaterfallLayoutCellKind = @"WaterfallCell";
static const NSInteger WFDefaultColumnCount = 2;

@interface WFWaterfallCollectionViewLayout ()

@property (strong, nonatomic) NSMutableArray *columnsCountInSections;

@property (nonatomic) NSDictionary *layoutInfo;
@property (nonatomic) NSArray *sectionsHeights;
@property (nonatomic) NSArray *itemsInSectionsHeights;

@end

@implementation WFWaterfallCollectionViewLayout

#pragma mark - Lifecycle

- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _topInset = 6.0f;
    _bottomInset = 6.0f;
    _headerMarginToTop = 0;
    _columnMargin = 6.0f;
    _stickyHeader = YES;
}

- (void)prepareLayout {
    if (self.collectionView.isDecelerating || self.collectionView.isDragging) {
        
    } else {
        [self calculateMaxColumnsCount];
        [self calculateItemsHeights];
        [self calculateSectionsHeights];
        [self calculateItemsAttributes];
    }
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *allAttributes = [NSMutableArray arrayWithCapacity:self.layoutInfo.count];
    
    [self.layoutInfo enumerateKeysAndObjectsUsingBlock:^(NSString *elementIdentifier,
                                                         NSDictionary *elementsInfo,
                                                         BOOL *stop) {
        [elementsInfo enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath,
                                                          UICollectionViewLayoutAttributes *attributes,
                                                          BOOL *innerStop) {
            if (CGRectIntersectsRect(rect, attributes.frame) || [elementIdentifier isEqualToString:UICollectionElementKindSectionHeader]) {
                [allAttributes addObject:attributes];
            }
        }];
    }];
    
    if(!self.stickyHeader) {
        return allAttributes;
    }
    
    for (UICollectionViewLayoutAttributes *layoutAttributes in allAttributes) {
        if ([layoutAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader]) {
            NSInteger section = layoutAttributes.indexPath.section;
            NSIndexPath *firstCellIndexPath = [NSIndexPath indexPathForItem:0 inSection:section];
            UICollectionViewLayoutAttributes *firstCellAttrs = [self layoutAttributesForItemAtIndexPath:firstCellIndexPath];
            
            CGFloat headerHeight = CGRectGetHeight(layoutAttributes.frame) + _topInset;
            CGFloat currentHeaderHeight = [self headerHeightForIndexPath:firstCellIndexPath];
            CGPoint origin = layoutAttributes.frame.origin;
            origin.y = MIN(
                           MAX(self.collectionView.contentOffset.y, (CGRectGetMinY(firstCellAttrs.frame) - headerHeight) - _headerMarginToTop),
                           CGRectGetMinY(firstCellAttrs.frame) - headerHeight + [[self.sectionsHeights objectAtIndex:section] floatValue] - currentHeaderHeight - _headerMarginToTop
                           ) + _headerMarginToTop;
            
            layoutAttributes.zIndex = 11;
            layoutAttributes.frame = (CGRect){
                .origin = origin,
                .size = CGSizeMake(layoutAttributes.frame.size.width, layoutAttributes.frame.size.height)
            };
        }
    }
    
    return allAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.layoutInfo[WFwaterfallLayoutCellKind][indexPath];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind
                                                                     atIndexPath:(NSIndexPath *)indexPath {
    return self.layoutInfo[UICollectionElementKindSectionHeader][indexPath];
}

- (CGSize)collectionViewContentSize {
    CGFloat height = self.topInset;
    for (NSNumber *h in self.sectionsHeights) {
        height += [h integerValue];
    }
    height += self.bottomInset;
    
    return CGSizeMake(self.collectionView.bounds.size.width, height);
}

#pragma mark - Prepare layout calculation

- (void) calculateMaxColumnsCount {
    _columnsCountInSections = [NSMutableArray new];
    NSInteger sections = self.collectionView.numberOfSections;
    for (int section = 0; section < sections; section++) {
        if ([self.delegate respondsToSelector:@selector(waterfallLayout:columnCountInSection:)]) {
            [_columnsCountInSections addObject:[NSNumber numberWithInteger:[self.delegate waterfallLayout:self columnCountInSection:section]]];
        }else {
            [_columnsCountInSections addObject:[NSNumber numberWithInteger:WFDefaultColumnCount]];
        }
    }
}

- (void) calculateItemsHeights {
    NSMutableArray *itemsInSectionsHeights = [NSMutableArray arrayWithCapacity:self.collectionView.numberOfSections];
    NSIndexPath *itemIndex;
    for (NSInteger section = 0; section < self.collectionView.numberOfSections; section++) {
        NSMutableArray *itemsHeights = [NSMutableArray arrayWithCapacity:[self.collectionView numberOfItemsInSection:section]];
        for (NSInteger item = 0; item < [self.collectionView numberOfItemsInSection:section]; item++) {
            itemIndex = [NSIndexPath indexPathForItem:item inSection:section];
            CGFloat itemHeight = [self.delegate waterfallLayout:self heightFotItemAtIndexPath:itemIndex];
            [itemsHeights addObject:[NSNumber numberWithFloat:itemHeight]];
        }
        [itemsInSectionsHeights addObject:itemsHeights];
    }
    
    self.itemsInSectionsHeights = itemsInSectionsHeights;
}

- (void) calculateSectionsHeights {
    NSMutableArray *newSectionsHeights = [NSMutableArray array];
    NSInteger sectionCount = [self.collectionView numberOfSections];
    for (NSInteger section = 0; section < sectionCount; section++) {
        [newSectionsHeights addObject:[self calculateHeightForSection:section]];
    }
    self.sectionsHeights = [NSArray arrayWithArray:newSectionsHeights];
}

- (NSNumber*) calculateHeightForSection: (NSInteger)section {
    NSInteger columnsCount = [_columnsCountInSections[section] integerValue];
    NSInteger sectionColumns[columnsCount];
    NSIndexPath* indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
    for (NSInteger column = 0; column < columnsCount; column++) {
        sectionColumns[column] = [self headerHeightForIndexPath:indexPath]
        + _topInset;
    }
    
    NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
    for (NSInteger item = 0; item < itemCount; item++) {
        indexPath = [NSIndexPath indexPathForItem:item inSection:section];
        
        NSInteger currentColumn = 0;
        for (NSInteger column = 0; column < columnsCount; column++) {
            if(sectionColumns[currentColumn] > sectionColumns[column]) {
                currentColumn = column;
            }
        }
        
        sectionColumns[currentColumn] += [[[self.itemsInSectionsHeights objectAtIndex:section]
                                           objectAtIndex:indexPath.item] floatValue];
        sectionColumns[currentColumn] += _topInset;
    }
    
    NSInteger biggestColumn = 0;
    for (NSInteger column = 0; column < columnsCount; column++) {
        if(sectionColumns[biggestColumn] < sectionColumns[column]) {
            biggestColumn = column;
        }
    }
    
    return [NSNumber numberWithFloat: sectionColumns[biggestColumn]];
}

- (void) calculateItemsAttributes {
    NSMutableDictionary *newLayoutInfo = [NSMutableDictionary dictionary];
    NSMutableDictionary *cellLayoutInfo = [NSMutableDictionary dictionary];
    NSMutableDictionary *titleLayoutInfo = [NSMutableDictionary dictionary];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    
    for (NSInteger section = 0; section < [self.collectionView numberOfSections]; section++) {
        for (NSInteger item = 0; item < [self.collectionView numberOfItemsInSection:section]; item++) {
            indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            
            UICollectionViewLayoutAttributes *itemAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            itemAttributes.frame = [self frameForWaterfallCellIndexPath:indexPath];
            cellLayoutInfo[indexPath] = itemAttributes;
            
            //Only one header in section, so we get only item at 0 position
            if (indexPath.item == 0) {
                UICollectionViewLayoutAttributes *titleAttributes = [UICollectionViewLayoutAttributes
                                                                     layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                     withIndexPath:indexPath];
                titleAttributes.frame = [self frameForWaterfallHeaderAtIndexPath:indexPath];
                titleLayoutInfo[indexPath] = titleAttributes;
            }
        }
    }
    
    newLayoutInfo[WFwaterfallLayoutCellKind] = cellLayoutInfo;
    newLayoutInfo[UICollectionElementKindSectionHeader] = titleLayoutInfo;
    
    self.layoutInfo = newLayoutInfo;
    
}

#pragma mark - Items frames

- (CGRect)frameForWaterfallCellIndexPath:(NSIndexPath *)indexPath {
    NSInteger columnsCount = [_columnsCountInSections[indexPath.section] integerValue];
    CGFloat width = (self.collectionView.frame.size.width - _columnMargin * (columnsCount+1))/columnsCount;
    
    CGFloat height = [[[self.itemsInSectionsHeights objectAtIndex:indexPath.section]
                       objectAtIndex:indexPath.item] floatValue];
    
    CGFloat topInset = self.topInset;
    for (NSInteger section = 0; section < indexPath.section; section++) {
        topInset += [[self.sectionsHeights objectAtIndex:section] integerValue];
    }
    
    NSInteger columnsHeights[columnsCount];
    for (NSInteger column = 0; column < columnsCount; column++) {
        columnsHeights[column] = [self headerHeightForIndexPath:indexPath] + _topInset;
    }
    
    for (NSInteger item = 0; item < indexPath.item; item++) {
        NSIndexPath *ip = [NSIndexPath indexPathForItem:item inSection:indexPath.section];
        NSInteger currentColumn = 0;
        for(NSInteger column = 0; column < columnsCount; column++) {
            if(columnsHeights[currentColumn] > columnsHeights[column]) {
                currentColumn = column;
            }
        }
        
        columnsHeights[currentColumn] += [[[self.itemsInSectionsHeights objectAtIndex:ip.section]
                                           objectAtIndex:ip.item] floatValue];
        columnsHeights[currentColumn] += _topInset;
    }
    
    NSInteger columnForCurrentItem = 0;
    for (NSInteger column = 0; column < columnsCount; column++) {
        if(columnsHeights[columnForCurrentItem] > columnsHeights[column]) {
            columnForCurrentItem = column;
        }
    }
    
    CGFloat originX = _topInset +
    columnForCurrentItem * width +
    columnForCurrentItem * _topInset;
    CGFloat originY =  columnsHeights[columnForCurrentItem] + topInset;
    
    return CGRectMake(originX, originY, width, height);
    
}

- (CGRect)frameForWaterfallHeaderAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = self.collectionView.bounds.size.width -
    _topInset * 2;
    CGFloat height = [self headerHeightForIndexPath:indexPath];
    
    CGFloat originY = self.topInset;
    for (NSInteger i = 0; i < indexPath.section; i++) {
        originY += [[self.sectionsHeights objectAtIndex:i] floatValue];
    }
    
    CGFloat originX = _topInset;
    return CGRectMake(originX, originY, width, height);
}

- (CGFloat) headerHeightForIndexPath:(NSIndexPath*)indexPath {
    if ([self.delegate respondsToSelector:@selector(waterfallLayout:heightFotHeaderAtIndexPath:)]) {
        return [self.delegate waterfallLayout:self heightFotHeaderAtIndexPath:indexPath];
    }
    return 0;
}

@end
