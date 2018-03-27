//
//  WBBarrageModel.h
//  WBBarrageRender
//
//  Created by wanba on 2018/3/27.
//  Copyright © 2018年 wanba. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WBBarrageDefines.h"

@interface WBBarrageModel : NSObject

@property (readonly) WBBarrageType danmakuType;

// unit second, ignore when liveModel
@property (nonatomic) CGFloat time;

- (instancetype)initWithType:(WBBarrageType)danmakuType NS_DESIGNATED_INITIALIZER;

@end
