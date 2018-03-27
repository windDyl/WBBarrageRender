//
//  WBBarrageCell.m
//  WBBarrageRender
//
//  Created by wanba on 2018/3/27.
//  Copyright © 2018年 wanba. All rights reserved.
//

#import "WBBarrageCell.h"

@interface WBBarrageCell ()

@property (nonatomic, strong) NSString *reuseIdentifier;

@end

@implementation WBBarrageCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [self init]) {
        self.reuseIdentifier = reuseIdentifier;
    }
    return self;
}

- (void)prepareForReuse {
    
}

@end
