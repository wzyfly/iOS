//
//  CollectionWaterfallLayout.m
//
//
//  Created by wzy on 2024/10/22.
//  Copyright © 2024 wzy. All rights reserved.
//

#import "CollectionWaterfallLayout.h"


@implementation CollectionWaterfallSectionConfig

+ (CollectionWaterfallSectionConfig *)defaultConfig {
    CollectionWaterfallSectionConfig *config = [[CollectionWaterfallSectionConfig alloc] init];
    config.columns = 1;
    config.xSpacing = 10;
    config.ySpacing = 10;
    return config;
}

@end

#pragma mark -

@interface CollectionWaterfallLayout ()

@property (nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> *attributesArray; // 保存所有Item的LayoutAttributes
@property (nonatomic, strong) NSMutableArray<NSMutableArray *> *columnHeights; // 保存所有列的当前高度
@property (nonatomic, strong) NSMutableArray<NSIndexPath *> *indexPaths;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, CollectionWaterfallSectionConfig *> *sectionConfigs;

@property (nonatomic, assign) CGFloat maxY;

@end

@implementation CollectionWaterfallLayout

- (instancetype)init {
    if (self = [super init]) {
        _insets = UIEdgeInsetsZero;
    }
    return self;
}

- (CollectionWaterfallSectionConfig *)getConfigAtSection:(NSInteger) section {
    if (_sectionConfigs[@(section)]) {
        return _sectionConfigs[@(section)];
    }
    CollectionWaterfallSectionConfig *config = [CollectionWaterfallSectionConfig defaultConfig];
    if (_delegate && [_delegate respondsToSelector:@selector(collectionViewLayout:configAtSection:)]) {
        config = [_delegate collectionViewLayout:self configAtSection:section];
    }
    _sectionConfigs[@(section)] = config;
    return config;
}

- (CGFloat)getWidthInSection:(NSInteger)section {
    CollectionWaterfallSectionConfig *config = [self getConfigAtSection:section];
    CGFloat width = (self.collectionView.frame.size.width - (_insets.left + _insets.right) - config.xSpacing * (config.columns - 1)) / config.columns;
    return width;
}

#pragma mark - UICollectionViewLayout

/**
 *  collectionView初次显示或者调用invalidateLayout方法后会调用此方法
 */
- (void)prepareLayout {
    [super prepareLayout];
    
    //初始化数组
    self.columnHeights = [NSMutableArray array];
    self.sectionConfigs = [NSMutableDictionary dictionary];
    _maxY = 0;
    
    self.indexPaths = [NSMutableArray array];
    self.attributesArray = [NSMutableArray array];
    NSInteger numSections = [self.collectionView numberOfSections];
    for (NSInteger section = 0; section < numSections; section++) {
        CollectionWaterfallSectionConfig *config = [self getConfigAtSection:section];
        NSMutableArray *heights = [NSMutableArray array];
        for (NSInteger i = 0; i < config.columns; i++) {
            [heights addObject:@(-1)];
        }
        [_columnHeights addObject:heights];
        
        // header
        NSIndexPath *pathOfSection = [NSIndexPath indexPathForRow:0 inSection:section];
        UICollectionViewLayoutAttributes *headerLayout = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:pathOfSection];
        if (headerLayout) {
            [self.attributesArray addObject:headerLayout];
        }
        
        NSInteger numItems = [self.collectionView numberOfItemsInSection:section];
        for (NSInteger item = 0; item < numItems; item++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            // 计算LayoutAttributes
            UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
            
            [self.attributesArray addObject:attributes];
        }
    }
}

/**
 *  计算需要返回所有内容的滚动长度
 */
- (CGSize)collectionViewContentSize {
    return CGSizeMake(self.collectionView.bounds.size.width, _maxY + _insets.top + _insets.bottom);
}

/**
 *  当CollectionView开始刷新后，会调用此方法并传递rect参数（即当前可视区域）
 */
- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *showLayoutAttributes = [NSMutableArray array];
    for (UICollectionViewLayoutAttributes *layoutAttri in self.attributesArray) {
        if (CGRectIntersectsRect(rect, layoutAttri.frame)) {
            [showLayoutAttributes addObject:layoutAttri];
        }
    }
    if (showLayoutAttributes.count > 0) {
        return showLayoutAttributes;
    }
    return self.attributesArray;
}

