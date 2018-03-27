//
//  WBBarrageDefines.h
//  WBBarrageRender
//
//  Created by wanba on 2018/3/27.
//  Copyright © 2018年 wanba. All rights reserved.
//

#ifndef WBBarrageDefines_h
#define WBBarrageDefines_h

typedef NS_ENUM (NSUInteger, WBBarrageMode) {
    WBBarrageModeVideo,
    WBBarrageModeLive
};

typedef NS_ENUM (NSUInteger, WBBarrageType) {
    WBBarrageTypeLR,
    WBBarrageTypeFT,
    WBBarrageTypeFB
};

typedef struct {
    CGFloat time;
    CGFloat interval;
} WBBarrageTime;

NS_INLINE CGFloat WBMaxTime(WBBarrageTime time) {
    return time.time + time.interval;
}

#endif /* WBBarrageDefines_h */
