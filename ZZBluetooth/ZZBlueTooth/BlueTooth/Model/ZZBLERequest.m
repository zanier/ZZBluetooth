//
//  ZZBLERequest.m
//  虹云智慧生活
//
//  Created by ZZ on 2017/9/21.
//  Copyright © 2017年 HongYun. All rights reserved.
//

#import "HCBLERequest+Private.h"
#import "HCBLEConfig.h"

NSString *HYMethodNameOfCommand(HCBLEAPICommand cmd) {
#define nameMethod(cmdCase, cmdName) case cmdCase: { return cmdName; }
    switch (cmd) {
            nameMethod(CMD_Invalid, @"无效命令")
            nameMethod(CMD_GET_LOCK_INFO, @"获取门锁信息")
            nameMethod(CMD_GET_VERSION, @"获取版本")
            nameMethod(CMD_CHECK_TIME, @"获取时间基线")
            nameMethod(CMD_GET_LOCK_RECORD, @"获取开门记录")
            nameMethod(CMD_DELETE_LOCK_RECORD, @"删除开门记录")
            nameMethod(CMD_SET_KEY_EXPAIRE_DATE, @"设置钥匙时限")
            nameMethod(CMD_GET_KEY_EXPAIRE_DATE, @"获取钥匙时限")
            
            nameMethod(CMD_SET_KEY_STATUS, @"设置钥匙状态")
            nameMethod(CMD_GET_KEY_STATUS, @"获取钥匙状态")
            nameMethod(CMD_SET_ROTATE_MODE, @"设置电机转动模式")
            nameMethod(CMD_GET_ROTATE_MODE, @"获取电机转动模式")
            nameMethod(CMD_SET_PASSWD_UNLOCK_TIMES, @"设置键盘开锁次数")
            nameMethod(CMD_GET_PASSWD_UNLOCK_TIMES, @"获取键盘开锁次数")
            
            nameMethod(CMD_CREATE_SESSION, @"新建会话")
            nameMethod(CMD_CREATE_KEY, @"创建钥匙")
            nameMethod(CMD_DELETE_KEY, @"删除钥匙")
            nameMethod(CMD_UPDATE_KEY, @"更新钥匙")
            nameMethod(CMD_UNLOCK, @"开锁")
            nameMethod(CMD_GET_BATTERY, @"获取电量")
            nameMethod(CMD_GET_UNLOCK_TIMES, @"？？")
            nameMethod(CMD_RESET, @"重置门锁")
            nameMethod(CMD_CREATE_FINGER_KEY, @"创建指纹钥匙")
            nameMethod(CMD_DELETE_FINGER_KEY, @"删除指纹钥匙")
            nameMethod(CMD_GET_LAST_RESULT, @"获取指纹结果")
            
            nameMethod(CMD_RESPONSE, @"响应")
            
            nameMethod(CMD_CARD_CREATE_KEY, @"创建卡片钥匙")
            nameMethod(CMD_CARD_GET_KEYID, @"获取卡片钥匙号")
            
            nameMethod(CMD_RING_CONFIG_WIFI, @"配置门铃WiFi")
            
            nameMethod(CMD_GATEWAY_CONFIG_WIFI, @"配置WiFi")
            nameMethod(CMD_GATEWAY_CAN_BE_BIND, @"查询可绑状态")
            nameMethod(CMD_GATEWAY_GET_SUB_MAC, @"获取MAC地址")
            
            //nameMethod(CMD_GUARD_WIFI_CONFIG, @"无效命令") //CMD_GATEWAY_CONFIG_WIFI
            nameMethod(CMD_GUARD_GET_NETWORK_STATUS, @"获取网络连接状态")
            
            nameMethod(CMD_AMMETER_DEPOSITE_ELECTRICITY, @"设置电表电量")
            nameMethod(CMD_AMMETER_GET_ELECTRICITY, @"获取电表电量")
            
            //            nameMethod(CMD_CONFIG_GATEWAY_WIFI, @"无效命令")
            nameMethod(CMD_DEVICE_CONNECT, @"无效命令")
            //            nameMethod(CMD_QUERY_BIND_STATUS, @"无效命令") //CMD_GATEWAY_CAN_BE_BIND
            //            nameMethod(CMD_QUERY_WIFI_MAC, @"无效命令") //CMD_GATEWAY_GET_SUB_MAC
            
        default:
            break;
    }
#undef nameMethod
    return @"命令为空";
}

