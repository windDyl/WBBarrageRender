//
//  WBBarrageModel.m
//  WBBarrageRender
//
//  Created by wanba on 2018/3/27.
//  Copyright © 2018年 wanba. All rights reserved.
//

#import "WBBarrageModel.h"

@interface WBBarrageModel ()

@property (nonatomic) WBBarrageType danmakuType;

@end

@implementation WBBarrageModel

- (instancetype)init {
    return [self initWithType:WBBarrageTypeLR];
}

- (instancetype)initWithType:(WBBarrageType)danmakuType {
    if (self = [super init]) {
        self.danmakuType = danmakuType;
    }
    return self;
}

@end
