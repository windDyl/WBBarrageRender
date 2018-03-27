//
//  WBBarrageView.m
//  WBBarrageRender
//
//  Created by wanba on 2018/3/27.
//  Copyright © 2018年 wanba. All rights reserved.
//

//#import "WBBarrageView.h"
//
//@implementation WBBarrageView
//
//
//@end

#import "WBBarrageView.h"
#import <libkern/OSAtomic.h>

@class WBBarrageRetainer;

static const CGFloat WBFrameInterval = 0.2;

static inline void onMainThreadAsync(void (^block)()) {
    if ([NSThread isMainThread]) block();
    else dispatch_async(dispatch_get_main_queue(), block);
}

static inline void onGlobalThreadAsync(void (^block)()) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

//_______________________________________________________________________________________________________________

@interface WBBarrageAgent : NSObject

@property (nonatomic, strong) WBBarrageModel *danmakuModel;
@property (nonatomic, strong) WBBarrageCell  *danmakuCell;

@property (nonatomic, assign) BOOL force;

@property (nonatomic, assign) NSInteger toleranceCount;
@property (nonatomic, assign) CGFloat remainingTime;

@property (nonatomic, assign) CGFloat px;
@property (nonatomic, assign) CGFloat py;
@property (nonatomic, assign) CGSize size;

// the line of trajectory, default -1
@property (nonatomic, assign) NSInteger yIdx;

- (instancetype)initWithDanmakuModel:(WBBarrageModel *)danmakuModel;

- (NSComparisonResult)compare:(WBBarrageAgent *)otherDanmakuAgent;

@end

@implementation WBBarrageAgent

- (instancetype)initWithDanmakuModel:(WBBarrageModel *)danmakuModel {
    if (self = [super init]) {
        self.danmakuModel = danmakuModel;
        self.yIdx = -1;
    }
    return self;
}

- (NSComparisonResult)compare:(WBBarrageAgent *)otherDanmakuAgent {
    return [@(self.danmakuModel.time) compare:@(otherDanmakuAgent.danmakuModel.time)];
}

@end

//_______________________________________________________________________________________________________________

@interface WBBarrageSource : NSObject {
    OSSpinLock _spinLock;
}

@property (nonatomic, strong) NSMutableArray <WBBarrageAgent *> *danmakuAgents;

+ (WBBarrageSource *)danmakuSourceWithMode:(WBBarrageMode)mode;

- (void)prepareDanmakus:(NSArray<WBBarrageModel *> *)danmakus completion:(void (^)(void))completion;
- (void)sendDanmaku:(WBBarrageModel *)danmaku forceRender:(BOOL)force;
- (void)sendDanmakus:(NSArray<WBBarrageModel *> *)danmakus;

- (NSArray *)fetchDanmakuAgentsForTime:(WBBarrageTime)time;

- (void)reset;

@end

@implementation WBBarrageSource

+ (WBBarrageSource *)danmakuSourceWithMode:(WBBarrageMode)mode {
    Class class = mode == WBBarrageModeVideo ? NSClassFromString(@"WBBarrageVideoSource"): NSClassFromString(@"WBBarrageLiveSource");
    return [class new];
}

- (instancetype)init {
    if (self = [super init]) {
        _spinLock = OS_SPINLOCK_INIT;
        self.danmakuAgents = [NSMutableArray array];
    }
    return self;
}

- (void)prepareDanmakus:(NSArray<WBBarrageModel *> *)danmakus completion:(void (^)(void))completion {
    NSAssert(NO, @"subClass implementation");
}

- (void)sendDanmaku:(WBBarrageModel *)danmaku forceRender:(BOOL)force {
    NSAssert(NO, @"subClass implementation");
}

- (void)sendDanmakus:(NSArray<WBBarrageModel *> *)danmakus {
    NSAssert(NO, @"subClass implementation");
}

- (NSArray *)fetchDanmakuAgentsForTime:(WBBarrageTime)time {
    NSAssert(NO, @"subClass implementation");
    return nil;
}

- (void)reset {
    OSSpinLockLock(&_spinLock);
    self.danmakuAgents = [NSMutableArray array];
    OSSpinLockUnlock(&_spinLock);
}

@end

//______________________________

@interface WBBarrageVideoSource : WBBarrageSource

@property (nonatomic, assign) NSUInteger lastIndex;

@end

@implementation WBBarrageVideoSource

- (void)prepareDanmakus:(NSArray<WBBarrageModel *> *)danmakus completion:(void (^)(void))completion {
    onGlobalThreadAsync(^{
        NSMutableArray *danmakuAgents = [NSMutableArray arrayWithCapacity:danmakus.count];
        [danmakus enumerateObjectsUsingBlock:^(WBBarrageModel *danmaku, NSUInteger idx, BOOL *stop) {
            WBBarrageAgent *agent = [[WBBarrageAgent alloc] initWithDanmakuModel:danmaku];
            [danmakuAgents addObject:agent];
        }];
        NSArray *sortDanmakuAgents = [danmakuAgents sortedArrayUsingSelector:@selector(compare:)];
        OSSpinLockLock(&_spinLock);
        self.danmakuAgents = [NSMutableArray arrayWithArray:sortDanmakuAgents];
        self.lastIndex = 0;
        OSSpinLockUnlock(&_spinLock);
        if (completion) {
            completion();
        }
    });
}

