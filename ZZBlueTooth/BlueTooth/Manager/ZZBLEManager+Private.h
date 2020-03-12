//
//  ZZBLEManager+Private.h
//  ZZBluetooth
//
//  Created by ZZ on 2017/10/9.
//  Copyright © 2017年 zz. All rights reserved.
//

#import "ZZBLEManager.h"
#import "ZZBLETask.h"

#ifdef DEBUG
    #define ZZLog(...)     \
        if ([ZZBLEManager shareInstance].logEnable) {\
            NSLog(@"[ZZBLE] %@", [NSString stringWithFormat:__VA_ARGS__]);\
        }
#else
    #define ZZLog(...)
#endif

@interface ZZBLEManager ()

- (void)dispatchTask:(ZZBLETask *)task;

- (void)cancelTask:(ZZBLETask *)task;

@end
