//
//  ZZBLEConnection.m
//  ZZBluetooth
//
//  Created by ZZ on 2017/9/21.
//  Copyright © 2017年 HongYun. All rights reserved.
//

#import "ZZBLEConnection.h"
#import "ZZBLEManager+Private.h"
#import "ZZBLEConnection+Private.h"
#import "ZZBLEConfig.h"
#import "ZZBLEResponseBuffer.h"
#import "ZZBLETaskError.h"

#define ZZLogConnection(...) ZZLog(@"<%@> %@", [self identifier], [NSString stringWithFormat:__VA_ARGS__])

#define ZZLogConnectionData(des, data) \
if (data && data.length) {\
int length = 16;\
int numberOfLine = data.length / length;\
int append = data.length % length;\
numberOfLine += (append) ? 1 : 0;\
ZZLogConnection(des);\
printf("*\n");\
for (int i = 0; i < numberOfLine; i++) {\
    int loc = i*length;\
    int len = MIN(length, data.length - loc);\
    printf("*\t%s\n", [data subdataWithRange:NSMakeRange(loc, len)].description.UTF8String);\
}\
printf("*\n");\
}\

@interface ZZBLEConnection () {
    
    dispatch_semaphore_t _lock;
    ZZBLETimer *_timer;
    NSMutableDictionary<NSNumber *, ZZBLETask *> *_dispatchDictionary;
    ZZBLEResponseBuffer *_buffer;

    BOOL _readyToWrite;
}

@property (nonatomic, strong) CBCentralManager *central;            // 主端角色
@property (nonatomic, strong) CBPeripheral *peripheral;             // 重端角色
@property (nonatomic, strong) CBCharacteristic *characteristic;     // 特征值

@end

@implementation ZZBLEConnection

+ (instancetype)connectionWithCentral:(CBCentralManager *)central peripheral:(CBPeripheral *)peripheral {
    ZZBLEConnection *connection = [[ZZBLEConnection alloc] init];
    connection.central = central;
    peripheral.delegate = connection;
    connection.peripheral = peripheral;
    return connection;
}

- (instancetype)init {
    if (self = [super init]) {
        _lock = dispatch_semaphore_create(1);
        _dispatchDictionary = [NSMutableDictionary dictionary];
        _buffer = [[ZZBLEResponseBuffer alloc] init];
    }
    return self;
}

- (CBPeripheralState)state {
    return _peripheral.state;
}

- (NSString *)identifier {
    return [NSString stringWithFormat:@"%@", _peripheral.name];
}

- (NSString *)UUIDString {
    return self.peripheral.identifier.UUIDString;
}

#pragma mark - timer

- (BOOL)taskIsValid {
    if (!_timer) {
        return NO;
    }
    return _timer.isValid;
}

- (void)startConnectTimer {
    if (_connectInterval == 0.0) {
        _connectInterval = ZZBLEDefaultConnectInterval;
    } else if (_connectInterval < 0) {
        return;
    }
    _timer = [ZZBLETimer timerWithTimeInterval:_connectInterval target:self selector:@selector(callTimeout:) repeats:NO];
}

- (void)stopConnectTimer {
    if ([self taskIsValid]) {
        [_timer invalidate];
    }
}

- (void)callTimeout:(ZZBLETimer *)timer {
    // System is still connecting. Cancel connection when timeout.
    [self disconnect];
    _connectTimeout ? _connectTimeout(_peripheral) : nil;
}

#pragma mark - connect, disconnect

- (void)connect {
    if (!_central) {
        return;
    }
    // is connecting
    if (self.state == CBPeripheralStateConnecting) {
        return;
    }
    // already connected
    if (self.state == CBPeripheralStateConnected) {
        _connectSuccess ? _connectSuccess(_peripheral, _characteristic) : nil;
        return;
    }
    // connecting
    [self startConnectTimer];
    ZZLogConnection(@"begin connect");
    [_central connectPeripheral:_peripheral options:nil];
}

- (void)disconnect {
    [self stopConnectTimer];
    if (!_central) {
        return;
    }
    if (self.state == CBPeripheralStateDisconnected) {
        return;
    }
    ZZLogConnection(@"begin disconnect");
    [_central cancelPeripheralConnection:_peripheral];
    _characteristic = nil;
    _readyToWrite = NO;
}

- (void)readRSSI {
    if (!_central || !_peripheral) {
        return;
    }
    if (self.state == CBPeripheralStateDisconnected) {
        return;
    }
    
    [_peripheral readRSSI];
}

#pragma mark - task
- (void)dispatchTask:(ZZBLETask *)task {
    if (!task) {
        return;
    }
    __weak ZZBLETask *weakTask = task;
    task.taskCompletion = ^() {
        [self dispatchTableRemoveTask:weakTask];
    };
    
    ZZLogConnection(@"(%@)", task.request.methodDesaription);
    
    [self dispatchTableAddTask:task];
    [task resume];
    
    if (self.state == CBPeripheralStateConnected) {
        if (_readyToWrite) {
            [self writeData:task.request.completData];
        } else {
            NSError *error = ZZErrorWithTaskErrorType(ZZBLEChaNotReady);
            [task taskDidFaildWithError:error];
        }
    } else {
        NSError *error = ZZErrorWithTaskErrorType(ZZBLEPeriNotConnected);
        [task taskDidFaildWithError:error];
    }
}

