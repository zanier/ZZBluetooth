//
//  ZZBLEResponseBuffer.m
//  ZZBluetooth
//
//  Created by ZZ on 2017/9/26.
//  Copyright © 2017年 HongYun. All rights reserved.
//

#import "ZZBLEResponseBuffer.h"
#import "ZZBLEConfig.h"

@interface ZZBLEResponseBuffer () {
    NSUInteger _recieveLen;
    NSMutableData *_recieveData;
}

@property (nonatomic, strong) NSMutableArray<ZZBLEResponse *> *responsesArray;

@end

@implementation ZZBLEResponseBuffer

- (instancetype)init {
    if (self = [super init]) {
        [self clearBuffer];
    }
    return self;
}

- (NSMutableArray<ZZBLEResponse *> *)responsesArray {
    if (_responsesArray) {
        return _responsesArray;
    }
    _responsesArray = [NSMutableArray array];
    return _responsesArray;
}

- (void)clearBuffer {
    _recieveData = [NSMutableData data];
    _responsesArray = [NSMutableArray array];
}


- (NSArray<ZZBLEResponse *> *)receiveData:(NSData *)data {
    
    //判断 API
    NSString *hapi = nil;
    if (data && data.length >= _layout.HAPI_length) {
        hapi = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(_layout.HAPI_offset, _layout.HAPI_length)] encoding:NSUTF8StringEncoding];
    }
    
    if ([HAPIString isEqualToString:hapi]) {
        //接收到包头
        //判断 命令码
        Byte *cmd = (Byte *)[[data subdataWithRange:NSMakeRange(_layout.CMD_offset, _layout.CMD_length)] bytes];
        if (*cmd != 0x21) {
            free(cmd);
            cmd = nil;
            return nil;
        }
        _recieveData = [NSMutableData dataWithData:data];
        Byte *byte = (Byte *)[[data subdataWithRange:NSMakeRange(_layout.LEN_offset, _layout.LEN_length)] bytes];
        _recieveLen = (NSUInteger)*byte;
    
    } else {
        
        //接收到负载
        [_recieveData appendData:data];
    }
    
    if (_recieveData.length < _recieveLen + _layout.length) {
        
        // 继续接收负载
        return nil;
        
    }  else {
        
        // 处理完整数据
        ZZBLEResponse *response = [ZZBLEResponse responseWithData:_recieveData];
        self.responsesArray = @[response].mutableCopy;
        return self.responsesArray;
        
    }
}

@end
