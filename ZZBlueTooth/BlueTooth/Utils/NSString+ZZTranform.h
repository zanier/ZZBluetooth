//
//  NSString+ZZTranform.h
//  ZZBluetooth
//
//  Created by ZZ on 2017/9/27.
//  Copyright © 2017年 zz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (ZZTranform)

/**
 将纯十六进制的字符串转化为相应的二进制数据。
 如字符串 “1234CDEF” 将转换为 <1234CDEF> 的二进制数据。两个数字将转换为一个字节；若字符串长度为奇数，最后一个字符将被忽略，例如 “1234CDE” 将转换为 <1234CD>
 
 @return 二进制数据
 */
- (NSData *)hexToBytes;

/**
 *  十六进制形式的字符串转换为char*字符串指针
 *
 *  @return char*字符串
 */
- (unsigned char *)hexToCharPointer;

/**
 *  十六进制字符串转换为byte数组再base64编码为字符串
 *
 *  @return 编码字符串
 */
- (NSString *)hexStringToBytesToBase64String;

/**
 *  base64编码字符串转换为byte数组再转为十六进制字符串
 *
 *  @return 编码字符串
 */
- (NSString *)base64StringToBytesToHexString;

@end
