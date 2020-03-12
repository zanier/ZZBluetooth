//
//  ZZBLEManager.m
//  ZZBluetooth
//
//  Created by ZZ on 2017/9/21.
//  Copyright © 2017年 HongYun. All rights reserved.
//

#import "ZZBLEManager+Private.h"
#import "ZZBLEConnection+Private.h"
#import "ZZBLEScanAction.h"
#import "ZZBLETaskError.h"
#import "ZZBLEConfig.h"

@interface ZZBLEManager () <CBCentralManagerDelegate, ZZBLEScanTaskDelegate>

@property (nonatomic, strong) NSMutableDictionary<NSString *, ZZBLEConnection *> *connections;

@property (nonatomic, strong) CBCentralManager *central;

@property (nonatomic, strong) dispatch_queue_t delegateQueue;

@property (nonatomic, strong) ZZBLEScanAction *scanTask;

@end

@implementation ZZBLEManager

static dispatch_semaphore_t _lock;

+ (instancetype)shareInstance {
    static ZZBLEManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!instance) {
            _lock = dispatch_semaphore_create(1);
            instance = [[super alloc] init];
            [instance initInstance];
        }
    });
    return instance;
}

- (void)initInstance {
    
    _connections = [NSMutableDictionary dictionary];
    
    const char *delegateQueueLabel = [[NSString stringWithFormat:@"%p_bleCentralDelegateQueue", self] cStringUsingEncoding:NSUTF8StringEncoding];
    _delegateQueue = dispatch_queue_create(delegateQueueLabel, DISPATCH_QUEUE_SERIAL);
    _central = [[CBCentralManager alloc] initWithDelegate:self queue:_delegateQueue options:nil];
    
    _logEnable = YES;
}

- (BOOL)centralIsPowerOn {
    return self.centralState == CBManagerStatePoweredOn;
}

- (CBManagerState)centralState {
    return _central.state;
}

- (CBPeripheral *)peripheralWithUUID:(NSString *)uuidString {
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    NSArray *array = [_central retrievePeripheralsWithIdentifiers:@[uuid]];
    CBPeripheral *peripheral = [array firstObject];
    return peripheral;
}

/*
 scan
 */

- (void)scanWithName:(NSString *)name
           duplicate:(BOOL)duplicate
        scanInterval:(NSTimeInterval)interval
         didDiscover:(ZZBLEScanDidDiscover)discoverAndContinue
           didFinish:(ZZBLEScanDidFinish)didFinish
{
    if (_scanTask) {
        [_scanTask stopScanTimer];
    }
    _scanTask = [[ZZBLEScanAction alloc] init];
    _scanTask.delegate = self;
    _scanTask.targetName = name;
    _scanTask.duplicate = duplicate;
    _scanTask.scanInterval = interval;
    // call block
    _scanTask.scanDidDiscover = discoverAndContinue;
    _scanTask.scanDidFinsh = didFinish;
    
    if ([self centralIsPowerOn]) {
        [self scan];
    } else {
        // waiting for central update state
    }

}

- (void)scan {
    ZZLog(@"central start scan <%@>...", _scanTask.targetName);
    [_scanTask startScanTimer];
    [_central scanForPeripheralsWithServices:[self defaulutServices]
                                     options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @(_scanTask.duplicate)}];
}

- (NSArray *)defaulutServices {
    static NSArray *_services;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CBUUID *UUID = [CBUUID UUIDWithString:ZZBLEServiceUUID];
        _services = @[UUID];
    });
    return _services;
}

- (void)stopScan {
    ZZLog(@"central stop scan!");
    [_central stopScan];
}

/*
 connect
 */

- (void)connectWithUUID:(NSString *)uuidString
                success:(ZZBLEConnectSuccess)connectSuccess
                failure:(ZZBLEConnectFailure)connectFailure
                timeout:(ZZBLEConnectTimeout)connectTimeout
{
    if (isAnEmptyString(uuidString)) {
        NSError *error = ZZErrorWithTaskErrorType(ZZBLEWithoutUUID);
        connectFailure ? connectFailure(nil, error) : nil;
        return;
    }
    ZZBLEConnection *connection = [self connectionWithUUIDString:uuidString];
    if (!connection) {
        CBPeripheral *peri = [self peripheralWithUUID:uuidString];
        connection = [ZZBLEConnection connectionWithCentral:_central peripheral:peri];
        [self addNewConnection:connection];
    }
    connection.connectSuccess = connectSuccess;
    connection.connectFailure = connectFailure;
    connection.connectTimeout = connectTimeout;
    
    [connection connect];
}

- (void)cancelConnectionWithUUID:(NSString *)uuidString {
    if (isAnEmptyString(uuidString)) {
        return;
    }
    ZZBLEConnection *connection = [self connectionWithUUIDString:uuidString];
    if (!connection) {
        CBPeripheral *cbPeri = [self peripheralWithUUID:uuidString];
        [_central cancelPeripheralConnection:cbPeri];
    } else {
        [connection disconnect];
//        [self removeConnection:connection];
    }
}