- (void)sendDanmaku:(WBBarrageModel *)danmaku forceRender:(BOOL)force {
    WBBarrageAgent *danmakuAgent = [[WBBarrageAgent alloc] initWithDanmakuModel:danmaku];
    danmakuAgent.force = force;
    OSSpinLockLock(&_spinLock);
    NSUInteger index = [self indexOfDanmakuAgent:danmakuAgent];
    [self.danmakuAgents insertObject:danmakuAgent atIndex:index];
    self.lastIndex = 0;
    OSSpinLockUnlock(&_spinLock);
}

- (NSUInteger)indexOfDanmakuAgent:(WBBarrageAgent *)danmakuAgent {
    NSUInteger count = self.danmakuAgents.count;
    if (count == 0) {
        return 0;
    }
    NSUInteger index = [self.danmakuAgents indexOfObjectPassingTest:^BOOL(WBBarrageAgent *tempDanmakuAgent, NSUInteger idx, BOOL *stop) {
        return danmakuAgent.danmakuModel.time <= tempDanmakuAgent.danmakuModel.time;
    }];
    if (index == NSNotFound) {
        return count;
    }
    return index;
}

- (void)sendDanmakus:(NSArray<WBBarrageModel *> *)danmakus {
    onGlobalThreadAsync(^{
        OSSpinLockLock(&_spinLock);
        NSMutableArray *danmakuAgents = [NSMutableArray arrayWithArray:self.danmakuAgents];
        OSSpinLockUnlock(&_spinLock);
        [danmakus enumerateObjectsUsingBlock:^(WBBarrageModel *danmaku, NSUInteger idx, BOOL *stop) {
            WBBarrageAgent *danmakuAgent = [[WBBarrageAgent alloc] initWithDanmakuModel:danmaku];
            [danmakuAgents addObject:danmakuAgent];
        }];
        NSArray *sortDanmakuAgents = [danmakuAgents sortedArrayUsingSelector:@selector(compare:)];
        OSSpinLockLock(&_spinLock);
        self.danmakuAgents = [NSMutableArray arrayWithArray:sortDanmakuAgents];
        self.lastIndex = 0;
        OSSpinLockUnlock(&_spinLock);
    });
}

- (NSArray *)fetchDanmakuAgentsForTime:(WBBarrageTime)time {
    OSSpinLockLock(&_spinLock);
    NSUInteger lastIndex = self.lastIndex < self.danmakuAgents.count ? self.lastIndex: NSNotFound;
    if (lastIndex == NSNotFound) {
        OSSpinLockUnlock(&_spinLock);
        return nil;
    }
    WBBarrageAgent *lastDanmakuAgent = self.danmakuAgents[self.lastIndex];
    if (time.time < lastDanmakuAgent.danmakuModel.time) {
        lastIndex = 0;
    }
    CGFloat minTime = floorf(time.time * 10) / 10.0f;
    CGFloat maxTime = WBMaxTime(time);
    NSIndexSet *indexSet = [self.danmakuAgents indexesOfObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(lastIndex, self.danmakuAgents.count - lastIndex)] options:NSEnumerationConcurrent passingTest:^BOOL(WBBarrageAgent *danmakuAgent, NSUInteger idx, BOOL *stop) {
        if (danmakuAgent.danmakuModel.time > maxTime) {
            *stop = YES;
        }
        return danmakuAgent.remainingTime <= 0 && danmakuAgent.danmakuModel.time >= minTime && danmakuAgent.danmakuModel.time < maxTime;
    }];
    if (indexSet.count == 0) {
        OSSpinLockUnlock(&_spinLock);
        return nil;
    }
    NSArray *danmakuAgents = [self.danmakuAgents objectsAtIndexes:indexSet];
    self.lastIndex = indexSet.firstIndex;
    OSSpinLockUnlock(&_spinLock);
    return danmakuAgents;
}

- (void)reset {
    [super reset];
    self.lastIndex = 0;
}

@end

//______________________________

@interface WBBarrageLiveSource : WBBarrageSource

@end

@implementation WBBarrageLiveSource

- (void)prepareDanmakus:(NSArray<WBBarrageModel *> *)danmakus completion:(void (^)(void))completion {
    onGlobalThreadAsync(^{
        NSMutableArray *danmakuAgents = [NSMutableArray arrayWithCapacity:danmakus.count];
        [danmakus enumerateObjectsUsingBlock:^(WBBarrageModel *danmaku, NSUInteger idx, BOOL *stop) {
            WBBarrageAgent *danmakuAgent = [[WBBarrageAgent alloc] initWithDanmakuModel:danmaku];
            [danmakuAgents addObject:danmakuAgent];
        }];
        OSSpinLockLock(&_spinLock);
        self.danmakuAgents = danmakuAgents;
        OSSpinLockUnlock(&_spinLock);
        if (completion) {
            completion();
        }
    });
}

