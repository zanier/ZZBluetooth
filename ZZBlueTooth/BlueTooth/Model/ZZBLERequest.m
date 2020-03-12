//
//  ZZBLERequest.m
//  ZZBluetooth
//
//  Created by ZZ on 2017/9/21.
//  Copyright © 2017年 HongYun. All rights reserved.
//

#import "ZZBLERequest+Private.h"
#import "ZZBLEConfig.h"

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
    return nil;
}

@end


