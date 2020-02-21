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

@property(nonatomic, strong) RACSignal *uploadBtnEnableSignal;

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

- (RACCommand *)uploadBtnDCCmd{
    if (nil == _uploadBtnDCCmd) {
       _uploadBtnDCCmd =  [[RACCommand alloc] initWithEnabled:self.uploadBtnEnableSignal signalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
              //上传网络请求
              return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
                  BOOL testSuc = YES;
                  
                  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                      if (testSuc) {
                          [subscriber sendNext:@"suc"];
                          [subscriber sendCompleted];
                      }else{
                          NSError *lErr = [NSError errorWithDomain:@"upload err" code:400 userInfo:nil];
                          [subscriber sendError:lErr];
                      }
                  });
                  
                  return nil;
              }];
          }];
    }
    return _uploadBtnDCCmd;
}

//- (void)uploadBtnDC:(id)btn{
//    self.uploadCrtTimes += 1;
//    NSLog(@"网络请求中。。。");
//
//    //模拟网络请求，提示上传成功
//    [[RACScheduler scheduler] afterDelay:2 schedule:^{
//         NSLog(@"网络请求suc");
//
//        [[RACScheduler mainThreadScheduler] schedule:^{
//            [self.uploadSucSubject sendNext:@1];
//        }];
//    }];
//}

- (RACSignal *)uploadBtnEnableSignal{
    return [RACObserve(self, person.name) filter:^BOOL(NSString *  _Nullable value) {
        return value.length > 3;
    }];
}

- (RACSignal *)uploadBtnHiddenSignal{
    return [RACObserve(self, uploadCrtTimes) filter:^BOOL(NSNumber *  _Nullable value) {
        return value.intValue >= 3;
    }];
}

@end