- (void)sendDanmaku:(WBBarrageModel *)danmaku forceRender:(BOOL)force {
    WBBarrageAgent *danmakuAgent = [[WBBarrageAgent alloc] initWithDanmakuModel:danmaku];
    danmakuAgent.force = force;
    OSSpinLockLock(&_spinLock);
    [self.danmakuAgents addObject:danmakuAgent];
    OSSpinLockUnlock(&_spinLock);
}

- (void)sendDanmakus:(NSArray<WBBarrageModel *> *)danmakus {
    onGlobalThreadAsync(^{
        u_int interval = 100;
        NSMutableArray *danmakuAgents = [NSMutableArray arrayWithCapacity:interval];
        NSUInteger lastIndex = danmakus.count - 1;
        [danmakus enumerateObjectsUsingBlock:^(WBBarrageModel *danmaku, NSUInteger idx, BOOL *stop) {
            WBBarrageAgent *agent = [[WBBarrageAgent alloc] initWithDanmakuModel:danmaku];
            [danmakuAgents addObject:agent];
            if (idx == lastIndex || danmakuAgents.count % interval == 0) {
                OSSpinLockLock(&_spinLock);
                [self.danmakuAgents addObjectsFromArray:danmakuAgents];
                OSSpinLockUnlock(&_spinLock);
                [danmakuAgents removeAllObjects];
            }
        }];
    });
}

- (NSArray *)fetchDanmakuAgentsForTime:(WBBarrageTime)time {
    OSSpinLockLock(&_spinLock);
    NSArray *danmakuAgents = [self.danmakuAgents copy];
    [self.danmakuAgents removeAllObjects];
    OSSpinLockUnlock(&_spinLock);
    return danmakuAgents;
}

@end

//_______________________________________________________________________________________________________________

#if OS_OBJECT_USE_OBJC
#define WBDispatchQueueRelease(__v)
#else
#define WBDispatchQueueRelease(__v) (dispatch_release(__v));
#endif

@interface WBBarrageView () {
    OSSpinLock _reuseLock;
    dispatch_queue_t _renderQueue;
    CGRect _renderBounds;
}

@property (nonatomic, strong) WBBarrageConfiguration *configuration;
@property (nonatomic, assign) NSUInteger toleranceCount;

@property (nonatomic, strong) WBBarrageSource *danmakuSource;
@property (nonatomic, strong) NSOperationQueue *sourceQueue;

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) WBBarrageTime playTime;

@property (atomic, assign) BOOL isPrepared;
@property (atomic, assign) BOOL isPlaying;

@property (nonatomic, strong) NSMutableDictionary *cellClassInfo;
@property (nonatomic, strong) NSMutableDictionary *cellReusePool;

@property (nonatomic, strong) NSMutableArray <WBBarrageAgent *> *danmakuQueuePool;
@property (nonatomic, strong) NSMutableArray <WBBarrageAgent *> *renderingDanmakus;

@property (nonatomic, strong) NSMutableDictionary <NSNumber *, WBBarrageAgent *> *LRRetainer;
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, WBBarrageAgent *> *FTRetainer;
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, WBBarrageAgent *> *FBRetainer;

@property (nonatomic, weak) WBBarrageAgent *selectDanmakuAgent;

@end

@implementation WBBarrageView

- (void)dealloc {
    WBDispatchQueueRelease(_renderQueue);
}

