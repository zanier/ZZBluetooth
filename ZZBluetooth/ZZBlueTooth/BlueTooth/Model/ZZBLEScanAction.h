//
//  ZZBLEScanAction.h
//  ZZBluetooth
//
//  Created by ZZ on 2017/9/25.
//  Copyright © 2017年 HongYun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "ZZBLEManager+Private.h"
#import "ZZBLEConfig.h"

@class ZZBLEScanAction;

NS_ASSUME_NONNULL_BEGIN

@protocol ZZBLEScanTaskDelegate <NSObject>

- (void)scanTaskDidFinishScan:(ZZBLEScanAction *)task discovered:(BOOL)didDiscover;

@end

@interface ZZBLEScanAction : NSObject

@property (nonatomic, weak) id<ZZBLEScanTaskDelegate> delegate;

@property (nonatomic, assign) BOOL duplicate;

@property (nonatomic, assign) NSTimeInterval scanInterval;

@property (nullable, nonatomic, copy) NSString *targetName;

@property (nullable, nonatomic, copy) ZZBLEScanDidDiscover scanDidDiscover;
@property (nullable, nonatomic, copy) ZZBLEScanDidFinish scanDidFinsh;

@property (nonatomic, assign) BOOL didDiscover;

@property (readonly) BOOL taskIsValid;

- (void)startScanTimer;

- (void)stopScanTimer;

- (void)callTimeout;

@end

NS_ASSUME_NONNULL_END
