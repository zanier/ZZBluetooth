//
//  ZZBLEConnection+Private.h
//  ZZBluetooth
//
//  Created by ZZ on 2017/10/9.
//  Copyright © 2017年 zz. All rights reserved.
//

#import "ZZBLEConnection.h"
#import "ZZBLETask+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZZBLEConnection () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, assign) NSTimeInterval connectInterval;

@property (nonatomic, copy) ZZBLEConnectSuccess connectSuccess;
@property (nonatomic, copy) ZZBLEConnectFailure connectFailure;
@property (nonatomic, copy) ZZBLEConnectTimeout connectTimeout;
@property (nonatomic, copy) ZZBLEDidReadRSSI didReadRSSI;

+ (instancetype)connectionWithCentral:(CBCentralManager *)central
                           peripheral:(CBPeripheral *)peripheral;

- (void)connect;
- (void)disconnect;

- (void)dispatchTask:(ZZBLETask *)task;
- (void)cancelTask:(ZZBLETask *)task;

@end

NS_ASSUME_NONNULL_END
