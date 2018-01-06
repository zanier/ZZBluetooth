//
//  ZZBLEResponseBuffer.h
//  ZZBluetooth
//
//  Created by ZZ on 2017/9/26.
//  Copyright © 2017年 HongYun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZZBLEResponse.h"

@interface ZZBLEResponseBuffer : NSObject

- (void)clearBuffer;

- (NSArray<ZZBLEResponse *> *)receiveData:(NSData *)data;

@end