#pragma mark - 计算单个indexPath的LayoutAttributes
/**
 *  根据indexPath，计算对应的LayoutAttributes
 */
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    if (![self.indexPaths containsObject:indexPath]) {
        [self.indexPaths addObject:indexPath];
        //外部返回Item高度
        CGFloat height = [self.delegate collectionViewLayout:self heightForItemAtIndexPath:indexPath];

        CollectionWaterfallSectionConfig *config = [self getConfigAtSection:indexPath.section];
        CGFloat width = [self getWidthInSection:indexPath.section];
        
        //找出所有列中高度最小的
        NSInteger columnIndex = [self columnOfLessHeight:indexPath.section];
        CGFloat lessHeight = [self getColumnHeight:columnIndex inSection:indexPath.section];
        
        //计算LayoutAttributes
        CGFloat x = _insets.left + (width + config.xSpacing) * columnIndex;
        CGFloat y = (lessHeight == 0) ? _insets.top : (lessHeight + config.ySpacing);
        attributes.frame = CGRectMake(x, y, width, height);
        
        // 更新列高度
        [self setColumnHeight:columnIndex inSection:indexPath.section height:(y + height)];
    }
    return attributes;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    if (CGRectGetWidth(newBounds) != CGRectGetWidth(self.collectionView.bounds)) {
        return YES;
    }
    return NO;
}

/**
 *  根据kind、indexPath，计算对应的LayoutAttributes
 */
- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:elementKind withIndexPath:indexPath];
    
    NSInteger mostColumn = [self columnOfMostHeight:indexPath.section];
    CGFloat maxY = [self getColumnHeight:mostColumn inSection:indexPath.section];
    
    //计算LayoutAttributes
    if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]){
        CGFloat width = self.collectionView.bounds.size.width - _insets.left - _insets.right;
        CGFloat height = [self.delegate collectionViewLayout:self heightForSupplementaryViewAtIndexPath:indexPath];
        CGFloat x = _insets.left;
        CGFloat y = maxY;
        if (indexPath.section == 0) {
            y += _insets.top;
        } else {
            CollectionWaterfallSectionConfig *config = [self getConfigAtSection:indexPath.section - 1];
            y += config.ySpacing;
        }
        attributes.frame = CGRectMake(x, y, width, height);
        attributes.zIndex = 1024;
        
        CollectionWaterfallSectionConfig *config = [self getConfigAtSection:indexPath.section];
        for (NSInteger column = 0; column < config.columns; column++) {
            [self setColumnHeight:column inSection:indexPath.section height:(y + height)];
        }
    }
    return attributes;
}


#pragma mark -
/**
 *  找到高度最小的那一列的下标
 */
- (NSInteger)columnOfLessHeight:(NSInteger)section {
    if (section >= self.columnHeights.count) {
        return 0;
    }
    NSMutableArray *heights = self.columnHeights[section];
    if (heights.count == 0){
        return 0;
    }

    __block NSInteger leastIndex = 0;
    [heights enumerateObjectsUsingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        if ([number floatValue] < [heights[leastIndex] floatValue]){
            leastIndex = idx;
        }
    }];
    
    return leastIndex;
}

/**
 *  找到高度最大的那一列的下标
 */
- (NSInteger)columnOfMostHeight:(NSInteger)section {
    if (section >= self.columnHeights.count) {
        return 0;
    }
    NSMutableArray *heights = self.columnHeights[section];
    if (heights.count == 0){
        return 0;
    }
    
    __block NSInteger mostIndex = 0;
    [heights enumerateObjectsUsingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        if ([number floatValue] > [heights[mostIndex] floatValue]) {
            mostIndex = idx;
        }
    }];
    
    return mostIndex;
}

- (CGFloat)getColumnHeight:(NSInteger)column inSection:(NSInteger)section {
    if (section < self.columnHeights.count) {
        NSMutableArray *heights = self.columnHeights[section];
        if (column < heights.count) {
            CGFloat height = [heights[column] floatValue];
            if (height < 0) {
                height = _maxY;
                heights[column] = @(height);
            }
            return height;
        }
    }
    return 0;
}

- (void)setColumnHeight:(NSInteger)column inSection:(NSInteger)section height:(CGFloat)height {
    if (section < self.columnHeights.count) {
        NSMutableArray *heights = self.columnHeights[section];
        if (column < heights.count) {
            heights[column] = @(height);
            if (height > _maxY) {
                _maxY = height;
            }
        }
    }
}

@end
