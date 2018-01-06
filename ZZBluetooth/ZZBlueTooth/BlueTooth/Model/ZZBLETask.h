//
//  HYBLETask.h
//  虹云智慧生活
//
//  Created by ZZ on 2017/9/21.
//  Copyright © 2017年 HongYun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCBLETaskError.h"
#import "ZZBLEResponse.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^ZZBLETaskSuccess)(ZZBLEResponse *response);
typedef void(^ZZBLETaskFailure)(NSError *error);
typedef void(^ZZBLETaskTimeout)(void);

/**
 任务状态

 - ZZBLETaskStateSuspended: 挂起
 - ZZBLETaskStateRunning: 运行中
 - ZZBLETaskStateCanceled: 被取消
 - ZZBLETaskStateCompleted: 完成
 */
typedef NS_ENUM(NSInteger, ZZBLETaskState) {
    ZZBLETaskStateSuspended  = 0,
    ZZBLETaskStateRunning    = 1,
    ZZBLETaskStateCanceled   = 2,
    ZZBLETaskStateCompleted  = 3,
};

@interface ZZBLETask : NSObject

@property (readonly) ZZBLETaskState state;

@property (readonly) NSInteger requestID;

@property (readonly) NSInteger requestCMD;

@property (readonly) NSString *UUIDString;

@end

NS_ASSUME_NONNULL_END
