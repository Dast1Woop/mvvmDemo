//
//  PersonScoreVM.h
//  mvvmDemo
//
//  Created by LongMa on 2020/2/7.
//  Copyright © 2020 huatu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveObjC.h>
#import "PersonM.h"
NS_ASSUME_NONNULL_BEGIN

@interface PersonScoreVM : NSObject

@property(nonatomic, strong) PersonM* person;

//stepper
@property(nonatomic, assign) double minValue;
@property(nonatomic, assign) double maxValue;
@property(nonatomic, assign) double stepNumber;

@property(nonatomic, assign) double scoreChangedCrtTimes;

//上传成功 代理
@property(nonatomic, strong) RACSubject *uploadSucSubject;

@property(nonatomic, strong) RACCommand *uploadBtnDCCmd;

//验证逻辑:
//名字是否有效
- (RACSignal *)forbiddenNameSignal;

//stepper是否隐藏
- (RACSignal *)stepperNeedsHiddenSignal;

//upload按钮是否隐藏
- (RACSignal *)uploadBtnHiddenSignal;

+ (instancetype)vm;


@end

NS_ASSUME_NONNULL_END
