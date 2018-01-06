//
//  ZZBLEResponse.h
//  虹云智慧生活
//
//  Created by ZZ on 2017/9/26.
//  Copyright © 2017年 HongYun. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZZBLEResponse : NSObject

@property (readonly) BOOL isSucceeded;

@property (readonly) unsigned short LEN;
@property (readonly) unsigned short SUM;
@property (readonly) unsigned short CMD;
@property (readonly) unsigned short ID;

@property (readonly) unsigned short CODE;

@property (nonatomic, nullable, strong) NSError *error;

@property (nullable, readonly) NSData *completData;     // Data of header, code and content.
@property (nullable, readonly) NSData *totalMsgData;    // Data of code and content.
@property (nullable, readonly) NSData *contentData;     // Data of content.

+ (instancetype)responseWithData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
