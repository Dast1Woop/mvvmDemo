//
//  PersonScoreVM.h
//  mvvmDemo
//
//  Created by LongMa on 2020/2/7.
//  Copyright © 2020 huatu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveObjC.h>

NS_ASSUME_NONNULL_BEGIN

@interface PersonScoreVM : NSObject

@property(nonatomic, copy) NSString *name;

//stepper
@property(nonatomic, assign) double score;
@property(nonatomic, assign) double minValue;
@property(nonatomic, assign) double maxValue;
@property(nonatomic, assign) double stepNumber;

//todo:id改为UIButton？此时，需要导入UIKit
- (void)uploadBtnDC:(id)btn;

//验证逻辑:
//名字是否有效
- (RACSignal *)forbiddenNameSignal;

//stepper是否隐藏

//stepper和upload按钮是否隐藏


+ (instancetype)vm;


@end

NS_ASSUME_NONNULL_END