static const unsigned short RequestIDMin = 0x0f;
static const unsigned short RequestIDMax = 0xf0;
static const char zero[8] = {0};

@interface ZZBLERequest ()

@property (nonatomic, strong) NSMutableData *completData;

@property (nonatomic, assign) unsigned short LEN;
@property (nonatomic, assign) unsigned short SUM;
@property (nonatomic, assign) unsigned short CMD;
@property (nonatomic, assign) unsigned short ID;

@property (nonatomic, assign) BOOL appendComplete;

@end

@implementation ZZBLERequest

/**
 生成自加的请求ID
 
 @return 请求ID
 */
+ (unsigned short)currentRequestID {
    static int requestID;
    static dispatch_semaphore_t lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        requestID = RequestIDMin;
        lock = dispatch_semaphore_create(1);
    });
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    requestID += 1;
    if (requestID > RequestIDMax) {
        requestID = RequestIDMin;
    }
    dispatch_semaphore_signal(lock);
    return requestID;
}

+ (instancetype)requestWithLEN:(unsigned short)len
                           SUM:(unsigned short)sum
                           CMD:(unsigned short)cmd
{
    ZZBLERequest *request = [[ZZBLERequest alloc] init];
    [request setHeaderWithLEN:len SUM:sum CMD:cmd];
    return request;
}

- (instancetype)init {
    if (self = [super init]) {
        _appendComplete = NO;
        _ID = [ZZBLERequest currentRequestID];
    }
    return self;
}

- (NSMutableData *)completData {
    if (!_completData) {
        _completData = [NSMutableData dataWithLength:8];
    }
    return _completData;
}

// 我来组成头部
- (void)setHeaderWithLEN:(unsigned short)len
                     SUM:(unsigned short)sum
                     CMD:(unsigned short)cmd {
    _LEN = len;
    _SUM = sum;
    _CMD = cmd;
    
    // 长度：8字节
    [self.completData resetBytesInRange:NSMakeRange(0, 8)];
    // "HAPI"
    [self.completData replaceBytesInRange:NSMakeRange(_layout.HAPI_offset, _layout.HAPI_length)
                                withBytes:[[HAPIString dataUsingEncoding:NSUTF8StringEncoding] bytes]];
    // 负载长度
    [self.completData replaceBytesInRange:NSMakeRange(_layout.LEN_offset, _layout.LEN_length)
                                withBytes:&_LEN];
    // 校验和
    [self.completData replaceBytesInRange:NSMakeRange(_layout.SUM_offset, _layout.SUM_length)
                                withBytes:&_SUM];
    // 命令码
    [self.completData replaceBytesInRange:NSMakeRange(_layout.CMD_offset, _layout.CMD_length)
                                withBytes:&_CMD];
    // ID号
    [self.completData replaceBytesInRange:NSMakeRange(_layout.ID_offset, _layout.ID_length)
                                withBytes:&_ID];
}

- (void)appendMsgData:(NSData *)msgData {
    [self.completData appendData:msgData];
}

- (void)completeAppending {
    if (_appendComplete) {
        return;
    }
    _appendComplete = YES;
    
    _LEN = self.completData.length - 8;
    // 负载长度
    [self.completData replaceBytesInRange:NSMakeRange(_layout.LEN_offset, _layout.LEN_length)
                                withBytes:&_LEN];

    NSUInteger pakageLen = 8;
    NSUInteger count = pakageLen - (self.completData.length % pakageLen);
    if (count != 0) {
        [self.completData appendBytes:&zero length:count];
    }
}

- (NSString *)methodDesaription {
    return HYMethodNameOfCommand(self.CMD);
}

@end


