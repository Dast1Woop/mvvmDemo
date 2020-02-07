//
//  PersonScoreVM.m
//  mvvmDemo
//
//  Created by LongMa on 2020/2/7.
//  Copyright © 2020 huatu. All rights reserved.
//

#import "PersonScoreVM.h"

@interface PersonScoreVM ()
@property(nonatomic, copy) NSArray *forbiddenNamesArr;

@end

@implementation PersonScoreVM

+ (instancetype)vm{
    return [[self alloc] init];
}

- (instancetype)init{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    [self resetProperties];
    return self;
}

- (void)resetProperties{
    self.name = @"myl";
    self.score = 100;
    self.minValue = 0;
    self.maxValue = 200;
    self.stepNumber = 10;
    
    self.forbiddenNamesArr = @[@"shit", @"poop"];
}

- (RACSignal *)forbiddenNameSignal{
    return [[RACObserve(self, name) distinctUntilChanged]
            filter:^BOOL(NSString*  _Nullable value) {
        return [self.forbiddenNamesArr containsObject:value];
    }];
}

@end
