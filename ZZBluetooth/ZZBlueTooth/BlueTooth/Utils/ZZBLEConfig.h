//
//  HCBLEConfig.h
//  ZZBluetooth
//
//  Created by ZZ on 2017/9/21.
//  Copyright © 2017年 HongYun. All rights reserved.
//

#ifndef HCBLEConfig_h
#define HCBLEConfig_h

#import <CoreBluetooth/CoreBluetooth.h>
#import "ZZBLETimer.h"

typedef struct {
    
    unsigned short length;
    
    unsigned short HAPI_offset;
    unsigned short HAPI_length;
    
    unsigned short LEN_offset;
    unsigned short LEN_length;
    
    unsigned short SUM_offset;
    unsigned short SUM_length;
    
    unsigned short CMD_offset;
    unsigned short CMD_length;
    
    unsigned short ID_offset;
    unsigned short ID_length;
    
} HCBLEHeaderLayout;

static const HCBLEHeaderLayout _layout =
{
    (unsigned short)8,
    
    (unsigned short)0,
    (unsigned short)4,
    
    (unsigned short)4,
    (unsigned short)1,
    
    (unsigned short)5,
    (unsigned short)1,
    
    (unsigned short)6,
    (unsigned short)1,
    
    (unsigned short)7,
    (unsigned short)1,
};

static NSString *const HAPIString = @"HAPI";

static NSString *const HCBLEServiceUUID         = @"FFF0";
static NSString *const HCBLECharacteristicUUID  = @"FFF1";

static NSTimeInterval const HCBLEDefaultScanInterval = 5.0f;
static NSTimeInterval const HCBLEDefaultConnectInterval = 5.0f;
static NSTimeInterval const HCBLEDefaulTaskInterval = 5.0;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"

static BOOL HCBLECheckValidRSSI(NSNumber *RSSI) {
    float rssi = [RSSI floatValue];
    if (rssi >= 0 || rssi < -90) {
        return NO;
    }
    return YES;
}

static NSString *HCBLECentralSateDescription(NSInteger state) {
    if (@available(iOS 10.0, *)) {
        switch (state) {
            case CBManagerStateUnknown:
                return @"Manager State Unknown";
            case CBManagerStateResetting:
                return @"Manager State Resetting";
            case CBManagerStateUnsupported:
                return @"Manager State Unsupported";
            case CBManagerStateUnauthorized:
                return @"Manager State Unauthorized";
            case CBManagerStatePoweredOff:
                return @"Manager State PoweredOff";
            case CBManagerStatePoweredOn:
                return @"Manager State PoweredOn";
            default:
                break;
        }
    } else {
        switch (state) {
            case CBCentralManagerStateUnknown:
                return @"Manager State Unknown";
            case CBCentralManagerStateResetting:
                return @"Manager State Resetting";
            case CBCentralManagerStateUnsupported:
                return @"Manager State Unsupported";
            case CBCentralManagerStateUnauthorized:
                return @"Manager State Unauthorized";
            case CBCentralManagerStatePoweredOff:
                return @"Manager State PoweredOff";
            case CBCentralManagerStatePoweredOn:
                return @"Manager State PoweredOn";
            default:
                break;
        }
    }
    return nil;
}

#pragma clang diagnostic pop

#ifndef isAnEmptyString
#define isAnEmptyString(aString)    (!aString || [aString isKindOfClass:[NSNull class]] || ![aString respondsToSelector:@selector(length)] || 0 == aString.length)
#endif

#ifndef isNotAnEmptyString
#define isNotAnEmptyString(aString) (!isAnEmptyString(aString))
#endif

#endif /* HCBLEConfig_h */
