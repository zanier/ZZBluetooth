//
//  HCBLEManager.h
//  ZZBluetooth
//
//  Created by ZZ on 2017/9/21.
//  Copyright © 2017年 HongYun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "ZZBLEConnection.h"

NS_ASSUME_NONNULL_BEGIN

typedef BOOL(^ZZBLEScanDidDiscover)(CBPeripheral *peripheral, NSDictionary<NSString *, id> *advertisementData, NSNumber *RSSI);
typedef void(^ZZBLEScanDidFinish)(NSString *targetName, BOOL didDiscover);

typedef void(^ZZBLEConnectSuccess)(CBPeripheral *peripheral, CBCharacteristic *characteristic);
typedef void(^ZZBLEConnectFailure)(CBPeripheral * _Nullable peripheral, NSError *error);
typedef void(^ZZBLEConnectTimeout)(CBPeripheral * _Nullable peripheral);
typedef void(^ZZBLEDidReadRSSI)(NSNumber *RSSI, NSError *_Nullable error);

@interface HCBLEManager : NSObject

/**
 HCBluetooth 打印信息开关，默认为YES。设置为NO以取消蓝牙的打印信息。
 */
@property (nonatomic, assign) BOOL logEnable;

@property (readonly) NSMutableDictionary<NSString *, ZZBLEConnection *> *connections;

- (ZZBLEConnection *)connectionWithUUIDString:(NSString *)UUIDString;

/**
 生成HCBLEManager单例对象，通过该对象进行蓝牙的扫描、连接等操作。在生成单例时，若当前蓝牙为开启状态，则会对蓝牙进行初始化操作，该操作需要持续几秒，在初始化过程中不能对蓝牙进行操作。建议在使用蓝牙之前提前创建该单例对象。

 @return 生成的单例对象。
 */
+ (instancetype)shareInstance;

/**
 手机蓝牙当前的状态。当状态为 ‘CBManagerStatePoweredOn’ 时蓝牙才可正常工作。

 @return 蓝牙状态
 */
- (CBManagerState)centralState;

/**
 扫描周围蓝牙重端设备(peripheral)

 @param name 设备名称过滤，设备名称中包含该字符串的设备将会在 ‘discoverAndContinue’ 中回调；若不设置传入nil，周围所有的相关设备都将会在 ‘discoverAndContinue’ 中回调。
 @param duplicate 是否重复发现。若为NO，在扫描过程中，同一设备只会被扫描到并由 ‘discoverAndContinue’ 返回一次；若为YES，在扫描过程中，同一设备的会被多次扫描到并由 ‘discoverAndContinue’ 返回，以获取设备的实时状态，返回的频率与设备自身以及信号强度有关。
 @param interval 扫描进行的时间，单位为秒/s。传入0则默认设置为5s；若小于0扫描将一直进行，直到‘discoverAndContinue’返回了NO或调用‘stopScan’方法手动停止扫描。
 @param discoverAndContinue 一旦符合条件的设备被扫描发现，会在此处返回设备信息、蓝牙广播数据、信号值信息，设备的UUID信息需要进行保存，以便在连接设备时使用。该block一次只能返回一个设备的信息。若该block返回值为YES，则扫描继续，若返回值为NO，则立刻结束扫描并触发 ‘didFinish’。
 @param didFinish 扫描结束时会触发该block。使用‘stopScan’方法不会触发该block。
 */
- (void)scanWithName:(NSString *)name
           duplicate:(BOOL)duplicate
        scanInterval:(NSTimeInterval)interval
         didDiscover:(ZZBLEScanDidDiscover)discoverAndContinue
           didFinish:(ZZBLEScanDidFinish)didFinish;

/**
 手动停止扫描操作
 */
- (void)stopScan;

/**
 连接蓝牙设备

 @param uuidString 设备的UUID信息。一个特定蓝牙设备在一个特定的手机上拥有唯一的UUID标识，设备不同或手机不同，UUID也会不同。新设备的UUID需要通过扫描获取，并进行保存。手机通过UUID获取蓝牙信息后，才能连接蓝牙设备。
 @param connectSuccess 设备连接成功后的回调。可以在回调中获得设备机器特征值得信息。
 @param connectFailure 设备连接失败后的回调。
 @param connectTimeout 设备连接超时后的回调。连接时间默认为5s。
 */
- (void)connectWithUUID:(NSString *)uuidString
                success:(ZZBLEConnectSuccess)connectSuccess
                failure:(ZZBLEConnectFailure)connectFailure
                timeout:(ZZBLEConnectTimeout)connectTimeout;


/**
 断开蓝牙设备的连接。由于一个蓝牙设备可能被多个应用使用，在一个应用要求断开连接后，手机会与设备的连接状态会保持一段时间，直到确认无应用使用该设备后才真正断开连接。蓝牙设备的断开连接过程不是实时的，但对于当前应用来说，设备的状态会及时更新为断开，可以认为连接已经断开。

 @param uuidString 需要断开连接设备的UUID
 */
- (void)cancelConnectionWithUUID:(NSString *)uuidString;

/**
 若同时连接了多个蓝牙设备，可使用该方法断开当前所有的设备连接。
 */
- (void)cancelAllConnection;

@end

NS_ASSUME_NONNULL_END
