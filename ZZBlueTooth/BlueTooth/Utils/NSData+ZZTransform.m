//
//  NSData+ZZTransform.m
//  ZZBluetooth
//
//  Created by ZZ on 2017/9/29.
//  Copyright © 2017年 zz. All rights reserved.
//

#import "NSData+ZZTransform.h"

@implementation NSData (ZZTransform)

- (NSUInteger)integerValue {
    if (self.length > 8) {
        NSAssert(self.length <= 8, @"长度超过8字节，无法转化");
        return 0;
    }
    
    uint64_t integer = 0;
    [self getBytes:&integer length:self.length];
    
    integer = ntohll(integer);
    
    NSInteger bitsPerByte = 8;
    NSInteger lackOfBytes = 8 - self.length;
    integer = integer >> bitsPerByte * lackOfBytes;
    
    return (NSUInteger)integer;
}

- (nullable NSString *)toString {
    if (self.length == 0) {
        return nil;
    }
    NSMutableString *string = [[NSMutableString alloc] init];
    for (int idx = 0; idx < self.length; idx++) {
        NSRange range = NSMakeRange(idx, 1);
        NSData *hexData = [self subdataWithRange:range];
        NSInteger *hex = (NSInteger *)[hexData bytes];
        [string appendFormat:@"%02lx", (long)*hex];
    }
    return string;
}

- (NSInteger)decimalIntergerValue {
    NSString *string = self.toString;
    if (string && string.length) {
        return [string integerValue];
    }
    return 0;
}

@end
