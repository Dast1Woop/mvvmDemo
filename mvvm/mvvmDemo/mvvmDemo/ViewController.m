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
    
    [self testRAC];
    
    @weakify(self);
    //新建VM
    PersonScoreVM *lVm = [PersonScoreVM vm];
    self.personVm = lVm;
    
    //双向绑定❌方法一(缺点：通过代码更改tf的text时，vm属性不会被更新)：
    //    RAC(self.nameTF, text) = RACObserve(self.personVm, person.name);
    //    RAC(self.personVm, person.name) = self.nameTF.rac_textSignal;
    
    //双向绑定❌方法二:会导致程序崩溃
    //    RAC(self.nameTF, text) = RACObserve(self.personVm, person.name);
    //    RAC(self.personVm, person.name) = self.nameTF.rac_textSignal;
    //    [RACObserve(self.nameTF, text) subscribeNext:^(id  _Nullable x) {
    //        self.personVm.person.name = x;
    //    }];
    
    //双向绑定❌方法三（stackoverflow方法，问题同上面方法一）：
    //    [
    //     [self.nameTF.rac_newTextChannel
    //      skip:1]
    //     subscribe:RACChannelTo(self.personVm,person.name)];
    //     [RACChannelTo(self.personVm,person.name) subscribe:self.nameTF.rac_newTextChannel];
    
    //双向绑定✅方法（实测 RACChannelTo 法，在iOS9+没问题）,但前提是触发属性的KVO机制才能实现。
    RACChannelTo(self.personVm,person.name) = RACChannelTo(self.nameTF,text);
  //网上说iOS9有问题。通过键盘输入无法更新vm属性。如需支持iOS9，需要订阅rac_textSignal更新vm属性
    [self.nameTF.rac_textSignal subscribeNext:^(NSString * _Nullable x) {
        self.personVm.person.name = x;
    }];
    
    self.nameTF.text = @"test";
    NSLog(@"vm name:%@", self.personVm.person.name);
    
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
    
    self.uploadBtn.rac_command = self.personVm.uploadBtnDCCmd;
//    [[self.uploadBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
//        [self.personVm.uploadBtnDCCmd execute:nil];
//    }];
    
//    [
     [[self.personVm.uploadBtnDCCmd executionSignals]
//      switchToLatest]
      subscribeNext:^(RACSignal *  _Nullable x) {
        NSLog(@"uploading...,name:%@", self.personVm.person.name);
        [x subscribeNext:^(id  _Nullable x) {
            NSLog(@"up suc");
        }];
    }];
    
    //This will send YES whenever -execute: is invoked and the created signal has not yet terminated. Once all executions have terminated, `executing` will send NO.
       [self.personVm.uploadBtnDCCmd.executing subscribeNext:^(NSNumber * _Nullable x) {
           NSLog(@"uploadBtnDCCmd is executing:%@",x);
       }];
    
    //flatten：直接获取内容;switchToLatest也行
    [[[self.personVm.uploadBtnDCCmd executionSignals] flatten] subscribeNext:^(id  _Nullable x) {
        NSLog(@"flattened : %@", x);
    }];
    [self.personVm.uploadBtnDCCmd.errors subscribeNext:^(NSError * _Nullable x) {
        NSLog(@"up error");
    }];
    
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

#pragma mark -  test
- (void)testRAC{
    
//    [self takeUntil];
//    [self testSubject];
//    [self testPublishConnect];
    [self testReplay];
//    [self testReplayLazily];
//    [self testReplayLast];
    
//    [self testGesture];
//    [self testRACCommand];
    
//    [self testSequecce];
//    [self testTimeOut];
}

//Sends an error after `interval` seconds if the source doesn't complete before then.
- (void)testTimeOut {
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"100"];
//        [subscriber sendCompleted];
//        [subscriber sendError:nil];
        return nil;
    }] timeout:1 onScheduler: [RACScheduler currentScheduler]]; // 这里将时间操作放在当前线程中执行
    
    [signal subscribeNext:^(id x) {
        NSLog(@"%@",x);
    } error:^(NSError *error) {
        NSLog(@"1秒后会自动调用?");
    }];
}

