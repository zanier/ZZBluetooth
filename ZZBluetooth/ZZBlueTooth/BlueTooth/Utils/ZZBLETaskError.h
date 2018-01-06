//
//  HCBLETaskError.h
//  ZZBluetooth
//
//  Created by ZZ on 2017/9/21.
//  Copyright © 2017年 HongYun. All rights reserved.
//

#ifndef HCBLETaskError_h
#define HCBLETaskError_h

typedef NS_ENUM(NSInteger, ZZBLEErrorType) {
    
    ZZBLEDidSucceed = 0,
    
    ZZBLECentralNotPowerOn  = 1 << 8,
    ZZBLEWithoutUUID,
    ZZBLEPeriNotConnected,
    ZZBLEChaNotReady,
    ZZScanTimeout,
    ZZConnectTimeout,
    ZZResponseTimeout,

    ZZRequestInvaild,
    ZZResponseInvaild,
};

static NSString *ZZBlueToothErrorDomain = @"ZZBlueToothErrorDomain";
static NSString *ZZResponseErrorDomain  = @"ZZResponseErrorDomain";
static NSString *ZZRequestErrorDomain   = @"ZZRequestErrorDomain";
static NSString *ZZOperateErrorDomain   = @"ZZOperateErrorDomain";

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"
static NSError *ZZErrorWithTaskErrorType(ZZBLEErrorType errorType) {
    if (errorType == ZZBLEDidSucceed) {
        return nil;
    }
    NSString *description = @"unknown error";
    switch (errorType) {
#define caseErrorType(errorType, des)     case errorType: description = des; break;
            caseErrorType(ZZBLEDidSucceed, @"成功")
            
            caseErrorType(ZZBLECentralNotPowerOn, @"蓝牙未开启或开启失败")
            caseErrorType(ZZBLEWithoutUUID, @"UUID为空，无法进行操作")
            caseErrorType(ZZBLEPeriNotConnected, @"蓝牙设备未连接")
            caseErrorType(ZZBLEChaNotReady, @"蓝牙设备特征值未订阅")
            caseErrorType(ZZScanTimeout, @"设备扫描超时")
            caseErrorType(ZZConnectTimeout, @"设备连接超时")
            caseErrorType(ZZResponseTimeout, @"设备响应超时")

            caseErrorType(ZZRequestInvaild, @"无效的蓝牙请求")
            caseErrorType(ZZResponseInvaild, @"无效的蓝牙响应")
#undef caseErrorType
        default:
            break;
    }
    
    return [NSError errorWithDomain:ZZResponseErrorDomain
                               code:errorType
                           userInfo:@{
                                      NSLocalizedDescriptionKey : @"",
                                      NSLocalizedFailureReasonErrorKey : description,
                                      }];
}

#pragma clang diagnostic pop

#endif /* HCBLETaskError_h */
