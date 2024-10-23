//
//  CollectionWaterfallLayout.h
//
//
//  Created by wzy on 2024/10/22.
//  Copyright © 2024 wzy. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CollectionWaterfallLayout;
@class CollectionWaterfallSectionConfig;
@protocol CollectionWaterfallLayoutProtocol <NSObject>

- (CGFloat)collectionViewLayout:(CollectionWaterfallLayout *)layout heightForItemAtIndexPath:(NSIndexPath *)indexPath;

- (CGFloat)collectionViewLayout:(CollectionWaterfallLayout *)layout heightForSupplementaryViewAtIndexPath:(NSIndexPath *)indexPath;

- (CollectionWaterfallSectionConfig *)collectionViewLayout:(CollectionWaterfallLayout *)layout configAtSection:(NSInteger)section;

@end

@interface CollectionWaterfallSectionConfig : NSObject

@property (nonatomic, assign) NSUInteger columns; //列数
@property (nonatomic, assign) CGFloat xSpacing; //x轴间距
@property (nonatomic, assign) CGFloat ySpacing; //y轴间距

+ (CollectionWaterfallSectionConfig *)defaultConfig;

@end

@interface CollectionWaterfallLayout : UICollectionViewLayout

@property (nonatomic, weak) id<CollectionWaterfallLayoutProtocol> delegate;
@property (nonatomic, assign) UIEdgeInsets insets;

- (CGFloat)getWidthInSection:(NSInteger)section;

@end

NS_ASSUME_NONNULL_END
