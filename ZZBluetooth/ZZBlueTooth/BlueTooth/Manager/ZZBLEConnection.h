//
//  ZZBLEConnection.h
//  ZZBluetooth
//
//  Created by ZZ on 2017/9/21.
//  Copyright © 2017年 HongYun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZZBLEConnection : NSObject

@property (readonly) NSString *UUIDString;

@property (readonly) CBPeripheralState state;

@end

NS_ASSUME_NONNULL_END
