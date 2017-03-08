//
//  CatchCrash.m
//  CrasgToolDemo
//
//  Created by Snow_lu on 2017/3/8.
//  Copyright © 2017年 小虾米. All rights reserved.
//

#import "CatchCrash.h"

#define  filePath @"log/error"

#define  VALIDDAYS  7

@implementation CatchCrash

 void catchExceptionHandler (NSException *exception){
    
     
     if (exception==nil) return;
    //异常的堆栈信息
    NSArray  *stackArrays = [exception callStackSymbols];
    
    //异常原因
    
    NSString *reason = [exception reason];
    
    //异常的名称
    NSString  *name   = [exception name];
    
     NSMutableDictionary *exceptionDic = [NSMutableDictionary dictionaryWithCapacity:0];
     
     [exceptionDic setValue:reason forKey:@"exceptionReason"];
     [exceptionDic setValue:name forKey:@"exceptionName"];
     [exceptionDic setValue:stackArrays forKey:@"callStackSymbols"];
     
    
     if ([CatchCrash CheckWriteCrashFileOnDocumentsException:exceptionDic]) {
          NSLog(@"Crash log write ok!");
     }
     
}
+(BOOL)CheckWriteCrashFileOnDocumentsException:(NSDictionary *)exceptionDic{
  
    //获取时间
    NSDate *date = [NSDate date];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
    
    NSString *DateTime = [formatter stringFromDate:date];
    
    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
    
     NSString *crashname = [NSString stringWithFormat:@"%@_%@Crashlog.log",DateTime,infoDic[@"CFBundleName"]];
    
      NSString *crashPath = [[self getFilePath] stringByAppendingString:filePath];
  

    
    NSFileManager *manger = [NSFileManager defaultManager];
    
    //设备信息
    
     NSMutableDictionary *deviceInfos = [NSMutableDictionary dictionary];
    
      [deviceInfos setValue:[infoDic objectForKey:@"DTPlatformVersion"] forKey:@"DTPlatformVersion"];
    
     [deviceInfos setValue:[infoDic objectForKey:@"CFBundleShortVersionString"] forKey:@"CFBundleShortVersionString"];
    
     [deviceInfos setValue:[infoDic objectForKey:@"UIRequiredDeviceCapabilities"] forKey:@"UIRequiredDeviceCapabilities"];
    
    BOOL isSuccess = [manger createDirectoryAtPath:crashPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    if (isSuccess) {
        
         NSLog(@"文件夹创建成功");
        
        NSString *filepath = [crashPath stringByAppendingPathComponent:crashname];
        
           NSMutableDictionary *logs = [NSMutableDictionary dictionaryWithContentsOfFile:filepath];
        
        if (!logs) {
            
            logs  = [NSMutableDictionary dictionaryWithCapacity:0];
        }
        
       NSDictionary *infos = @{@"Exception":exceptionDic,@"DeviceInfo":deviceInfos};
        
        
        [logs setValue:infos forKey:[NSString stringWithFormat:@"%@_crashLogs",infoDic[@"CFBundleName"]]];

                BOOL writeOK = [logs writeToFile:filepath atomically:YES];
        
             NSLog(@"write result = %d,filePath = %@",writeOK,filepath);
             return writeOK;
    }else{
     
        return  NO;
    }

}

//获取日志
+(NSArray *)getCrashLog {
    
  NSString *crashFilePath =   [[self getFilePath] stringByAppendingString:filePath];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSArray *fileArray = [manager contentsOfDirectoryAtPath:crashFilePath error:nil];
    
    NSMutableArray *results= [NSMutableArray arrayWithCapacity:0];
    
    if (fileArray.count ==0)return nil;
    
    for (NSString *fileName in fileArray) {
       
      NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[crashFilePath stringByAppendingPathComponent:fileName]];
        
           [results addObject:dict];
    }
    
    return results;
}
// 清理日志 有效期 7天
+(BOOL)clearCrashLog{
  
    NSString *crashFilePath =  [[self getFilePath]stringByAppendingString:filePath];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    if (![manager fileExistsAtPath:crashFilePath]) return YES;
    
      NSArray *crashLogContents = [manager contentsOfDirectoryAtPath:crashFilePath error:NULL];
    
    if (crashLogContents.count==0) return  YES;
    
      __block  NSString *fileName ;
    [crashLogContents enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([self interval:[crashFilePath stringByAppendingPathComponent:obj]]>VALIDDAYS) {
          
            fileName  = obj;

        }
    }];
    NSEnumerator *enums = [crashLogContents objectEnumerator];
    BOOL  success = YES;
    
    NSError  *error ;
    
    while (fileName == [enums nextObject]) {
        
        if (![manager removeItemAtPath:[crashFilePath stringByAppendingPathComponent:fileName] error:&error]) {
            
            success =NO;
           
            break;
        }
        NSLog(@"清除文件成功");
    }
    
    return success;
    
}
// 创建文件路径
+(NSString *)getFilePath{
    
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
}
//通过路径获取文件创建的时间
+(NSInteger )interval:(NSString *)path{
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    NSString *dateString = [NSString stringWithFormat:@"%@",[attributes fileModificationDate]];
    
    NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
    [inputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
    
    NSDate *formatterDate = [inputFormatter dateFromString:dateString];
    
    unsigned int unitFlags = NSDayCalendarUnit;
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *d = [cal components:unitFlags fromDate:formatterDate toDate:[NSDate date] options:0];
    
    NSInteger result = (NSUInteger)[d day];

    return result;
    
}

@end
