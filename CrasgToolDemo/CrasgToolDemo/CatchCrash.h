//
//  CatchCrash.h
//  CrasgToolDemo
//
//  Created by Snow_lu on 2017/3/8.
//  Copyright © 2017年 小虾米. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CatchCrash : NSObject

 void catchExceptionHandler (NSException *exception);
//获取崩溃日志文件
+(NSArray *)getCrashLog;
//清理日志
+(BOOL)clearCrashLog;
@end
