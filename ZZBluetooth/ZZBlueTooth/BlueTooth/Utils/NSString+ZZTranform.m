//
//  NSString+ZZTranform.m
//  ZZBluetooth
//
//  Created by ZZ on 2017/9/27.
//  Copyright © 2017年 zz. All rights reserved.
//

#import "NSString+ZZTranform.h"

@implementation NSString (ZZTranform)

- (NSData *)hexToBytes {
    NSMutableData *data = [NSMutableData data];
    for (int idx = 0; idx + 2 <= self.length; idx += 2) {
        NSRange range = NSMakeRange(idx, 2);
        NSString *hexStr = [self substringWithRange:range];
        NSScanner *scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    return data;
}

- (unsigned char *)hexToCharPointer {
    unsigned char *charPointer = (unsigned char *)[[self hexToBytes] bytes];
    return charPointer;
}

- (NSString *)hexStringToBytesToBase64String {
    
    NSData *hexData = [self hexToBytes];
    
    NSString *base64String = [hexData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    
    return base64String;
}

- (NSString *)base64StringToBytesToHexString {
    
    NSData *data = [[NSData alloc] initWithBase64EncodedString:self options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    NSMutableString *hexString = [[NSMutableString alloc] init];
    
    for (int idx = 0; idx < data.length; idx++) {
        NSRange range = NSMakeRange(idx, 1);
        NSData *hexData = [data subdataWithRange:range];
        NSInteger *hex = (NSInteger *)[hexData bytes];
        [hexString appendFormat:@"%02lx", (long)*hex];
    }
    
    return hexString;
}

@end