- (void)cancelTask:(ZZBLETask *)task {
    if (!task) {
        return;
    }
    [task cancel];
    [self dispatchTableRemoveTask:task];
}

- (void)writeData:(NSData *)data {
    
    if (!data || data.length == 0) {
        return;
    }
    if (!_readyToWrite) {
        return;
    }
    
#pragma mark - write value
    ZZLogConnectionData(@"write data", data);
    static const NSUInteger subDataLength = 8;
    NSUInteger remainder = data.length % subDataLength;
    NSUInteger times = data.length / subDataLength;
    void (^writeValueWithDataAndRange)(NSData *data, NSRange range) = ^(NSData *data, NSRange range){
        NSData *subData = [data subdataWithRange:range];
        //ZZLogConnection(@"write value :%@", subData);
        [_peripheral writeValue:subData forCharacteristic:_characteristic type:CBCharacteristicWriteWithResponse];
    };
    for (int index = 0; index < times; index++) {
        NSRange range = NSMakeRange(index * subDataLength, subDataLength);
        writeValueWithDataAndRange(data, range);
    }
    if (remainder) {
        NSRange range = NSMakeRange(times * subDataLength, remainder);
        writeValueWithDataAndRange(data, range);
    }
}


#pragma mark - task dispatch

- (void)dispatchTableRemoveTask:(ZZBLETask *)task {
    if (!task || !task.requestID) {
        return;
    }
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    [_dispatchDictionary removeObjectForKey:@(task.requestID)];
    dispatch_semaphore_signal(_lock);
}

- (void)dispatchTableAddTask:(ZZBLETask *)task {
    // 设置ID
    if (!task || !task.requestID) {
        return;
    }
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    [_dispatchDictionary setObject:task forKey:@(task.requestID)];
    dispatch_semaphore_signal(_lock);
}

#pragma mark - <CBCentralManagerDelegate>

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI {}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    ZZLogConnection(@"did connect");
    [self stopConnectTimer];
    [_buffer clearBuffer];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    ZZLogConnection(@"did fail to connect");
    _readyToWrite = NO;
    [self stopConnectTimer];
    _connectFailure ? _connectFailure(peripheral, error) : nil;
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    ZZLogConnection(@"did disconnect");
    _readyToWrite = NO;
}

#pragma mark - <CBPeripheralDelegate>

- (NSArray *)defaultChaUUIDs {
    static NSArray *_characteriiticUUIDs;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CBUUID *UUID = [CBUUID UUIDWithString:ZZBLECharacteristicUUID];
        _characteriiticUUIDs = @[UUID];
    });
    return _characteriiticUUIDs;
}

- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral {
    
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    
}

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(nullable NSError *)error {
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
    if (error) {
        return;
    }
    NSArray *services = [peripheral services];
    if (services == nil || services.count == 0) {
        return;
    }
    
    for (CBService *service in services) {
        if ([ZZBLEServiceUUID isEqualToString:service.UUID.UUIDString]) {
            [peripheral discoverCharacteristics:[self defaultChaUUIDs] forService:service];
            break;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error {
    if (error) {
        return;
    }
    NSArray *characteristics = [service characteristics];
    if (characteristics == nil || characteristics.count == 0) {
        return;
    }
    
    for (CBCharacteristic *cha in characteristics) {
        if ([ZZBLECharacteristicUUID isEqualToString:cha.UUID.UUIDString]) {
            _characteristic = cha;
            [peripheral setNotifyValue:YES forCharacteristic:cha];
            break;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    
    _readyToWrite = characteristic.isNotifying;
    
    if (_readyToWrite) {
        
        ZZLogConnection(@"ready to write");
        _connectSuccess ? _connectSuccess(_peripheral, _characteristic) : nil;
        
    } else {
        
        ZZLogConnection(@"cannot write error : %@", error);
        _connectFailure ? _connectFailure(_peripheral, error) : nil;
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    // did write value
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    // did get value
    
    NSData *data = characteristic.value;
    
    if (!data || data.length == 0) {
        return;
    }
    
    //ZZLogConnection(@"update value %@", data);
    
    [self didReceiveData:data];
}

#pragma mark - receive data

- (void)didReceiveData:(NSData *)data {
    
    NSArray<ZZBLEResponse *> *responsesArray = [_buffer receiveData:data];;
    
    for (int index = 0; index < responsesArray.count; index++) {
        
        ZZBLEResponse *response = responsesArray[index];
        
#pragma mark - receive value
        ZZLogConnectionData(@"receive data", response.completData);

        ZZBLETask *task = _dispatchDictionary[@(response.ID)];
        
        [task getResponse:response];
        
    }
    
}

@end
