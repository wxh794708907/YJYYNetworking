//
//  YJYYNetworking+cache.m
//  YJYYNetworking
//
//  Created by YJYY on 2016/7/25.
//  Copyright © 2016年 YJYY. All rights reserved.
//

#import "YJYYNetworking+cache.h"
#import "YJYYMemoryCache.h"
#import "YJYYDistCache.h"
#import <CommonCrypto/CommonDigest.h>

static NSString *const cacheDirKey = @"cacheDirKey";

static NSString *const downloadDirKey = @"downloadDirKey";

#define YJYY_NSUSERDEFAULT_GETTER(key) [[NSUserDefaults standardUserDefaults] objectForKey:key]

#define YJYY_NSUSERDEFAULT_SETTER(value, key) [[NSUserDefaults standardUserDefaults] setObject:value forKey:key]

@implementation YJYYNetworking (cache)

+ (void)cacheResponseObject:(id)responseObject
                 requestUrl:(NSString *)requestUrl
                     params:(NSDictionary *)params {
    assert(responseObject);
    
    assert(requestUrl);
    
    if (!params) params = @{};
    NSString *originString = [NSString stringWithFormat:@"%@+%@",requestUrl,params];
    NSString *hash = [self md5:originString];
    
    NSData *data = nil;
    NSError *error = nil;
    if ([responseObject isKindOfClass:[NSData class]]) {
        data = responseObject;
    }else if ([responseObject isKindOfClass:[NSDictionary class]]){
        data = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:&error];
    }
    
    if (error == nil) {
        //缓存到内存中
        [YJYYMemoryCache writeData:responseObject forKey:hash];
        
        //缓存到磁盘中
        //磁盘路径
        NSString *directoryPath = nil;
        directoryPath = YJYY_NSUSERDEFAULT_GETTER(cacheDirKey);
        if (!directoryPath) {
            directoryPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"YJYYNetworking"] stringByAppendingPathComponent:@"networkCache"];
            YJYY_NSUSERDEFAULT_SETTER(directoryPath,cacheDirKey);
        }
        [YJYYDistCache writeData:data toDir:directoryPath filename:hash];
    }
    
}

+ (id)getCacheResponseObjectWithRequestUrl:(NSString *)requestUrl
                                    params:(NSDictionary *)params {
    assert(requestUrl);
    
    id cacheData = nil;
    
    if (!params) params = @{};
    NSString *originString = [NSString stringWithFormat:@"%@+%@",requestUrl,params];
    NSString *hash = [self md5:originString];
    
    //先从内存中查找
    cacheData = [YJYYMemoryCache readDataWithKey:hash];
    
    if (!cacheData) {
        NSString *directoryPath = YJYY_NSUSERDEFAULT_GETTER(cacheDirKey);
        cacheData = [YJYYDistCache readDataFromDir:directoryPath filename:hash];
    }
    
    return cacheData;
}

+ (void)storeDownloadData:(NSData *)data
               requestUrl:(NSString *)requestUrl {
    assert(data);
    
    assert(requestUrl);
    
    NSString *fileName = nil;
    NSString *type = nil;
    NSArray *strArray = nil;
    
    strArray = [requestUrl componentsSeparatedByString:@"."];
    if (strArray.count > 0) {
        type = strArray[strArray.count - 1];
    }
    
    if (type) {
        fileName = [NSString stringWithFormat:@"%@.%@",[self md5:requestUrl],type];
    }else {
        fileName = [NSString stringWithFormat:@"%@",[self md5:requestUrl]];
    }
    
    NSString *directoryPath = nil;
    directoryPath = YJYY_NSUSERDEFAULT_GETTER(downloadDirKey);
    if (!directoryPath) {
        directoryPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"YJYYNetworking"] stringByAppendingPathComponent:@"download"];
        
        YJYY_NSUSERDEFAULT_SETTER(directoryPath, downloadDirKey);
    }
    
    [YJYYDistCache writeData:data toDir:directoryPath filename:fileName];

}

+ (NSURL *)getDownloadDataFromCacheWithRequestUrl:(NSString *)requestUrl {
    assert(requestUrl);
    
    NSData *data = nil;
    NSString *fileName = nil;
    NSString *type = nil;
    NSArray *strArray = nil;
    NSURL *fileUrl = nil;
    

    strArray = [requestUrl componentsSeparatedByString:@"."];
    if (strArray.count > 0) {
        type = strArray[strArray.count - 1];
    }
    
    if (type) {
        fileName = [NSString stringWithFormat:@"%@.%@",[self md5:requestUrl],type];
    }else {
        fileName = [NSString stringWithFormat:@"%@",[self md5:requestUrl]];
    }
    
    
    NSString *directoryPath = YJYY_NSUSERDEFAULT_GETTER(downloadDirKey);
    
    data = [YJYYDistCache readDataFromDir:directoryPath filename:fileName];
    
    if (data) {
        NSString *path = [directoryPath stringByAppendingPathComponent:fileName];
        fileUrl = [NSURL fileURLWithPath:path];
    }
    
    return fileUrl;
}

+ (unsigned long long)totalCacheSize {
    NSString *diretoryPath = YJYY_NSUSERDEFAULT_GETTER(cacheDirKey);

    return [YJYYDistCache dataSizeInDir:diretoryPath];
}

+ (void)clearTotalCache {
    NSString *directoryPath = YJYY_NSUSERDEFAULT_GETTER(cacheDirKey);
    
    [YJYYDistCache clearDataIinDir:directoryPath];
}

+ (unsigned long long)totalDownloadDataSize {
    NSString *diretoryPath = YJYY_NSUSERDEFAULT_GETTER(downloadDirKey);
    
    return [YJYYDistCache dataSizeInDir:diretoryPath];
}

+ (void)clearDownloadData {
    NSString *diretoryPath = YJYY_NSUSERDEFAULT_GETTER(downloadDirKey);
    
    [YJYYDistCache clearDataIinDir:diretoryPath];
}

#pragma mark - 散列值
+ (NSString *)md5:(NSString *)string {
    if (string == nil || string.length == 0) {
        return nil;
    }
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH],i;
    
    CC_MD5([string UTF8String],(int)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding],digest);
    
    NSMutableString *ms = [NSMutableString string];
    
    for (i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [ms appendFormat:@"%02x",(int)(digest[i])];
    }
    
    return [ms copy];
}

@end
