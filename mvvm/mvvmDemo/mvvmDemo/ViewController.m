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
 3.stepper最多被点击5次，之后隐藏stepper控件
 4.upload按钮最多点击3次，之后隐藏。每次点击都模拟网络请求，延迟弹窗提示:显示名字和分数。
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
    self.title = @"信息";
    
    @weakify(self);
    //新建VM
    PersonScoreVM *lVm = [PersonScoreVM vm];
    self.personVm = lVm;
    
    //绑定
    RAC(self.nameTF, text) = RACObserve(self.personVm, person.name);
    [[self.nameTF.rac_textSignal distinctUntilChanged] subscribeNext:^(NSString * _Nullable x) {
        @strongify(self);
        self.personVm.person.name = x;
        //        NSLog(@"name changed to:%@", x);
    }];
    
    RAC(self.scoreLbl, text) = [RACObserve(self.personVm.person, score) map:^id _Nullable(NSNumber *  _Nullable value) {
        return value.description;
    }];
    
    self.stepper.value = self.personVm.person.score;
    RAC(self.stepper, minimumValue) = RACObserve(self.personVm, minValue);
    RAC(self.stepper, maximumValue) = RACObserve(self.personVm, maxValue);
    RAC(self.stepper, stepValue) = RACObserve(self.personVm, stepNumber);
    
    [[self.stepper rac_signalForControlEvents:UIControlEventValueChanged] subscribeNext:^(__kindof UIStepper * _Nullable x) {
        @strongify(self);
        self.personVm.person.score = x.value;
        self.personVm.scoreChangedCrtTimes += 1;
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
    
    //3.stepper最多被点击5次，之后隐藏stepper和upload控件
    [self.personVm.stepperNeedsHiddenSignal subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        self.stepper.hidden = YES;
    }];
    
    [self.uploadBtn addTarget:self.personVm action:@selector(uploadBtnDC:) forControlEvents:(UIControlEventTouchUpInside)];
    
    [self.personVm.uploadSucSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self uploadMsgSuc:x];
    }];
    
    [self.personVm.uploadBtnHiddenSignal subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        self.uploadBtn.hidden = YES;
    }];
}

- (void)uploadMsgSuc:(id)btn{
    UIAlertController *lAlertC = [[UIAlertController alloc] init];
    NSString *lMsg = [NSString stringWithFormat:@"upload suc:%@,%.1f", self.personVm.person.name, self.personVm.person.score];
    UIAlertAction *lAct = [UIAlertAction actionWithTitle:lMsg  style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [lAlertC addAction:lAct];
    
    [self presentViewController:lAlertC animated:YES completion:^{
    }];
}

- (IBAction)nextPageItemDC:(id)sender {
    UIViewController *lVC = [[UIViewController alloc] init];
    lVC.view.backgroundColor = [UIColor yellowColor];
    [self.navigationController pushViewController:lVC animated:YES];
}

@end
