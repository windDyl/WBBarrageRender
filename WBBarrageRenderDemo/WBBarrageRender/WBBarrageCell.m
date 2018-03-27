//
//  WBBarrageCell.m
//  WBBarrageRender
//
//  Created by wanba on 2018/3/27.
//  Copyright © 2018年 wanba. All rights reserved.
//

#import "WBBarrageCell.h"

@interface WBBarrageCell ()
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) NSString *reuseIdentifier;

@end

@implementation WBBarrageCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super init]) {
        self.reuseIdentifier = reuseIdentifier;
    }
    return self;
}

- (void)prepareForReuse {
    
}

- (UILabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] init];
        _textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_textLabel];
    }
    return _textLabel;
}

@end
