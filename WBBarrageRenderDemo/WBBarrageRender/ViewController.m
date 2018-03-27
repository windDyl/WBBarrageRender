//
//  ViewController.m
//  WBBarrageRender
//
//  Created by wanba on 2018/3/27.
//  Copyright © 2018年 wanba. All rights reserved.
//

#import "ViewController.h"
#import "WBBarrageConfiguration.h"
#import "WBBarrageView.h"
#import "BarrageCell.h"
#import "BarrageModel.h"

@interface ViewController ()<WBBarrageViewDelegate, WBBarrageViewDateSource>
@property (nonatomic, strong) WBBarrageView *danmakuView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    WBBarrageConfiguration *config = [[WBBarrageConfiguration alloc] initWithDanmakuMode:WBBarrageModeLive];
    self.danmakuView = [[WBBarrageView alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.view.bounds), CGRectGetMinY(self.view.bounds)+15, self.view.bounds.size.width, self.view.bounds.size.height-15) configuration:config];
    self.danmakuView.dataSource = self;
    self.danmakuView.delegate = self;
    [self.danmakuView registerClass:[BarrageCell class] forCellReuseIdentifier:@"cell"];
    self.danmakuView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.danmakuView];
    if (!self.danmakuView.isPrepared) {
        [self.danmakuView prepareDanmakus:nil];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSString *content = @"三地均涉及到是你卡萨丁女宽松商店女卡收到女";
    CGFloat textSize = 17;
    BOOL showAvatar = NO;
    BOOL showVipMark = NO;
    UIColor *textColor = [UIColor whiteColor];
    NSString *iconUrl = @"";
    BOOL showUserName = YES;
    NSString *userName = @"是的不拿手机";
    UIColor *userNameColor = [UIColor orangeColor];
    CGFloat duration = 10.0;
    CGSize tipsSize = CGSizeMake(100, 14);
    CGSize titleSize = CGSizeMake(340, 20);
    
    
    
    BarrageModel *barrageModel = [[BarrageModel alloc] init];
    barrageModel.iconUrl = showAvatar ? iconUrl : @"";
    barrageModel.hiddenLevelIcon = showAvatar ? (!showVipMark) : YES;
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowBlurRadius = 4.0;
    shadow.shadowOffset = CGSizeMake(1, 1);
    shadow.shadowColor = [UIColor blackColor];
    NSDictionary *atts = @{NSShadowAttributeName: shadow, NSFontAttributeName:[UIFont systemFontOfSize:textSize], NSForegroundColorAttributeName: textColor};
    NSAttributedString *contentAttribute = [[NSAttributedString alloc] initWithString:content attributes:atts];
    barrageModel.attributedContent = contentAttribute;
    
    barrageModel.bottomColor = textColor;
//    barrageModel.hiddenBottomLine = ![uid isEqualToString:[UCAccount instance].myself.uid];
    barrageModel.hiddenBottomLine = NO;
    
    CGFloat nameTextSize = showUserName ? ((textSize/2 > 8) ? textSize/2 : 8) : 0.0f;
    NSString *titleStr = showUserName ? userName : @"";
    NSAttributedString *nameAttribute = [[NSAttributedString alloc] initWithString:titleStr attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:nameTextSize], NSForegroundColorAttributeName:userNameColor}];
    barrageModel.attributedUserName = nameAttribute;
    
//    CGSize tipsSize = [UCUtility textSize:titleStr andFont:[UIFont systemFontOfSize:nameTextSize] andwidth:CGFLOAT_MAX];
//    CGSize titleSize = [UCUtility textSize:content andFont:[UIFont systemFontOfSize:textSize] andwidth:CGFLOAT_MAX];
    barrageModel.nameSize = tipsSize;
    barrageModel.contentSize = titleSize;
    barrageModel.maxH = tipsSize.height + titleSize.height;
    barrageModel.maxW = MAX(tipsSize.width, titleSize.width) + tipsSize.height + titleSize.height;
    //    [self.danmakuView sendDanmaku:barrageModel forceRender:NO];
    self.danmakuView.configuration.cellHeight = barrageModel.maxH;
    self.danmakuView.configuration.duration = duration;
    [NSTimer scheduledTimerWithTimeInterval:0.01 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [self.danmakuView sendDanmaku:barrageModel forceRender:NO];
    }];
    [self.danmakuView play];
}

#pragma mark - delegate

- (void)prepareCompletedWithDanmakuView:(WBBarrageView *)danmakuView {
    [self.danmakuView play];
}

- (BOOL)danmakuView:(WBBarrageView *)danmakuView shouldSelectCell:(WBBarrageCell *)cell danmaku:(WBBarrageModel *)danmaku {
    return danmaku.danmakuType == WBBarrageTypeLR;
}

- (void)danmakuView:(WBBarrageView *)danmakuView didSelectCell:(WBBarrageCell *)cell danmaku:(WBBarrageModel *)danmaku {
    NSLog(@"select=> %@", cell.textLabel.text);
}

#pragma mark - dataSource

- (CGFloat)danmakuView:(WBBarrageView *)danmakuView widthForDanmaku:(WBBarrageModel *)danmaku {
    BarrageModel *model = (BarrageModel *)danmaku;
    return model.maxW;
}

- (WBBarrageCell *)danmakuView:(WBBarrageView *)danmakuView cellForDanmaku:(WBBarrageModel *)danmaku {
    BarrageModel *model = (BarrageModel *)danmaku;
    BarrageCell *cell = (BarrageCell *)[danmakuView dequeueReusableCellWithIdentifier:@"cell"];
    cell.selectionStyle = WBBarrageCellSelectionStyleDefault;
    if (model.selfFlag) {
        cell.zIndex = 30;
        cell.layer.borderWidth = 0.5;
        cell.layer.borderColor = [UIColor redColor].CGColor;
    }
    cell.barrageModel = model;
    return cell;
}


@end
