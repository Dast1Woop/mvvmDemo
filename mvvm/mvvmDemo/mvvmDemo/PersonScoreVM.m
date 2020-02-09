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
@property(nonatomic, assign) double uploadCrtTimes;

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
    self.person = [[PersonM alloc] init];
    self.person.name = @"myl";
    self.person.score = 100;
    self.minValue = 0;
    self.maxValue = 600;
    self.stepNumber = 5;
    
    self.forbiddenNamesArr = @[@"shit", @"poop"];
    self.scoreChangedCrtTimes = 0;
    self.uploadCrtTimes = 0;
    
    self.uploadSucSubject = [RACSubject subject];
}

- (RACSignal *)forbiddenNameSignal{
    return [[RACObserve(self.person, name) distinctUntilChanged]
            filter:^BOOL(NSString*  _Nullable value) {
        return [self.forbiddenNamesArr containsObject:value];
    }];
}

//scoreChangedCrtTimes变化5次后，触发此信号
- (RACSignal *)stepperNeedsHiddenSignal{
    return [[RACObserve(self, scoreChangedCrtTimes) distinctUntilChanged] filter:^BOOL(NSNumber *  _Nullable value) {
        return value.intValue >= 5;
    }];
}

- (void)uploadBtnDC:(id)btn{
    self.uploadCrtTimes += 1;
    NSLog(@"网络请求中。。。");
    
    //模拟网络请求，提示上传成功
    [[RACScheduler scheduler] afterDelay:2 schedule:^{
         NSLog(@"网络请求suc");
        
        [[RACScheduler mainThreadScheduler] schedule:^{
            [self.uploadSucSubject sendNext:@1];
        }];
    }];
}

- (RACSignal *)uploadBtnHiddenSignal{
    return [RACObserve(self, uploadCrtTimes) filter:^BOOL(NSNumber *  _Nullable value) {
        return value.intValue >= 3;
    }];
}

@end
