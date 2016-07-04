//
//  ViewController.m
//  StickHeaderCustomWaterFall
//
//  Created by delphiwu on 16/7/4.
//  Copyright © 2016年 delphi. All rights reserved.
//

#import "ViewController.h"
#import "WFWaterfallCollectionViewLayout.h"
#import "WFCollectionViewCell.h"
#import "WFCollectionHeaderReusableView.h"

static NSString* const CollectionViewCellID = @"WFCollectionViewCell";
static NSString* const CollectionHeaderReusableViewID = @"WFCollectionHeaderReusableView";

@interface ViewController ()<WFWaterfallCollectionViewLayoutDelegate,UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (strong, nonatomic) NSMutableArray *itemHeights;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    WFWaterfallCollectionViewLayout *layout = [[WFWaterfallCollectionViewLayout alloc]init];
    layout.delegate = self;
    layout.stickyHeader = YES; // default is YES
    
    _collectionView.collectionViewLayout = layout;
    [_collectionView reloadData];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 6;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 11;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFCollectionViewCell *waterfallCell = [collectionView dequeueReusableCellWithReuseIdentifier:CollectionViewCellID
                                                                                              forIndexPath:indexPath];
    waterfallCell.label.text = [NSString stringWithFormat: @"Item %ld", (long)indexPath.item];
    return waterfallCell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath; {
    WFCollectionHeaderReusableView *titleView =
    [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                       withReuseIdentifier:CollectionHeaderReusableViewID
                                              forIndexPath:indexPath];
    titleView.titleLabel.text = [NSString stringWithFormat: @"Section %ld", (long)indexPath.section];
    return titleView;
}

#pragma mark - WFWaterfallCollectionViewLayoutDelegate

-(CGFloat)waterfallLayout:(WFWaterfallCollectionViewLayout *)layout heightFotItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.itemHeights[indexPath.section + 1 * indexPath.item] floatValue];
}

-(CGFloat)waterfallLayout:(WFWaterfallCollectionViewLayout *)layout heightFotHeaderAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section + 1) * 15.0f;
}

-(NSInteger)waterfallLayout:(WFWaterfallCollectionViewLayout *)layout columnCountInSection:(NSInteger)section {
    return section+1;
}

#pragma mark - getter

- (NSMutableArray *)itemHeights {
    if (!_itemHeights) {
        _itemHeights = [NSMutableArray arrayWithCapacity:900];
        for (NSInteger i = 0; i < 66; i++) {
            _itemHeights[i] = @(arc4random()%100*2+100);
        }
    }
    return _itemHeights;
}

@end
