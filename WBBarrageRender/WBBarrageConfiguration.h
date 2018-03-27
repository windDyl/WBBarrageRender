//
//  WBBarrageConfiguration.h
//  WBBarrageRender
//
//  Created by wanba on 2018/3/27.
//  Copyright © 2018年 wanba. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WBBarrageDefines.h"

@interface WBBarrageConfiguration : NSObject

@property (readonly) WBBarrageMode danmakuMode;

// unit second, greater than zero, default 5.0s
@property (nonatomic) CGFloat duration;

// setting a tolerance for a danmaku render later than the time, unit second, default 2.0s
@property (nonatomic) CGFloat tolerance;

// default 0, full screen
@property (nonatomic) NSInteger numberOfLines;

// height of single line cell, avoid modify after initialization, default 30.0f
@property (nonatomic) CGFloat cellHeight;

// the maximum number of danmakus at the same time, default 0, adapt to the height of screen
@property (nonatomic) NSUInteger maxShowCount;

- (instancetype)initWithDanmakuMode:(WBBarrageMode)danmakuMode NS_DESIGNATED_INITIALIZER;

@end