- (instancetype)initWithFrame:(CGRect)frame configuration:(WBBarrageConfiguration *)configuration {
    if (self = [super initWithFrame:frame]) {
        self.clipsToBounds = YES;
        self.configuration = configuration;
        self.toleranceCount = (NSUInteger)(fabs(self.configuration.tolerance) / WBFrameInterval);
        self.toleranceCount = MAX(self.toleranceCount, 1);
        self.cellClassInfo = [NSMutableDictionary dictionary];
        self.cellReusePool = [NSMutableDictionary dictionary];
        self.danmakuQueuePool = [NSMutableArray array];
        self.renderingDanmakus = [NSMutableArray array];
        self.LRRetainer = [NSMutableDictionary dictionary];
        self.FTRetainer = [NSMutableDictionary dictionary];
        self.FBRetainer = [NSMutableDictionary dictionary];
        self.danmakuSource = [WBBarrageSource danmakuSourceWithMode:configuration.danmakuMode];
        
        self.sourceQueue = [NSOperationQueue new];
        self.sourceQueue.name = @"com.olinone.danmaku.sourceQueue";
        self.sourceQueue.maxConcurrentOperationCount = 1;
        
        _reuseLock = OS_SPINLOCK_INIT;
        _renderQueue = dispatch_queue_create("com.olinone.danmaku.renderQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_renderQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    }
    return self;
}

#pragma mark -

- (void)registerClass:(Class)cellClass forCellReuseIdentifier:(NSString *)identifier {
    if (!identifier) {
        return;
    }
    self.cellClassInfo[identifier] = cellClass;
}

- (WBBarrageCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier {
    if (!identifier) {
        return nil;
    }
    NSMutableArray *cells = self.cellReusePool[identifier];
    if (cells.count == 0) {
        Class cellClass = self.cellClassInfo[identifier];
        return cellClass ? [[cellClass alloc] initWithReuseIdentifier:identifier]: nil;
    }
    OSSpinLockLock(&_reuseLock);
    WBBarrageCell *cell = cells.lastObject;
    [cells removeLastObject];
    OSSpinLockUnlock(&_reuseLock);
    cell.zIndex = 0;
    [cell prepareForReuse];
    return cell;
}

- (void)recycleCellToReusePool:(WBBarrageCell *)danmakuCell {
    NSString *identifier = danmakuCell.reuseIdentifier;
    if (!identifier) {
        return;
    }
    OSSpinLockLock(&_reuseLock);
    NSMutableArray *cells = self.cellReusePool[identifier];
    if (!cells) {
        cells = [NSMutableArray array];
        self.cellReusePool[identifier] = cells;
    }
    [cells addObject:danmakuCell];
    OSSpinLockUnlock(&_reuseLock);
}

#pragma mark -

- (void)prepareDanmakus:(NSArray<WBBarrageModel *> *)danmakus {
    self.isPrepared = NO;
    [self stop];
    
    if (danmakus.count == 0) {
        self.isPrepared = YES;
        onMainThreadAsync(^{
            if ([self.delegate respondsToSelector:@selector(prepareCompletedWithDanmakuView:)]) {
                [self.delegate prepareCompletedWithDanmakuView:self];
            }
        });
        return;
    }
    
    [self.danmakuSource prepareDanmakus:danmakus completion:^{
        [self preloadDanmakusWhenPrepare];
        self.isPrepared = YES;
        onMainThreadAsync(^{
            if ([self.delegate respondsToSelector:@selector(prepareCompletedWithDanmakuView:)]) {
                [self.delegate prepareCompletedWithDanmakuView:self];
            }
        });
    }];
}

- (void)play {
    if (!self.configuration || self.configuration.duration <= 0) {
        NSAssert(NO, @"configuration nil or duration <= 0");
        return;
    }
    if (!self.isPrepared) {
        NSAssert(NO, @"isPrepared is NO!");
        return;
    }
    if (self.isPlaying) {
        return;
    }
    self.isPlaying = YES;
    [self resumeDisplayingDanmakus];
    if (!self.displayLink) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
        self.displayLink.frameInterval = 60.0 * WBFrameInterval;
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    self.displayLink.paused = NO;
}

- (void)pause {
    if (!self.isPlaying) {
        return;
    }
    self.isPlaying = NO;
    self.displayLink.paused = YES;
    [self pauseDisplayingDanmakus];
}

- (void)stop {
    self.isPlaying = NO;
    [self.displayLink invalidate];
    self.displayLink = nil;
    self.playTime = (WBBarrageTime){0, WBFrameInterval};
    dispatch_async(_renderQueue, ^{
        [self.danmakuQueuePool removeAllObjects];
    });
    [self clearScreen];
}

- (void)reset {
    [self stop];
    [self.danmakuSource reset];
    self.isPrepared = NO;
}

- (void)clearScreen {
    [self recycleDanmakuAgents:[self.renderingDanmakus copy]];
    dispatch_async(_renderQueue, ^{
        [self.renderingDanmakus removeAllObjects];
        [self.LRRetainer removeAllObjects];
        [self.FTRetainer removeAllObjects];
        [self.FBRetainer removeAllObjects];
    });
}

- (void)sizeToFit {
    [super sizeToFit];
    NSArray *danmakuAgents = [self visibleDanmakuAgents];
    onMainThreadAsync(^{
        CGFloat midX = CGRectGetMidX(self.bounds);
        CGFloat height = CGRectGetHeight(self.bounds);
        for (WBBarrageAgent *danmakuAgent in danmakuAgents) {
            if (danmakuAgent.danmakuModel.danmakuType != WBBarrageTypeLR) {
                CGPoint centerPoint = danmakuAgent.danmakuCell.center;
                centerPoint.x = midX;
                danmakuAgent.danmakuCell.center = centerPoint;
                if (danmakuAgent.danmakuModel.danmakuType == WBBarrageTypeFB) {
                    CGRect rect = danmakuAgent.danmakuCell.frame;
                    rect.origin.y = height - self.configuration.cellHeight * (danmakuAgent.yIdx + 1);
                    danmakuAgent.danmakuCell.frame = rect;
                }
            }
        }
    });
}

#pragma mark -

- (void)preloadDanmakusWhenPrepare {
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        NSArray <WBBarrageAgent *> *danmakuAgents = [self.danmakuSource fetchDanmakuAgentsForTime:self.playTime];
        for (WBBarrageAgent *danmakuAgent in danmakuAgents) {
            danmakuAgent.remainingTime = self.configuration.duration;
            danmakuAgent.toleranceCount = self.toleranceCount;
        }
        dispatch_async(_renderQueue, ^{
            [self.danmakuQueuePool addObjectsFromArray:danmakuAgents];
        });
    }];
    [self.sourceQueue cancelAllOperations];
    [self.sourceQueue addOperation:operation];
}

- (void)pauseDisplayingDanmakus {
    NSArray *danmakuAgents = [self visibleDanmakuAgents];
    onMainThreadAsync(^{
        for (WBBarrageAgent *danmakuAgent in danmakuAgents) {
            if (danmakuAgent.danmakuModel.danmakuType == WBBarrageTypeLR) {
                CALayer *layer = danmakuAgent.danmakuCell.layer;
                danmakuAgent.danmakuCell.frame = ((CALayer *)layer.presentationLayer).frame;
                [danmakuAgent.danmakuCell.layer removeAllAnimations];
            }
        }
    });
}

- (void)resumeDisplayingDanmakus {
    NSArray *danmakuAgents = [self visibleDanmakuAgents];
    onMainThreadAsync(^{
        for (WBBarrageAgent *danmakuAgent in danmakuAgents) {
            if (danmakuAgent.danmakuModel.danmakuType == WBBarrageTypeLR) {
                [UIView animateWithDuration:danmakuAgent.remainingTime delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    danmakuAgent.danmakuCell.frame = (CGRect){CGPointMake(-danmakuAgent.size.width, danmakuAgent.py), danmakuAgent.size};
                } completion:nil];
            }
        }
    });
}

