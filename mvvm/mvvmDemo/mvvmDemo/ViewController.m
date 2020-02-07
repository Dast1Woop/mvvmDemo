//
//  ViewController.m
//  mvvmDemo
//
//  Created by LongMa on 2020/2/7.
//  Copyright © 2020 huatu. All rights reserved.
/*
需求:
 1.输入文字不能是特定的名字，eg:shit,poop
 2.stepper被点击后，分数显示需要变化;
 3.stepper最多被点击10次，之后隐藏stepper和upload控件
 4.upload按钮最多点击5次，之后隐藏。每次点击都模拟网络请求，延迟弹窗提示:显示名字和分数。
 附加：
 5.新增导航跳转到下一页的需求
*/

#import "ViewController.h"
#import <ReactiveObjC.h>
#import "PersonScoreVM.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *nameTF;
@property (weak, nonatomic) IBOutlet UILabel *scoreLbl;
@property (weak, nonatomic) IBOutlet UIStepper *stepper;
@property (weak, nonatomic) IBOutlet UIButton *uploadBtn;

@property(nonatomic, strong) PersonScoreVM *personVm;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    @weakify(self);
    //新建VM
    PersonScoreVM *lVm = [PersonScoreVM vm];
    self.personVm = lVm;
    
    //绑定
    RAC(self.nameTF, text) = RACObserve(self.personVm, name);
    [[self.nameTF.rac_textSignal distinctUntilChanged] subscribeNext:^(NSString * _Nullable x) {
        @strongify(self);
        self.personVm.name = x;
//        NSLog(@"name changed to:%@", x);
    }];
    
    RAC(self.scoreLbl, text) = [RACObserve(self.personVm, score) map:^id _Nullable(NSNumber *  _Nullable value) {
        return value.description;
    }];
    
    self.stepper.value = self.personVm.score;
    RAC(self.stepper, minimumValue) = RACObserve(self.personVm, minValue);
    RAC(self.stepper, maximumValue) = RACObserve(self.personVm, maxValue);
    RAC(self.stepper, stepValue) = RACObserve(self.personVm, stepNumber);
    
    [[self.stepper rac_signalForControlEvents:UIControlEventValueChanged] subscribeNext:^(__kindof UIStepper * _Nullable x) {
        @strongify(self);
        self.personVm.score = x.value;
    }];
    
    //名字过滤
    [self.personVm.forbiddenNameSignal subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        UIAlertController *lAlertC = [[UIAlertController alloc] init];
        UIAlertAction *lAct = [UIAlertAction actionWithTitle:@"name 非法" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        [lAlertC addAction:lAct];
        [self presentViewController:lAlertC animated:YES completion:^{
            self.nameTF.text = @"";
        }];
    }];
    
}


@end
