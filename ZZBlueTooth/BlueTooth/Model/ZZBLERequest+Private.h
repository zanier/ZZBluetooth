//
//  ZZBLERequest+Private.h
//  ZZBluetooth
//
//  Created by ZZ on 2017/10/9.
//  Copyright © 2017年 zz. All rights reserved.
//

#import "ZZBLERequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZZBLERequest ()

+ (instancetype)requestWithLEN:(unsigned short)len
                           SUM:(unsigned short)sum
                           CMD:(unsigned short)cmd;

- (NSMutableData *)completData;

- (void)appendMsgData:(NSData *)msgData;

- (void)completeAppending;

@end

NS_ASSUME_NONNULL_END
