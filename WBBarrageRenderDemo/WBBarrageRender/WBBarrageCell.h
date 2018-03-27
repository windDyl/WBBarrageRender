//
//  WBBarrageCell.h
//  WBBarrageRender
//
//  Created by wanba on 2018/3/27.
//  Copyright © 2018年 wanba. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, WBBarrageCellSelectionStyle) {
    WBBarrageCellSelectionStyleNone,     // no select.
    WBBarrageCellSelectionStyleDefault,
};

@interface WBBarrageCell : UIView

@property (nonatomic) NSUInteger zIndex; // default LR 0  FT/FB 10.

@property (nonatomic) WBBarrageCellSelectionStyle selectionStyle; // default is HJDanmakuCellSelectionStyleNone.

@property (nonatomic, readonly) NSString *reuseIdentifier;

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier;

- (void)prepareForReuse;

@end