- (void)cancelAllConnection {
    for (NSString *UUIDString in _connections) {
        ZZBLEConnection *connection = _connections[UUIDString];
        [connection disconnect];
    }
    [_connections removeAllObjects];
}

/*
 connect
 */

- (void)readRSSIWithUUID:(NSString *)uuidString {
    
}

#pragma mark - task action

- (void)dispatchTask:(ZZBLETask *)task {
    if (!task) {
        return;
    }
    if (self.centralState != CBManagerStatePoweredOn) {
        ZZLog(@"cetral state %@", ZZBLECentralSateDescription(_central.state));
        NSError *error = ZZErrorWithTaskErrorType(ZZBLECentralNotPowerOn);
        [task taskDidFaildWithError:error];
        return;
    }
    ZZBLEConnection *connection = [self connectionWithUUIDString:task.UUIDString];
    if (!connection) {
        ZZLog(@"connect peripheral and set characteristic notified first!");
        NSError *error = ZZErrorWithTaskErrorType(ZZBLEPeriNotConnected);
        [task taskDidFaildWithError:error];
        return;
    }
    [connection dispatchTask:task];
}

- (void)cancelTask:(ZZBLETask *)task {
    if (!task) {
        return;
    }
    ZZBLEConnection *connection = [self connectionWithUUIDString:task.UUIDString];
    if (!connection) {
        return;
    }
    [connection cancelTask:task];
}

#pragma mark - task dispatch

- (void)removeConnection:(ZZBLEConnection *)connection {
    if (!connection || isAnEmptyString(connection.UUIDString)) {
        return;
    }
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    [_connections removeObjectForKey:connection.UUIDString];
    dispatch_semaphore_signal(_lock);
}

- (void)addNewConnection:(ZZBLEConnection *)connection {
    if (!connection || isAnEmptyString(connection.UUIDString)) {
        return;
    }
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    [_connections setObject:connection forKey:connection.UUIDString];
    dispatch_semaphore_signal(_lock);
}

- (ZZBLEConnection *)connectionWithUUIDString:(NSString *)UUIDString {
    if (isAnEmptyString(UUIDString)) {
        return nil;
    }
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    ZZBLEConnection *connection = _connections[UUIDString];
    dispatch_semaphore_signal(_lock);
    return connection;
}

#pragma mark - <ZZBLEScanTaskDelegate>

- (void)scanTaskDidFinishScan:(ZZBLEScanAction *)task discovered:(BOOL)didDiscover {
    
    [self stopScan];
    
    if (_scanTask.scanDidFinsh) {
        _scanTask.scanDidFinsh(_scanTask.targetName, _scanTask.didDiscover);
    }
    
    _scanTask.scanDidDiscover = nil;
    _scanTask.scanDidFinsh = nil;
    
}

#pragma mark - <CBCentralManagerDelegate>

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    ZZLog(@"central manager did update state : %@", ZZBLECentralSateDescription(central.state));
    if ([self centralIsPowerOn]) {
        if (_scanTask && _scanTask.scanDidFinsh && _scanTask.scanDidDiscover) {
            [self scan];
        }
    }
}

//- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *, id> *)dict {}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
    if (!ZZBLECheckValidRSSI(RSSI)) {
        return;
    }
    
    if (isAnEmptyString(peripheral.name)) {
        return;
    }
    
    if (isNotAnEmptyString(self.scanTask.targetName)) {
        NSString *periName = peripheral.name;
        if ([periName rangeOfString:self.scanTask.targetName].location == NSNotFound) {
            return;
        }
    }
    
    self.scanTask.didDiscover = YES;
    
    if (self.scanTask.scanDidDiscover) {
        BOOL shouldContinue = self.scanTask.scanDidDiscover(peripheral, advertisementData, RSSI);
        if (!shouldContinue) {
            [self.scanTask callTimeout];
        }
    }
}

#define getProperConnection     \
ZZBLEConnection *connection = [self connectionWithUUIDString:peripheral.identifier.UUIDString];\
if (!connection || ![connection respondsToSelector:_cmd]) {\
    return;\
}\
if (![connection.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {\
    return;\
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    getProperConnection;
    [self stopScan];
    [connection centralManager:central didConnectPeripheral:peripheral];
    [peripheral discoverServices:[self defaulutServices]];
    
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    
    getProperConnection;
    [connection centralManager:central didFailToConnectPeripheral:peripheral error:error];
    //? [self removeConnection:connection];
    
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    
    getProperConnection;
    [connection centralManager:central didDisconnectPeripheral:peripheral error:error];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), _delegateQueue, ^{
        [self removeConnection:connection];
    });
    
}

#undef getProperSession

@end
