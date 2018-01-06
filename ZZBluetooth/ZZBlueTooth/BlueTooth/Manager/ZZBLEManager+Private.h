//
//  HCBLEManager+Private.h
//  ZZBluetooth
//
//  Created by ZZ on 2017/10/9.
//  Copyright © 2017年 zz. All rights reserved.
//

#import "HCBLEManager.h"
#import "ZZBLETask.h"

#ifdef DEBUG
    #define HCLog(...)     \
        if ([HCBLEManager shareInstance].logEnable) {\
            NSLog(@"[HCBLE] %@", [NSString stringWithFormat:__VA_ARGS__]);\
        }
#else
    #define HCLog(...)
#endif

@interface HCBLEManager ()

- (void)dispatchTask:(ZZBLETask *)task;

- (void)cancelTask:(ZZBLETask *)task;

@end
