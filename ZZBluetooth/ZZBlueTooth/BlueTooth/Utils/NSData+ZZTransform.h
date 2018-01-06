//
//  NSData+ZZTransform.h
//  HYBLEDemo
//
//  Created by ZZ on 2017/9/29.
//  Copyright © 2017年 zz. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (ZZTransform)

/**
 将不大于8字节的数据转换为数字。如<0011> 转换为（0x11）
 */
- (NSUInteger)integerValue;

- (nullable NSString *)toString;

- (NSInteger)decimalIntergerValue;

@end

NS_ASSUME_NONNULL_END