#pragma mark - Render

- (void)update {
    WBBarrageTime time = {0, WBFrameInterval};
    if ([self.dataSource respondsToSelector:@selector(playTimeWithDanmakuView:)]) {
        time.time = [self.dataSource playTimeWithDanmakuView:self];
    }
    if (self.configuration.danmakuMode == WBBarrageModeVideo && time.time <= 0) {
        return;
    }
    BOOL isBuffering = NO;
    if ([self.dataSource respondsToSelector:@selector(bufferingWithDanmakuView:)]) {
        isBuffering = [self.dataSource bufferingWithDanmakuView:self];
    }
    if (!isBuffering) {
        [self loadDanmakusFromSourceForTime:time];
    }
    [self renderDanmakusForTime:time buffering:isBuffering];
}

- (void)loadDanmakusFromSourceForTime:(WBBarrageTime)time {
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        NSArray <WBBarrageAgent *> *danmakuAgents = [self.danmakuSource fetchDanmakuAgentsForTime:(WBBarrageTime){WBMaxTime(time), time.interval}];
        danmakuAgents = [danmakuAgents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"remainingTime <= 0"]];
        for (WBBarrageAgent *danmakuAgent in danmakuAgents) {
            danmakuAgent.remainingTime = self.configuration.duration;
            danmakuAgent.toleranceCount = self.toleranceCount;
        }
        dispatch_async(_renderQueue, ^{
            if (time.time < self.playTime.time || time.time > WBMaxTime(self.playTime) + self.configuration.tolerance) {
                [self.danmakuQueuePool removeAllObjects];
            }
            if (danmakuAgents.count > 0) {
                [self.danmakuQueuePool insertObjects:danmakuAgents atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, danmakuAgents.count)]];
            }
            self.playTime = time;
        });
    }];
    [self.sourceQueue cancelAllOperations];
    [self.sourceQueue addOperation:operation];
}

- (void)renderDanmakusForTime:(WBBarrageTime)time buffering:(BOOL)isBuffering {
    _renderBounds = self.bounds;
    dispatch_async(_renderQueue, ^{
        [self renderDisplayingDanmakusForTime:time];
        if (!isBuffering) {
            [self renderNewDanmakusForTime:time];
            [self removeExpiredDanmakusForTime:time];
        }
    });
}

- (void)renderDisplayingDanmakusForTime:(WBBarrageTime)time {
    NSMutableArray *disappearDanmakuAgens = [NSMutableArray arrayWithCapacity:self.renderingDanmakus.count];
    [self.renderingDanmakus enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(WBBarrageAgent *danmakuAgent, NSUInteger idx, BOOL *stop) {
        danmakuAgent.remainingTime -= time.interval;
        if (danmakuAgent.remainingTime <= 0) {
            [disappearDanmakuAgens addObject:danmakuAgent];
            [self.renderingDanmakus removeObjectAtIndex:idx];
        }
    }];
    [self recycleDanmakuAgents:disappearDanmakuAgens];
}

- (void)recycleDanmakuAgents:(NSArray *)danmakuAgents {
    if (danmakuAgents.count == 0) {
        return;
    }
    onMainThreadAsync(^{
        for (WBBarrageAgent *danmakuAgent in danmakuAgents) {
            [danmakuAgent.danmakuCell.layer removeAllAnimations];
            [danmakuAgent.danmakuCell removeFromSuperview];
            danmakuAgent.yIdx = -1;
            danmakuAgent.remainingTime = 0;
            [self recycleCellToReusePool:danmakuAgent.danmakuCell];
            if ([self.delegate respondsToSelector:@selector(danmakuView:didEndDisplayCell:danmaku:)]) {
                [self.delegate danmakuView:self didEndDisplayCell:danmakuAgent.danmakuCell danmaku:danmakuAgent.danmakuModel];
            }
        }
    });
}

