//
//  ZZBLERequest.h
//  虹云智慧生活
//
//  Created by ZZ on 2017/9/21.
//  Copyright © 2017年 HongYun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCBLEAPICommand.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *HYMethodNameOfCommand(HCBLEAPICommand cmd);

@interface ZZBLERequest : NSObject

@property (readonly) unsigned short LEN;
@property (readonly) unsigned short SUM;
@property (readonly) unsigned short CMD;
@property (readonly) unsigned short ID;

@property (readonly) NSString *methodDesaription;

@end

NS_ASSUME_NONNULL_END