- (void)testRACCommand{
    RACCommand *lCmd = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(NSNumber *  _Nullable input) {
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> subscriber) {
            [subscriber sendNext:input];
            [subscriber sendCompleted];
            return nil;
        }];
    }];
    
    [lCmd execute:@1];
    [[lCmd.executionSignals switchToLatest] subscribeNext:^(id  _Nullable x) {
        NSLog(@"cmd log: %@",x);
    }];
    [lCmd  execute:@2];
    //1和2不会被log！因为订阅前的1肯定无法log。2执行时，会受到1的影响（去掉1，可打印2）。
    [[RACScheduler mainThreadScheduler] afterDelay:1 schedule:^{
        [lCmd execute:@3];
    }];
}

- (void)testSequecce{
    NSArray *lArr = @[@1, @2, @3];
    [lArr.rac_sequence.signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"x=%@", x);
    }];
    
    NSDictionary *lDic = @{@1 : @11,
                           @2 : @22,
                           @3 : @33
    };
    [lDic.rac_sequence.signal subscribeNext:^(RACTuple*  _Nullable x) {
//        NSLog(@"dic:%@",x);
        RACTupleUnpack(NSNumber *key, NSNumber *value) = x;
        NSLog(@"key:%@,v:%@", key, value);
    }];
}

- (void)testGesture{
    UITapGestureRecognizer *lTapG = [[UITapGestureRecognizer alloc] init];
    [lTapG.rac_gestureSignal subscribeNext:^(__kindof UITapGestureRecognizer * _Nullable x) {
        NSLog(@"lTapG:%@", x);
    }];
    [self.view addGestureRecognizer:lTapG];
}

- (void)testReplayLast{
    RACSignal *lSig = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
              NSLog(@"sig 内部开始执行");
              [[RACScheduler mainThreadScheduler] afterDelay:1 schedule:^{
                  [subscriber sendNext:@1];
              }];
              
              [[RACScheduler mainThreadScheduler] afterDelay:2 schedule:^{
                  [subscriber sendNext:@2];
              }];
              
              [[RACScheduler mainThreadScheduler] afterDelay:3 schedule:^{
                  [subscriber sendNext:@3];
              }];
              [[RACScheduler mainThreadScheduler] afterDelay:4 schedule:^{
                  [subscriber sendCompleted];
              }];
              return nil;
          }];
    
    [[RACScheduler mainThreadScheduler] afterDelay:0.1 schedule:^{
        RACSignal *lSigTemp = lSig.replayLast;
        
        //replayLast：能收到最后一条历史消息。
        [[RACScheduler mainThreadScheduler] afterDelay:3.5 schedule:^{
            [lSigTemp subscribeNext:^(id  _Nullable x) {
                NSLog(@"3.5:%@",x);
            }];
        }];
        
        [[RACScheduler mainThreadScheduler] afterDelay:5 schedule:^{
            [lSigTemp subscribeNext:^(id  _Nullable x) {
                NSLog(@"5:%@",x);
            }];
        }];
        
        [[RACScheduler mainThreadScheduler] afterDelay:8 schedule:^{
            [lSigTemp subscribeNext:^(id  _Nullable x) {
                NSLog(@"8:%@",x);
            }];
        }];
    }];
}

- (void)testReplayLazily{
    RACSignal *lSig = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
           NSLog(@"sig 内部开始执行");
           [[RACScheduler mainThreadScheduler] afterDelay:1 schedule:^{
               [subscriber sendNext:@1];
           }];
           
           [[RACScheduler mainThreadScheduler] afterDelay:2 schedule:^{
               [subscriber sendNext:@2];
           }];
           
           [[RACScheduler mainThreadScheduler] afterDelay:3 schedule:^{
               [subscriber sendNext:@3];
           }];
           [[RACScheduler mainThreadScheduler] afterDelay:4 schedule:^{
               [subscriber sendCompleted];
           }];
           return nil;
       }];
    
    [[RACScheduler mainThreadScheduler] afterDelay:0.1 schedule:^{
        RACSignal *lSigTemp = lSig.replayLazily;
        
        //replay!so 能收到 所有 消息。
        [[RACScheduler mainThreadScheduler] afterDelay:3.5 schedule:^{
            [lSigTemp subscribeNext:^(id  _Nullable x) {
                NSLog(@"3.5:%@",x);
            }];
        }];
        
        [[RACScheduler mainThreadScheduler] afterDelay:5 schedule:^{
            [lSigTemp subscribeNext:^(id  _Nullable x) {
                NSLog(@"5:%@",x);
            }];
        }];
        
        [[RACScheduler mainThreadScheduler] afterDelay:8 schedule:^{
            [lSigTemp subscribeNext:^(id  _Nullable x) {
                NSLog(@"8:%@",x);
            }];
        }];
    }];
    
}

