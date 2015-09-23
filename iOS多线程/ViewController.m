//
//  ViewController.m
//  iOS多线程
//
//  Created by 马健Jane on 15/8/26.
//  Copyright (c) 2015年 HSC. All rights reserved.
//

#import "ViewController.h"
#import "PMOperation.h"

#define k_dispatch_barrier 0
#define k_dispatch_group 1
#define k_safeThread 0
#define k_operationStart 0
#define k_operationDependencyDemo 0

@interface ViewController ()
@property (nonatomic,strong) NSOperationQueue * operationQueue;

@property (nonatomic,assign) int leftTicketsCount;
@property (nonatomic,strong) NSThread * thread1;
@property (nonatomic,strong) NSThread * thread2;
@property (nonatomic,strong) NSThread * thread3;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    k_operationStart == 0 ? : [self operationStart];
    k_safeThread == 0 ? : [self safeThread]; //需要点击界面
    k_dispatch_group == 0 ? : [self dispatch_group];
    k_dispatch_barrier == 0 ? : [self dispatch_barrier];
    k_operationDependencyDemo == 0 ? : [self operationDependencyDemo];
}

#pragma mark - Operation_Start
#if 1
- (void)operationStart{
    NSBlockOperation * blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"before");
        sleep(2);
        NSLog(@"later");
    }];
    [blockOperation start];  //使用start开启线程而不是加入到operationQueue中，将会在当前线程中同步执行
//    PMOperation * myOperation = [PMOperation new];
//    [myOperation start];
    
    /*这段代码一定要放在operation执行之前，否则会崩溃
    [blockOperation addExecutionBlock:^{
        NSLog(@"execution");
    }];
    */
//    self.operationQueue = [NSOperationQueue new];
//    [self.operationQueue addOperation:blockOperation];
    NSLog(@"hhhhhh");
    

}

#endif

#pragma mark - 线程安全
#if 1
- (void)safeThread{
//默认有20张票
self.leftTicketsCount = 20;
//开个线程，模拟售票员售票
self.thread1 = [[NSThread alloc] initWithTarget:self
                                       selector:@selector(sellTickets)
                                         object:nil];
self.thread1.name = @"售票员A";

self.thread2 = [[NSThread alloc] initWithTarget:self
                                       selector:@selector(sellTickets)
                                         object:nil];
self.thread2.name = @"售票员B";
self.thread3 = [[NSThread alloc] initWithTarget:self
                                       selector:@selector(sellTickets)
                                         object:nil];
self.thread3.name = @"售票员C";
}
- (void)sellTickets{
    while (1) {

        //先检查票数
        @synchronized(self){
        int count = self.leftTicketsCount;
            if (count > 0) {
                //暂停一段时间
                [NSThread sleepForTimeInterval:0.002];
                
                //2.票数 - 1
                self.leftTicketsCount = count - 1;
                
                //获取当前线程
                NSThread * current = [NSThread currentThread];
                NSLog(@"%@--卖了一张票，还剩余%d张票",current,self.leftTicketsCount);
            } else {
                NSThread * current = [NSThread currentThread];
                NSLog(@"%@退出",current);
                [NSThread exit];
            }//end if
        }//end synchronized
    }//end while(1)

}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.thread1 start];
    [self.thread2 start];
    [self.thread3 start];
}

#endif

#pragma mark - Operation_Dependency
#if 1
- (void)operationDependencyDemo{
PMOperation * myOperation = [[PMOperation alloc] init];

NSBlockOperation * blockOperation = [NSBlockOperation blockOperationWithBlock:^{
    NSLog(@"there is blockOperation");
    //        sleep(2);
}];

NSInvocationOperation * invocationOperation = [[NSInvocationOperation alloc] initWithTarget:self
                                                                                   selector:@selector(print:)
                                                                                     object:@"hahah"];

self.operationQueue = [[NSOperationQueue alloc] init];
[self.operationQueue setMaxConcurrentOperationCount:3];

dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [invocationOperation addDependency:blockOperation];
    [blockOperation addDependency:myOperation];
    
    [self.operationQueue addOperation:invocationOperation];
    [self.operationQueue addOperation:blockOperation];
    [self.operationQueue addOperation:myOperation];
});
}
- (void)print:(NSString *)str{
    NSLog(@"%@",str);
    //    sleep(2);
    
    //    NSThread * thread = [NSThread currentThread];
    //    NSLog(@"%@",[thread isMainThread] == YES ? @"YES" : @"NO");
}

#endif


#pragma mark - Dispatch_Barrier
#if 1
- (void)dispatch_barrier{
dispatch_queue_t queue = dispatch_queue_create("com.haoyi.www", DISPATCH_QUEUE_CONCURRENT);
dispatch_async(queue, ^{
    NSLog(@"1");
    //        sleep(2);
});
dispatch_barrier_async(queue, ^{
    NSLog(@"there is a barrier");
    sleep(1);
});
dispatch_async(queue, ^{
    NSLog(@"2");
    //        sleep(2);
});
dispatch_barrier_async(queue, ^{
    NSLog(@"there is a barrier 2 ");
    sleep(1);
});
dispatch_async(queue, ^{
    NSLog(@"3");
    //        sleep(3);
});
}
#endif

#pragma mark - Dispatch_Group
#if 1  //Group
- (void)dispatch_group{
dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
dispatch_group_t group = dispatch_group_create();

dispatch_group_async(group,queue, ^{
    NSLog(@"下载了第1张图片");
});
dispatch_group_async(group,queue, ^{
    sleep(4);
    NSLog(@"下载了第2张图片");
});
dispatch_group_async(group,queue, ^{
    NSLog(@"下载了第3张图片");
});
dispatch_group_notify(group, queue, ^{
    NSLog(@"全部下载完了");
});
}
#endif

@end
