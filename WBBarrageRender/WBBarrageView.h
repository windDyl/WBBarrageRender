//
//  WBBarrageView.h
//  WBBarrageRender
//
//  Created by wanba on 2018/3/27.
//  Copyright © 2018年 wanba. All rights reserved.
//

//#import <UIKit/UIKit.h>
//
//@interface WBBarrageView : UIView
//
//@end
#import <UIKit/UIKit.h>
#import "WBBarrageConfiguration.h"
#import "WBBarrageModel.h"
#import "WBBarrageCell.h"

@class WBBarrageView;
@protocol WBBarrageViewDelegate <NSObject>

@optional

// preparate completed. you can start render after callback
- (void)prepareCompletedWithDanmakuView:(WBBarrageView *)danmakuView;

// called before render. return NO will ignore danmaku
- (BOOL)danmakuView:(WBBarrageView *)danmakuView shouldRenderDanmaku:(WBBarrageModel *)danmaku;

// display customization
- (void)danmakuView:(WBBarrageView *)danmakuView willDisplayCell:(WBBarrageCell *)cell danmaku:(WBBarrageModel *)danmaku;
- (void)danmakuView:(WBBarrageView *)danmakuView didEndDisplayCell:(WBBarrageCell *)cell danmaku:(WBBarrageModel *)danmaku;

// selection customization
- (BOOL)danmakuView:(WBBarrageView *)danmakuView shouldSelectCell:(WBBarrageCell *)cell danmaku:(WBBarrageModel *)danmaku;
- (void)danmakuView:(WBBarrageView *)danmakuView didSelectCell:(WBBarrageCell *)cell danmaku:(WBBarrageModel *)danmaku;

@end

//_______________________________________________________________________________________________________________

@protocol WBBarrageViewDateSource;
@interface WBBarrageView : UIView

@property (nonatomic, weak) id <WBBarrageViewDateSource> dataSource;
@property (nonatomic, weak) id <WBBarrageViewDelegate> delegate;

@property (readonly) WBBarrageConfiguration *configuration;
@property (readonly) BOOL isPrepared;
@property (readonly) BOOL isPlaying;

// traverse touches outside of the danmaku view, default NO
@property (nonatomic, assign) BOOL traverseTouches;

- (instancetype)initWithFrame:(CGRect)frame configuration:(WBBarrageConfiguration *)configuration;

- (void)registerClass:(Class)cellClass forCellReuseIdentifier:(NSString *)identifier;
- (__kindof WBBarrageCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;

- (__kindof WBBarrageModel *)danmakuForVisibleCell:(WBBarrageCell *)danmakuCell; // returns nil if cell is not visible
@property (nonatomic, readonly) NSArray<__kindof WBBarrageCell *> *visibleCells;

// you can prepare with nil when liveModel
- (void)prepareDanmakus:(NSArray<WBBarrageModel *> *)danmakus;

// be sure to call -prepareDanmakus before -play, when isPrepared is NO, call will be invalid
- (void)play;
- (void)pause;
- (void)stop;

// reset and clear all danmakus, must call -prepareDanmakus before -play once again
- (void)reset;
- (void)clearScreen;


/* send customization. when force, renderer will draw the danmaku immediately and ignore the maximum quantity limit.
 you should call -sendDanmakus: instead of -sendDanmaku:forceRender: to send the danmakus from a remote servers
 */
- (void)sendDanmaku:(WBBarrageModel *)danmaku forceRender:(BOOL)force;
- (void)sendDanmakus:(NSArray<WBBarrageModel *> *)danmakus;

@end

//_______________________________________________________________________________________________________________

@protocol WBBarrageViewDateSource <NSObject>

@required

// variable cell width support
- (CGFloat)danmakuView:(WBBarrageView *)danmakuView widthForDanmaku:(WBBarrageModel *)danmaku;

// cell display. implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
- (WBBarrageCell *)danmakuView:(WBBarrageView *)danmakuView cellForDanmaku:(WBBarrageModel *)danmaku;

@optional

// current play time, unit second, must implementation when videoModel
- (float)playTimeWithDanmakuView:(WBBarrageView *)danmakuView;

// play buffer status, when YES, stop render new danmaku, rendered danmaku in screen will continue anim until disappears, only valid when videoModel
- (BOOL)bufferingWithDanmakuView:(WBBarrageView *)danmakuView;

@end

