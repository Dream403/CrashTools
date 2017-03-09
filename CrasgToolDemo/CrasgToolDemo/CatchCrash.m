//
//  CatchCrash.m
//  CrasgToolDemo
//
//  Created by Snow_lu on 2017/3/8.
//  Copyright © 2017年 小虾米. All rights reserved.
//

#import "CatchCrash.h"
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
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
/**
 
 http://www.cocoachina.com/ios/20150701/12301.html?mType=Group
 
 如果同时有多方通过NSSetUncaughtExceptionHandler注册异常处理程序，和平的作法是：后注册者通过NSGetUncaughtExceptionHandler将先前别人注册的handler取出并备份，在自己handler处理完后自觉把别人的handler注册回去，规规矩矩的传递。不传递强行覆盖的后果是，在其之前注册过的日志收集服务写出的Crash日志就会因为取不到NSException而丢失Last Exception Backtrace等信息。（P.S. iOS系统自带的Crash Reporter不受影响）
 */
+(NSUncaughtExceptionHandler *)catchGetExceptionHandler{
    
  return  NSGetUncaughtExceptionHandler();
    
}
//获取dSYM UUID方法如下
static  NSUUID *ExecutabUUID (void ){
    
    const  struct mach_header  *executableHeader =NULL;
    
    for (uint32_t  i = 0 ; i<_dyld_image_count(); i++) {
     
        const struct mach_header *header =_dyld_get_image_header(i);
        
        if (header ->filetype ==MH_EXECUTE) {
            
            executableHeader =header;
            
            break;
        }
        
    }
    
    if (!executableHeader) return nil;
    
    BOOL  is64bit  =executableHeader ->magic ==MH_EXECUTE ||executableHeader->magic == MH_CIGAM_64 ;
    
    uintptr_t cursor  = (uintptr_t)executableHeader + (is64bit ? sizeof(struct mach_header_64) : sizeof(struct mach_header));
    
    const struct segment_command *segmentCommand = NULL;
    
    for (uint32_t i = 0; i < executableHeader->ncmds; i++, cursor += segmentCommand->cmdsize)
    {
        segmentCommand = (struct segment_command *)cursor;
        
        if (segmentCommand->cmd == LC_UUID)
        {
            const struct uuid_command *uuidCommand = (const struct uuid_command *)segmentCommand;
            return [[NSUUID alloc] initWithUUIDBytes:uuidCommand->uuid];
        }
    }
    
    return nil;
    
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
    
     NSString *crashname = [NSString stringWithFormat:@"%@_%@_%@Crashlog.log",ExecutabUUID(),DateTime,infoDic[@"CFBundleName"]];
    
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
