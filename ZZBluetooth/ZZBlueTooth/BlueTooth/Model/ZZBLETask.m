//
//  ZZBLETask.m
//  ZZBluetooth
//
//  Created by ZZ on 2017/9/21.
//  Copyright © 2017年 HongYun. All rights reserved.
//

#import "ZZBLETask+Private.h"
#import "ZZBLETaskError.h"
#import "ZZBLETimer.h"
#import "ZZBLEConfig.h"

@interface ZZBLETask ()

@property (nonatomic, copy) NSString *UUIDString;

@property (nonatomic, strong) ZZBLETimer *timeoutTimer;

@property (nonatomic, assign) ZZBLETaskState state;

@property (nonatomic, copy) ZZBLETaskSuccess taskSuccess;
@property (nonatomic, copy) ZZBLETaskFailure taskFailure;
@property (nonatomic, copy) ZZBLETaskTimeout taskTimeout;

@end

@implementation ZZBLETask

+ (instancetype)taskWithRequest:(ZZBLERequest *)request UUIDString:(NSString *)UUIDString {
    ZZBLETask *task = [[ZZBLETask alloc] init];
    task.state = ZZBLETaskStateSuspended;
    task.UUIDString = UUIDString;
    task.request = request;
    [task.request completeAppending];
    return task;
}

+ (instancetype)taskWithRequest:(ZZBLERequest *)request
                     UUIDString:(NSString *)UUIDString
                    taskSuccess:(ZZBLETaskSuccess)taskSuccess
                    taskFailure:(ZZBLETaskFailure)taskFailure
                    taskTimeout:(ZZBLETaskTimeout)taskTimeout
{
    ZZBLETask *task = [ZZBLETask taskWithRequest:request UUIDString:UUIDString];
    task.taskSuccess = taskSuccess;
    task.taskFailure = taskFailure;
    task.taskTimeout = taskTimeout;
    return task;
}

#pragma mark -

- (NSInteger)requestID {
    return self.request.ID;
}

- (NSInteger)requestCMD {
    return self.request.CMD;
}

- (void)resume {
    
    if (self.state != ZZBLETaskStateSuspended) {
        return;
    }
    self.state = ZZBLETaskStateRunning;
    
    [self stopTimer];
    // 开启超时定时器
    NSTimeInterval timeoutInterval = (self.timeoutInterval > 0) ? self.timeoutInterval : ZZBLEDefaulTaskInterval;
    
    self.timeoutTimer = [ZZBLETimer timerWithTimeInterval:timeoutInterval
                                                   target:self
                                                 selector:@selector(taskDidTimeout:)
                                                  repeats:NO];
    
}

- (void)cancel {
    if (self.state <= ZZBLETaskStateRunning) {
        return;
    }
    self.state = ZZBLETaskStateCanceled;
}

- (void)stopTimer {
    if (self.timeoutTimer) {
        [self.timeoutTimer invalidate];
        self.timeoutTimer = nil;
        self.taskTimeout = nil;
    }
}

#pragma mark -

- (void)getResponse:(ZZBLEResponse *)response {
    
    _state = ZZBLETaskStateCompleted;
    [self stopTimer];
    self.taskCompletion ? self.taskCompletion() : nil;

    if (response.isSucceeded) {
        self.taskSuccess ? self.taskSuccess(response) : nil;
    } else {
        self.taskFailure ? self.taskFailure(response.error) : nil;
    }
    self.taskSuccess = nil;
    self.taskFailure = nil;
    self.taskTimeout = nil;
    
}

- (void)taskDidFaildWithError:(NSError *)error {
    [self stopTimer];
    _state = ZZBLETaskStateCompleted;
    self.taskCompletion ? self.taskCompletion() : nil;
    self.taskFailure ? self.taskFailure(error) : nil;
    self.taskSuccess = nil;
    self.taskFailure = nil;
    self.taskTimeout = nil;
}

- (void)taskDidTimeout:(NSTimer *)timer {
    if (_state > ZZBLETaskStateRunning) {
        return;
    }
    _state = ZZBLETaskStateCanceled;
    self.taskCompletion ? self.taskCompletion() : nil;
    self.taskTimeout ? self.taskTimeout() : nil;
    [self stopTimer];
    self.taskSuccess = nil;
    self.taskFailure = nil;
    self.taskTimeout = nil;
}

@end