- (void)renderNewDanmakusForTime:(WBBarrageTime)time {
    NSUInteger maxShowCount = self.configuration.maxShowCount > 0 ? self.configuration.maxShowCount : NSUIntegerMax;
    NSMutableDictionary *renderResult = [NSMutableDictionary dictionary];
    for (WBBarrageAgent *danmakuAgent in self.danmakuQueuePool) {
        NSNumber *retainKey = @(danmakuAgent.danmakuModel.danmakuType);
        if (!danmakuAgent.force) {
            if (self.renderingDanmakus.count > maxShowCount) {
                break;
            }
            if (renderResult[@(WBBarrageTypeLR)] && renderResult[@(WBBarrageTypeFT)] && renderResult[@(WBBarrageTypeFB)]) {
                break;
            }
            if (renderResult[retainKey]) {
                continue;
            }
        }
        BOOL shouldRender = YES;
        if ([self.delegate respondsToSelector:@selector(danmakuView:shouldRenderDanmaku:)]) {
            shouldRender = [self.delegate danmakuView:self shouldRenderDanmaku:danmakuAgent.danmakuModel];
        }
        if (!shouldRender) {
            continue;
        }
        if (![self renderNewDanmaku:danmakuAgent forTime:time]) {
            renderResult[retainKey] = @(YES);
        }
    }
}

- (BOOL)renderNewDanmaku:(WBBarrageAgent *)danmakuAgent forTime:(WBBarrageTime)time {
    if (![self layoutNewDanmaku:danmakuAgent forTime:time]) {
        return NO;
    }
    [self.renderingDanmakus addObject:danmakuAgent];
    danmakuAgent.toleranceCount = 0;
    onMainThreadAsync(^{
        danmakuAgent.danmakuCell = ({
            WBBarrageCell *cell = [self.dataSource danmakuView:self cellForDanmaku:danmakuAgent.danmakuModel];
            cell.frame = (CGRect){CGPointMake(danmakuAgent.px, danmakuAgent.py), danmakuAgent.size};
            cell.zIndex = cell.zIndex > 0 ? cell.zIndex: (danmakuAgent.danmakuModel.danmakuType == WBBarrageTypeLR ? 0: 10);
            cell;
        });
        if ([self.delegate respondsToSelector:@selector(danmakuView:willDisplayCell:danmaku:)]) {
            [self.delegate danmakuView:self willDisplayCell:danmakuAgent.danmakuCell danmaku:danmakuAgent.danmakuModel];
        }
        [self insertSubview:danmakuAgent.danmakuCell atIndex:danmakuAgent.danmakuCell.zIndex];
        if (danmakuAgent.danmakuModel.danmakuType == WBBarrageTypeLR) {
            [UIView animateWithDuration:danmakuAgent.remainingTime delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                danmakuAgent.danmakuCell.frame = (CGRect){CGPointMake(-danmakuAgent.size.width, danmakuAgent.py), danmakuAgent.size};
            } completion:nil];
        }
    });
    return YES;
}

- (void)removeExpiredDanmakusForTime:(WBBarrageTime)time {
    [self.danmakuQueuePool enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(WBBarrageAgent *danmakuAgent, NSUInteger idx, BOOL *stop) {
        danmakuAgent.toleranceCount --;
        if (danmakuAgent.toleranceCount <= 0) {
            [self.danmakuQueuePool removeObjectAtIndex:idx];
        }
    }];
}

#pragma mark - Retainer

- (BOOL)layoutNewDanmaku:(WBBarrageAgent *)danmakuAgent forTime:(WBBarrageTime)time {
    CGFloat width = [self.dataSource danmakuView:self widthForDanmaku:danmakuAgent.danmakuModel];
    danmakuAgent.size = CGSizeMake(width, self.configuration.cellHeight);
    CGFloat py = [self layoutPyWithNewDanmaku:danmakuAgent forTime:time];
    if (py < 0) {
        return NO;
    }
    danmakuAgent.py = py;
    danmakuAgent.px = danmakuAgent.danmakuModel.danmakuType == WBBarrageTypeLR ? CGRectGetWidth(_renderBounds): (CGRectGetMidX(_renderBounds) - danmakuAgent.size.width / 2);
    return YES;
}

- (CGFloat)layoutPyWithNewDanmaku:(WBBarrageAgent *)danmakuAgent forTime:(WBBarrageTime)time {
    switch (danmakuAgent.danmakuModel.danmakuType) {
        case WBBarrageTypeLR:
            return [self layoutPyWithLRDanmaku:danmakuAgent forTime:time];
        case WBBarrageTypeFT:
            return [self layoutPyWithFTDanmaku:danmakuAgent forTime:time];
        case WBBarrageTypeFB:
            return [self layoutPyWithFBDanmaku:danmakuAgent forTime:time];
    }
}

