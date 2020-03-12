## ZZBluetooth

​		根据公司业务封装的蓝牙通用组件，在 **CoreBluetooth** 的基础上提供了更加便捷直观的蓝牙使用方法，包括定时扫描、定向连接、数据通信等功能。

## 1. 使用前

* 在工程中导入 **\<CoreBluetooth/CoreBluetooth.h\>** 框架。

* 在 **info.plist** 文件中添加 **Privacy - Bluetooth Peripheral Usage Description** 一项，value为应用向用户申请蓝牙使用权限的描述。

## 2. 使用

### 2.1 ZZBLEManager

蓝牙实例化操作对象，用于实现蓝牙的扫描、连接、数据发送等操作。

**获取单例对象**

通过 `shareInstance` 方法获取单例对象，利用该单例对象进行扫描、连接等操作。

在第一次生成单例使用蓝牙时，若当前蓝牙为开启状态，则系统会对蓝牙进行初始化操作，该操作需要持续几秒，在初始化过程中若进行蓝牙操作则会失败。为避免此情况，建议在APP启动时`application:didFinishLaunchingWithOptions:`或者在使用前提前创建该单例对象，以提前进行蓝牙初始化。


```objective-c
// 获取单例对象
[ZZBLEManager shareInstance];
```


### 2.2 扫描设备

```
typedef BOOL(^ZZBLEScanDidDiscover)(CBPeripheral *peripheral, NSDictionary<NSString *, id> *advertisementData, NSNumber *RSSI);
typedef void(^ZZBLEScanDidFinish)(NSString *targetName, BOOL didDiscover);

/**
 扫描周围蓝牙重端设备(peripheral)
 */
- (void)scanWithName:(NSString *)name
           duplicate:(BOOL)duplicate
        scanInterval:(NSTimeInterval)interval
         didDiscover:(ZZBLEScanDidDiscover)discoverAndContinue
           didFinish:(ZZBLEScanDidFinish)didFinish;

```

| 参数 				| 描述				|
| ------------- 	| -------------	|
| name |设备名称过滤，设备名称中包含该字符串的设备将会在`discoverAndContinue`中回调；若不设置传入`nil`，周围所有的相关设备都将会在`discoverAndContinue`中回调。|
| duplicate |是否重复发现。若为NO，在扫描过程中，同一设备只会被扫描到并由`discoverAndContinue`返回一次；若为YES，在扫描过程中，同一设备的会被多次扫描到并由`discoverAndContinue`返回，以获取设备的实时状态，返回的频率与设备自身以及信号强度有关。|
| interval|扫描进行的时间，单位为秒/s。传入0则默认设置为5s；若小于0扫描将一直进行，直到`discoverAndContinue`返回了NO或调用`stopScan`方法手动停止扫描。|
| discoverAndContinue|一旦符合条件的设备被扫描发现，会在此处返回设备信息、蓝牙广播数据、信号值信息，设备的UUID信息需要进行保存，以便在连接设备时使用。该block一次只能返回一个设备的信息。若该block返回值为YES，则扫描继续，若返回值为NO，则立刻结束扫描并触发 `didFinish`。|
| didFinish |扫描结束时会触发该block。使用`stopScan`方法不会触发该block。|

### 2.3 停止扫描

通过`stopScan`方法手动停止蓝牙扫描操作。

```
/**
 手动停止扫描操作
 */
- (void)stopScan;
```

### 2.4 连接设备

```objective-c
/**
 连接蓝牙设备
 */
- (void)connectWithUUID:(NSString *)uuidString
                success:(ZZBLEConnectSuccess)connectSuccess
                failure:(ZZBLEConnectFailure)connectFailure
                timeout:(ZZBLEConnectTimeout)connectTimeout;
```

| 参数 				| 描述				|
| ------------- 	| -------------	|
| uuidString		|设备的UUID信息|
| connectSuccess	|设备连接成功后的回调。可以在回调中获得设备机器特征值得信息。|
| connectFailure	|设备连接失败后的回调。|
| connectTimeout	|设备连接超时后的回调。连接时间默认为5s。|

> 一个特定蓝牙设备在一个特定的手机上拥有唯一的UUID标识，设备不同或手机不同，UUID也会不同。新设备的UUID需要通过扫描获取，并进行保存。手机通过UUID获取蓝牙信息后，才能连接蓝牙设备。

### 2.5 断开连接

```objective-c
- (void)cancelConnectionWithUUID:(NSString *)uuidString;
- (void)cancelAllConnection;
```

> 由于一个蓝牙设备可能被多个应用使用，在一个应用要求断开连接后，手机会与设备的连接状态会保持一段时间，直到确认无应用使用该设备后才真正断开连接。蓝牙设备的断开连接过程不是实时的，但对于当前应用来说，设备的状态会及时更新为断开，可以认为连接已经断开。

## 3. ZZBLEAPI

该文件封装了设备的蓝牙业务接口。

### 3.1 接口示例

例如：

```objective-c
/**
 1.1 查询门锁的信息，可获得门锁电量、门锁保存的开门记录数和门锁时间是否准确的信息。门锁时间误差超过5分钟即认为不准确。
 
 @param UUIDString 设备UUID
 @param success 任务成功的回调。从中获取门锁电量、门锁保存的开门记录数和门锁时间是否准确的信息。
 @param failure 任务失败的回调
 @param timeout 任务超时的回调
 @return 请求任务
 */
+ (ZZBLETask *)lock_getInfoWithUUIDString:(NSString *)UUIDString
                              taskSuccess:(void (^)(BOOL battery, NSUInteger recordCount, BOOL timeAccurate))success
                              taskFailure:(ZZBLEAPIFailure)failure
                              taskTimeout:(ZZBLEAPITimeout)timeout;
```

在调用接口前，需先连接设备。在调用结束后，建议执行断开连接操作，减少对设备的占用。若未断开连接，设备端一段时间未收到数据则主动断开连接。

### 3.2 使用示例

演示：

```objective-c
NSString *uuidString = @"****";

[[ZZBLEManager shareInstance] connectWithUUID:uuidString success:^(CBPeripheral * _Nonnull peripheral, CBCharacteristic * _Nonnull characteristic) {

    /* 1、连接设备成功 */
    
    [ZZBLEAPI lock_getInfoWithUUIDString:uuidString taskSuccess:^(BOOL battery, NSUInteger recordCount, BOOL timeAccurate) {
    
        /* 2、接口执行成功 */
        /*
         执行业务操作或调用其他接口
         */
        /* 3、断开连接 */
        [[ZZBLEManager shareInstance] cancelConnectionWithUUID:uuidString];
        
    } taskFailure:^(NSError * _Nonnull error) {
    
        /* 2、接口执行失败，错误详情见`ZZBLETaskError.h` */
        /* 3、断开连接 */
        [[ZZBLEManager shareInstance] cancelConnectionWithUUID:uuidString];
        
    } taskTimeout:^{
    
        /* 2、接口执行超时 */
		 /* 3、断开连接 */
        [[ZZBLEManager shareInstance] cancelConnectionWithUUID:uuidString];
        
    }];
    
} failure:^(CBPeripheral * _Nullable peripheral, NSError * _Nonnull error) {

    /* 1、连接设备失败，错误详情见`ZZBLETaskError.h` */
    
} timeout:^(CBPeripheral * _Nullable peripheral) {

    /* 1、连接设备超时 */
    
}];
```

### 3.3 错误码

详见文件`"ZZBLETaskError.h"`。
