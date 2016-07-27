//
//  YJYYNetworking+cache.h
//  YJYYNetworking
//
//  Created by YJYY on 2016/7/25.
//  Copyright © 2016年 YJYY. All rights reserved.
//

#import "YJYYNetworking.h"

@interface YJYYNetworking (cache)

/**
 *  缓存响应数据
 *
 *  @param responseObject 响应数据
 *  @param requestUrl     请求url
 *  @param params         请求参数
 */
+ (void)cacheResponseObject:(id)responseObject requestUrl:(NSString *)requestUrl params:(NSDictionary *)params;

/**
 *  获取响应数据
 *
 *  @param requestUrl 请求url
 *  @param params     请求参数
 *
 *  @return 响应数据
 */
+ (id)getCacheResponseObjectWithRequestUrl:(NSString *)requestUrl params:(NSDictionary *)params;

/**
 *  存储下载文件
 *
 *  @param data       文件数据
 *  @param requestUrl 请求url
 *
 *  @return
 */
+ (void)storeDownloadData:(NSData *)data
               requestUrl:(NSString *)requestUrl;

/**
 *  获取磁盘中的下载文件
 *
 *  @param requestUrl 请求url
 *
 *  @return 文件本地存储路径
 */
+ (NSURL *)getDownloadDataFromCacheWithRequestUrl:(NSString *)requestUrl;


+ (NSString *)getCacheDiretoryPath;

+ (NSString *)getDownDirectoryPath;

/**
 *  获取缓存大小
 *
 *  @return 缓存大小
 */
+ (unsigned long long)totalCacheSize;

/**
 *  清除所有缓存
 */
+ (void)clearTotalCache;

/**
 *  获取所有下载数据大小
 *
 *  @return 下载数据大小
 */
+ (unsigned long long)totalDownloadDataSize;

/**
 *  清除下载数据
 */
+ (void)clearDownloadData;
@end