// LR
- (CGFloat)layoutPyWithLRDanmaku:(WBBarrageAgent *)danmakuAgent forTime:(WBBarrageTime)time {
    u_int8_t maxPyIndex = self.configuration.numberOfLines > 0 ? self.configuration.numberOfLines: (CGRectGetHeight(_renderBounds) / self.configuration.cellHeight);
    NSMutableDictionary *retainer = [self retainerWithType:danmakuAgent.danmakuModel.danmakuType];
    for (u_int8_t index = 0; index < maxPyIndex; index++) {
        NSNumber *key = @(index);
        WBBarrageAgent *tempAgent = retainer[key];
        if (!tempAgent) {
            danmakuAgent.yIdx = index;
            retainer[key] = danmakuAgent;
            return self.configuration.cellHeight * index;
        }
        if (![self checkLRIsWillHitWithPreDanmaku:tempAgent danmaku:danmakuAgent]) {
            danmakuAgent.yIdx = index;
            retainer[key] = danmakuAgent;
            return self.configuration.cellHeight * index;
        }
    }
    if (danmakuAgent.force) {
        u_int8_t index = arc4random() % maxPyIndex;
        danmakuAgent.yIdx = index;
        retainer[@(index)] = danmakuAgent;
        return self.configuration.cellHeight * index;
    }
    return -1;
}

- (BOOL)checkLRIsWillHitWithPreDanmaku:(WBBarrageAgent *)preDanmakuAgent danmaku:(WBBarrageAgent *)danmakuAgent {
    if (preDanmakuAgent.remainingTime <= 0) {
        return NO;
    }
    CGFloat width = CGRectGetWidth(_renderBounds);
    CGFloat preDanmakuSpeed = (width + preDanmakuAgent.size.width) / self.configuration.duration;
    if (preDanmakuSpeed * (self.configuration.duration - preDanmakuAgent.remainingTime) < preDanmakuAgent.size.width) {
        return YES;
    }
    CGFloat curDanmakuSpeed = (width + danmakuAgent.size.width) / self.configuration.duration;
    if (curDanmakuSpeed * preDanmakuAgent.remainingTime > width) {
        return YES;
    }
    return NO;
}

// FT
- (CGFloat)layoutPyWithFTDanmaku:(WBBarrageAgent *)danmakuAgent forTime:(WBBarrageTime)time {
    u_int8_t maxPyIndex = self.configuration.numberOfLines > 0 ? self.configuration.numberOfLines: (CGRectGetHeight(_renderBounds) / 2.0 / self.configuration.cellHeight);
    NSMutableDictionary *retainer = [self retainerWithType:danmakuAgent.danmakuModel.danmakuType];
    for (u_int8_t index = 0; index < maxPyIndex; index++) {
        NSNumber *key = @(index);
        WBBarrageAgent *tempAgent = retainer[key];
        if (!tempAgent) {
            danmakuAgent.yIdx = index;
            retainer[key] = danmakuAgent;
            return self.configuration.cellHeight * index;
        }
        if (![self checkFTIsWillHitWithPreDanmaku:tempAgent danmaku:danmakuAgent]) {
            danmakuAgent.yIdx = index;
            retainer[key] = danmakuAgent;
            return self.configuration.cellHeight * index;
        }
    }
    if (danmakuAgent.force) {
        u_int8_t index = arc4random() % maxPyIndex;
        danmakuAgent.yIdx = index;
        retainer[@(index)] = danmakuAgent;
        return self.configuration.cellHeight * index;
    }
    return -1;
}

- (BOOL)checkFTIsWillHitWithPreDanmaku:(WBBarrageAgent *)preDanmakuAgent danmaku:(WBBarrageAgent *)danmakuAgent {
    if (preDanmakuAgent.remainingTime <= 0) {
        return NO;
    }
    return YES;
}

// FB
- (CGFloat)layoutPyWithFBDanmaku:(WBBarrageAgent *)danmakuAgent forTime:(WBBarrageTime)time {
    u_int8_t maxPyIndex = self.configuration.numberOfLines > 0 ? self.configuration.numberOfLines: (CGRectGetHeight(_renderBounds) / 2.0 / self.configuration.cellHeight);
    NSMutableDictionary *retainer = [self retainerWithType:danmakuAgent.danmakuModel.danmakuType];
    for (u_int8_t index = 0; index < maxPyIndex; index++) {
        NSNumber *key = @(index);
        WBBarrageAgent *tempAgent = retainer[key];
        if (!tempAgent) {
            danmakuAgent.yIdx = index;
            retainer[key] = danmakuAgent;
            return CGRectGetHeight(_renderBounds) - self.configuration.cellHeight * (index + 1);
        }
        if (![self checkFBIsWillHitWithPreDanmaku:tempAgent danmaku:danmakuAgent]) {
            danmakuAgent.yIdx = index;
            retainer[key] = danmakuAgent;
            return CGRectGetHeight(_renderBounds) - self.configuration.cellHeight * (index + 1);
        }
    }
    if (danmakuAgent.force) {
        u_int8_t index = arc4random() % maxPyIndex;
        danmakuAgent.yIdx = index;
        retainer[@(index)] = danmakuAgent;
        return CGRectGetHeight(_renderBounds) - self.configuration.cellHeight * (index + 1);
    }
    return -1;
}

- (BOOL)checkFBIsWillHitWithPreDanmaku:(WBBarrageAgent *)preDanmakuAgent danmaku:(WBBarrageAgent *)danmakuAgent {
    if (preDanmakuAgent.remainingTime <= 0) {
        return NO;
    }
    return YES;
}