- (void)testPublishConnect{
    RACSignal *lSig = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        NSLog(@"sig 内部开始执行");
        [[RACScheduler mainThreadScheduler] afterDelay:1 schedule:^{
            [subscriber sendNext:@1];
        }];
        
        [[RACScheduler mainThreadScheduler] afterDelay:2 schedule:^{
            [subscriber sendNext:@2];
        }];
        
        [[RACScheduler mainThreadScheduler] afterDelay:3 schedule:^{
            [subscriber sendNext:@3];
        }];
        [[RACScheduler mainThreadScheduler] afterDelay:4 schedule:^{
            [subscriber sendCompleted];
        }];
        return nil;
    }];
    
    //把冷信号变为热信号2步法：发布，连接！简称“发姐”！两步骤写一起，防止忘记连接！
    //冷信号 经过 发姐 后，变成了 热信号！
    RACMulticastConnection *lCnt = [lSig publish];
    [lCnt connect];
    
    RACSignal *lSigHot = lCnt.signal;
    [[RACScheduler mainThreadScheduler] afterDelay:1.1 schedule:^{
        [lSigHot subscribeNext:^(id  _Nullable x) {
            NSLog(@"1:%@",x);
        }];
    }];
    
    [[RACScheduler mainThreadScheduler] afterDelay:2.1 schedule:^{
        [lSigHot subscribeNext:^(id  _Nullable x) {
            NSLog(@"2:%@",x);
        }];
    }];
    
    //5s时，codeSig已经发送完成，此热信号没有replay功能，故订阅后搜不到消息。
    [[RACScheduler mainThreadScheduler] afterDelay:5 schedule:^{
        [lSigHot subscribeNext:^(id  _Nullable x) {
            NSLog(@"5:%@",x);
        }];
    }];
}

- (void)testSubject{
    
    //热信号
    RACSubject *lSub = [RACSubject subject];

    [lSub sendNext:@1];
    [lSub sendNext:@2];
    [lSub sendNext:@3];
    [lSub subscribeNext:^(id  _Nullable x) {
         NSLog(@"RACSubject1:%@", x);
     }];
    [lSub sendNext:@4];
    
    [lSub subscribeNext:^(id  _Nullable x) {
            NSLog(@"RACSubject2:%@", x);
        }];
   [lSub sendNext:@5];
    
}

- (void)testReplay{
    __block int i = 0;
    RACSignal *lSig = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:[NSString stringWithFormat:@"《%@-%d》",@"电影", i]];
        i++;
        
        [[RACScheduler mainThreadScheduler] afterDelay:1 schedule:^{
            [subscriber sendNext:@"1s后发的内容"];
            
            //如果放到延迟外面和后面，会导致此闭包内代码无法被收到，因为信号已经发布完成了！
            [subscriber sendCompleted];
        }];

        return nil;
    }];
    
    [lSig subscribeNext:^(id  _Nullable x) {
         NSLog(@"小1 看了%@",x);
     }];

     [lSig subscribeNext:^(id  _Nullable x) {
         NSLog(@"小2 看了%@",x);
     }];
    
    RACSignal *lS = lSig.replay;

    [lS subscribeNext:^(id  _Nullable x) {
        NSLog(@"小3 看了%@",x);
    }];

    [lS subscribeNext:^(id  _Nullable x) {
        NSLog(@"小4 看了%@",x);
    }];
    
    [[RACScheduler mainThreadScheduler] afterDelay:2 schedule:^{
      [lS subscribeNext:^(id  _Nullable x) {
            NSLog(@"2s后，小5 看了%@",x);
        }];
    }];
}

- (void)takeUntil{
    [
     [
      [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [[RACSignal interval:1 onScheduler:[RACScheduler mainThreadScheduler]] subscribeNext:^(id _Nullable x) {
            [subscriber sendNext:@"直到世界尽头才能把我们分开"];
        }];
        return nil;
    }]
      takeUntil:
      [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            NSLog(@"世界尽头了");
            [subscriber sendNext:@"世界尽头了xxxx"];
        });
        return nil;
    }]
      ]
     subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@", x);
    }];
}

@end
