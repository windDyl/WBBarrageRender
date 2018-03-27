//
//  WBBarrageConfiguration.m
//  WBBarrageRender
//
//  Created by wanba on 2018/3/27.
//  Copyright © 2018年 wanba. All rights reserved.
//

#import "WBBarrageConfiguration.h"

@interface WBBarrageConfiguration ()

@property (nonatomic) WBBarrageMode danmakuMode;

@end

@implementation WBBarrageConfiguration

- (instancetype)init {
    return [self initWithDanmakuMode:WBBarrageModeVideo];
}

- (instancetype)initWithDanmakuMode:(WBBarrageMode)danmakuMode {
    if (self = [super init]) {
        self.danmakuMode = danmakuMode;
        self.duration = 5.0;
        self.tolerance = 2.0f;
        self.cellHeight = 30.0f;
    }
    return self;
}

@end
