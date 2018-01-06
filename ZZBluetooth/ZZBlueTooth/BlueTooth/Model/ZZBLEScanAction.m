//
//  HYBLEScanAction.m
//  虹云智慧生活
//
//  Created by ZZ on 2017/9/25.
//  Copyright © 2017年 HongYun. All rights reserved.
//

#import "ZZBLEScanAction.h"
#import "HCBLEManager.h"

@implementation ZZBLEScanAction {
    HCBLETimer *_timer;
}

- (BOOL)taskIsValid {
    return _timer && _timer.isValid;
}

- (void)startScanTimer {
    
    _didDiscover = NO;
    
    if (_scanInterval == 0.0) {
        
        _scanInterval = HCBLEDefaultScanInterval;
        
    } else if (_scanInterval < 0) {
        
        return;
        
    }
    
    _timer = [HCBLETimer timerWithTimeInterval:_scanInterval
                                        target:self
                                      selector:@selector(callTimeout)
                                       repeats:NO];
    
}

- (void)stopScanTimer {
    if ([self taskIsValid]) {
        [_timer invalidate];
    }
}

- (void)callTimeout {
    
    [self stopScanTimer];
    
    if (_delegate && [_delegate respondsToSelector:@selector(scanTaskDidFinishScan:discovered:)]) {
        [_delegate scanTaskDidFinishScan:self discovered:_didDiscover];
    }
    
}

@end
