//
//  ZZBLEResponse.m
//  ZZBluetooth
//
//  Created by ZZ on 2017/9/26.
//  Copyright © 2017年 HongYun. All rights reserved.
//

#import "ZZBLEResponse.h"
#import "ZZBLEConfig.h"
#import "ZZBLETaskError.h"

@interface ZZBLEResponse ()

@property (nonatomic, assign) BOOL isSucceeded;

@property (nonatomic, assign) unsigned short LEN;
@property (nonatomic, assign) unsigned short SUM;
@property (nonatomic, assign) unsigned short CMD;
@property (nonatomic, assign) unsigned short ID;

@property (nonatomic, strong) NSData *completData;
@property (nonatomic, strong) NSData *contentData;
@property (nonatomic, strong) NSData *totalMsgData;

@end

@implementation ZZBLEResponse

+ (instancetype)responseWithData:(NSData *)data {
    return [[ZZBLEResponse alloc] initWithData:data];
}

- (instancetype)initWithData:(NSData *)data {
    if (!data || data.length < _layout.length) {
        return nil;
    }
    if (self = [super init]) {
        [self setCompletData:data];
    }
    return self;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:@"ZZBLEResponse init error" reason:@"ZZBLEResponse must be initialized with response data. Use 'responseWithData:' instead." userInfo:nil];
    return [self initWithData:nil];
}

unsigned short subdateValueWithRange(NSData *data, unsigned short loc, unsigned short len) {
    unsigned short *subdata = (unsigned short *)[[data subdataWithRange:NSMakeRange(loc, len)] bytes];
    return *subdata;
}

- (void)setCompletData:(NSData *)completData {
    
    if (!completData || completData.length < _layout.length) {
        return;
    }
    
    _completData = completData;
    
    _LEN = subdateValueWithRange(completData, _layout.LEN_offset, _layout.LEN_length);
    _SUM = subdateValueWithRange(completData, _layout.SUM_offset, _layout.SUM_length);
    _CMD = subdateValueWithRange(completData, _layout.CMD_offset, _layout.CMD_length);
    _ID  = subdateValueWithRange(completData, _layout.ID_offset,  _layout.ID_length);

    _isSucceeded = YES;
    
    if (completData.length >= _layout.length + 1) {
        
        _CODE = subdateValueWithRange(completData, _layout.length, 1);
        _error = ZZErrorWithTaskErrorType(_CODE);
        _isSucceeded = (_CODE == 0);
        
        _contentData = [completData subdataWithRange:NSMakeRange(_layout.length + 1, _LEN - 1)];
        _totalMsgData = [completData subdataWithRange:NSMakeRange(_layout.length, _completData.length - (_layout.length))];
    }
    
}

@end