- (NSMutableDictionary *)retainerWithType:(WBBarrageType)danmakuType {
    switch (danmakuType) {
        case WBBarrageTypeLR:return self.LRRetainer;
        case WBBarrageTypeFT:return self.FTRetainer;
        case WBBarrageTypeFB:return self.FBRetainer;
        default:return nil;
    }
}

#pragma mark - Touch

- (WBBarrageAgent *)danmakuAgentAtPoint:(CGPoint)point {
    NSArray *sortDanmakuAgents = [[self visibleDanmakuAgents] sortedArrayUsingComparator:^NSComparisonResult(WBBarrageAgent *obj1, WBBarrageAgent *obj2) {
        return obj1.danmakuCell.zIndex > obj2.danmakuCell.zIndex ? NSOrderedAscending: NSOrderedDescending;
    }];
    for (WBBarrageAgent *danmakuAgent in sortDanmakuAgents) {
        CGRect rect = danmakuAgent.danmakuCell.layer.presentationLayer.frame;
        if (CGRectContainsPoint(rect, point)) {
            return danmakuAgent;
        }
    }
    return nil;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    self.selectDanmakuAgent = nil;
    WBBarrageAgent *danmakuAgent = [self danmakuAgentAtPoint:point];
    if (danmakuAgent) {
        if (danmakuAgent.danmakuCell.selectionStyle == WBBarrageCellSelectionStyleDefault) {
            self.selectDanmakuAgent = danmakuAgent;
            return self;
        }
        CGPoint cellPoint = [self convertPoint:point toView:danmakuAgent.danmakuCell];
        return [danmakuAgent.danmakuCell hitTest:cellPoint withEvent:event];
    }
    return self.traverseTouches ? nil: [super hitTest:point withEvent:event];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    if (self.selectDanmakuAgent) {
        if ([self.delegate respondsToSelector:@selector(danmakuView:shouldSelectCell:danmaku:)]) {
            BOOL shouldSelect = [self.delegate danmakuView:self shouldSelectCell:self.selectDanmakuAgent.danmakuCell danmaku:self.selectDanmakuAgent.danmakuModel];
            if (!shouldSelect) {
                self.selectDanmakuAgent = nil;
                return;
            }
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    if (self.selectDanmakuAgent) {
        CGRect rect = self.selectDanmakuAgent.danmakuCell.layer.presentationLayer.frame;
        CGPoint touchPoint = [[touches anyObject] locationInView:self];
        if (!CGRectContainsPoint(rect, touchPoint)) {
            self.selectDanmakuAgent = nil;
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    if (self.selectDanmakuAgent) {
        CGRect rect = self.selectDanmakuAgent.danmakuCell.layer.presentationLayer.frame;
        CGPoint touchPoint = [[touches anyObject] locationInView:self];
        if (CGRectContainsPoint(rect, touchPoint)) {
            if ([self.delegate respondsToSelector:@selector(danmakuView:didSelectCell:danmaku:)]) {
                [self.delegate danmakuView:self didSelectCell:self.selectDanmakuAgent.danmakuCell danmaku:self.selectDanmakuAgent.danmakuModel];
            }
            self.selectDanmakuAgent = nil;
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    self.selectDanmakuAgent = nil;
}

#pragma mark -

- (void)sendDanmaku:(WBBarrageModel *)danmaku forceRender:(BOOL)force {
    if (!danmaku) {
        return;
    }
    [self.danmakuSource sendDanmaku:danmaku forceRender:force];
    
    if (force) {
        WBBarrageTime time = {0, WBFrameInterval};
        if ([self.dataSource respondsToSelector:@selector(playTimeWithDanmakuView:)]) {
            time.time = [self.dataSource playTimeWithDanmakuView:self];
        }
        [self loadDanmakusFromSourceForTime:time];
    }
}

- (void)sendDanmakus:(NSArray<WBBarrageModel *> *)danmakus {
    if (danmakus.count == 0) {
        return;
    }
    [self.danmakuSource sendDanmakus:danmakus];
}

- (WBBarrageModel *)danmakuForVisibleCell:(WBBarrageCell *)danmakuCell {
    if (!danmakuCell) {
        return nil;
    }
    NSArray *danmakuAgents = [self visibleDanmakuAgents];
    for (WBBarrageAgent *danmakuAgent in danmakuAgents) {
        if (danmakuAgent.danmakuCell == danmakuCell) {
            return danmakuAgent.danmakuModel;
        }
    }
    return nil;
}

- (NSArray *)visibleCells {
    __block NSMutableArray *visibleCells = [NSMutableArray array];
    dispatch_sync(_renderQueue, ^{
        [self.renderingDanmakus enumerateObjectsUsingBlock:^(WBBarrageAgent *danmakuAgent, NSUInteger idx, BOOL * _Nonnull stop) {
            WBBarrageCell *cell = danmakuAgent.danmakuCell;
            if (cell) {
                [visibleCells addObject:cell];
            }
        }];
    });
    return visibleCells;
}

- (NSArray *)visibleDanmakuAgents {
    __block NSArray *renderingDanmakus = nil;
    dispatch_sync(_renderQueue, ^{
        renderingDanmakus = [NSArray arrayWithArray:self.renderingDanmakus];
    });
    return renderingDanmakus;
}

@end
