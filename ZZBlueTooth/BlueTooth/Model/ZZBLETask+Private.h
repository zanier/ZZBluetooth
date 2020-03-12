//
//  ZZBLETask+Private.h
//  ZZBluetooth
//
//  Created by ZZ on 2017/10/9.
//  Copyright © 2017年 zz. All rights reserved.
//

#import "ZZBLETask.h"
#import "ZZBLEResponse.h"
#import "ZZBLERequest+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZZBLETask ()

@property (nonatomic, strong) ZZBLERequest *request;

@property (nonatomic, assign) NSTimeInterval timeoutInterval;

@property (nonatomic, copy) void (^taskCompletion)(void);

+ (instancetype)taskWithRequest:(ZZBLERequest *)request
                     UUIDString:(NSString *)UUIDString
                    taskSuccess:(ZZBLETaskSuccess)taskSuccess
                    taskFailure:(ZZBLETaskFailure)taskFailure
                    taskTimeout:(ZZBLETaskTimeout)taskTimeout;

- (void)resume;
- (void)cancel;

- (void)getResponse:(ZZBLEResponse *)response;
- (void)taskDidFaildWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
