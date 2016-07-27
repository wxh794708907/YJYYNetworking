//
//  YJYYNetworking.m
//  YJYYNetworking
//
//  Created by YJYY on 2016/7/25.
//  Copyright © 2016年 YJYY. All rights reserved.
//

#import "YJYYNetworking.h"
#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"
#import <CommonCrypto/CommonDigest.h>
#import "YJYYNetworking+cache.h"

#define YJYY_ERROR_IMFORMATION @"网络出现错误，请检查网络连接"

#define YJYY_ERROR [NSError errorWithDomain:@"com.caixindong.YJYYNetworking.ErrorDomain" code:-999 userInfo:@{ NSLocalizedDescriptionKey:YJYY_ERROR_IMFORMATION}]

static NSMutableArray   *requestTasks;

static NSDictionary     *headers;

static YJYYNetworkStatus  networkStatus;

static NSTimeInterval   requestTimeout = 20.f;

static int CACHEMAXSIZE = 10485760;

@implementation YJYYNetworking

#pragma mark - manager
+ (AFHTTPSessionManager *)manager {
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    //默认解析模式
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    //配置请求序列化
    AFJSONResponseSerializer *serializer = [AFJSONResponseSerializer serializer];
    
    [serializer setRemovesKeysWithNullValues:YES];
    
    manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
    
    manager.requestSerializer.timeoutInterval = requestTimeout;
    
    for (NSString *key in headers.allKeys) {
        if (headers[key] != nil) {
            [manager.requestSerializer setValue:headers[key] forHTTPHeaderField:key];
        }
    }
    
    //配置响应序列化
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",
                                                                              @"text/html",
                                                                              @"text/json",
                                                                              @"text/plain",
                                                                              @"text/javascript",
                                                                              @"text/xml",
                                                                              @"image/*",
                                                                              @"application/octet-stream",
                                                                              @"application/zip"]];
    
    [self checkNetworkStatus];
    
    //每次网络请求的时候，检查此时磁盘中的缓存大小，如果超过阈值，则清理所有缓存
    //未来优化点：1、这里到时会做进一步优化，到时会有两种清理策略，一种基于时间维度，一种基于缓存大小,
    //          2、清理也不会清理全部，会采取LRU算法来淘汰在磁盘中价值最低的缓存
    if ([self totalCacheSize] > CACHEMAXSIZE) [self clearTotalCache];
    
    return manager;
}

#pragma mark - 检查网络
+ (void)checkNetworkStatus {
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    
    [manager startMonitoring];
    
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
       
        switch (status) {
            case AFNetworkReachabilityStatusNotReachable:
                networkStatus = YJYYNetworkStatusNotReachable;
                break;
            case AFNetworkReachabilityStatusUnknown:
                networkStatus = YJYYNetworkStatusUnknown;
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                networkStatus = YJYYNetworkStatusReachableViaWWAN;
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                networkStatus = YJYYNetworkStatusReachableViaWiFi;
                break;
            default:
                networkStatus = YJYYNetworkStatusUnknown;
                break;
        }
        
    }];
}

+ (NSMutableArray *)allTasks {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (requestTasks == nil) requestTasks = [NSMutableArray array];
    });
    
    return requestTasks;
}

#pragma mark - get
+ (YJYYURLSessionTask *)getWithUrl:(NSString *)url
                           cache:(BOOL)cache
                          params:(NSDictionary *)params
                   progressBlock:(YJYYGetProgress)progressBlock
                    successBlock:(YJYYResponseSuccessBlock)successBlock
                       failBlock:(YJYYResponseFailBlock)failBlock {
    YJYYURLSessionTask *session = nil;
    
    AFHTTPSessionManager *manager = [self manager];
    
    if (networkStatus == YJYYNetworkStatusNotReachable) {
        if (failBlock) failBlock(YJYY_ERROR);
        return session;
    }
    
    id responseObj = [self getCacheResponseObjectWithRequestUrl:url params:params];
    
    if (responseObj && cache) {
        if (successBlock) successBlock(responseObj);
    }
    
    session = [manager GET:url
                parameters:params
                  progress:^(NSProgress * _Nonnull downloadProgress) {
                      if (progressBlock) progressBlock(downloadProgress.completedUnitCount,
                                                       downloadProgress.totalUnitCount);
                      
                  } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                      if (successBlock) successBlock(responseObject);
                      
                      if (cache) [self cacheResponseObject:responseObject requestUrl:url params:params];
                      
                      [[self allTasks] removeObject:session];
    
                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                      if (failBlock) failBlock(error);
                      [[self allTasks] removeObject:session];
                      
                  }];
    
    [session resume];
    
    if (session) [[self allTasks] addObject:session];
    
    return session;
}

#pragma mark - post
+ (YJYYURLSessionTask *)postWithUrl:(NSString *)url
                            cache:(BOOL)cache
                           params:(NSDictionary *)params
                    progressBlock:(YJYYPostProgress)progressBlock
                     successBlock:(YJYYResponseSuccessBlock)successBlock
                        failBlock:(YJYYResponseFailBlock)failBlock {
    YJYYURLSessionTask *session = nil;
    
    AFHTTPSessionManager *manager = [self manager];
    
    if (networkStatus == YJYYNetworkStatusNotReachable) {
        if (failBlock) failBlock(YJYY_ERROR);
        return session;
    }
    
    id responseObj = [self getCacheResponseObjectWithRequestUrl:url params:params];
    
    if (responseObj && cache) {
        if (successBlock) successBlock(responseObj);
    }
    
    session = [manager POST:url
                 parameters:params
                   progress:^(NSProgress * _Nonnull uploadProgress) {
                       if (progressBlock) progressBlock(uploadProgress.completedUnitCount,
                                                        uploadProgress.totalUnitCount);
                       
                   } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                       if (successBlock) successBlock(responseObject);
                       
                       if (cache) [self cacheResponseObject:responseObject requestUrl:url params:params];
                       
                       [[self allTasks] removeObject:session];
                       
                   } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                       if (failBlock) failBlock(error);
                       [[self allTasks] removeObject:session];
                       
                   }];
    
    [session resume];
    
    if (session) [[self allTasks] addObject:session];
    
    return session;
    
}

#pragma mark - 文件上传
+ (YJYYURLSessionTask *)uploadFileWithUrl:(NSString *)url
                               fileData:(NSData *)data
                                   type:(NSString *)type
                                   name:(NSString *)name
                               mimeType:(NSString *)mimeType
                          progressBlock:(YJYYUploadProgressBlock)progressBlock
                           successBlock:(YJYYResponseSuccessBlock)successBlock
                              failBlock:(YJYYResponseFailBlock)failBlock {
    YJYYURLSessionTask *session = nil;
    
    AFHTTPSessionManager *manager = [self manager];
    
    if (networkStatus == YJYYNetworkStatusNotReachable) {
        if (failBlock) failBlock(YJYY_ERROR);
        return session;
    }
    
    session = [manager POST:url
                 parameters:nil
  constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
      NSString *fileName = nil;
      
      NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
      formatter.dateFormat = @"yyyyMMddHHmmss";
      
      NSString *day = [formatter stringFromDate:[NSDate date]];
      
      fileName = [NSString stringWithFormat:@"%@.%@",day,type];
      
      [formData appendPartWithFileData:data name:name fileName:fileName mimeType:mimeType];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progressBlock) progressBlock (uploadProgress.completedUnitCount,uploadProgress.totalUnitCount);
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (successBlock) successBlock(responseObject);
        [[self allTasks] removeObject:session];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failBlock) failBlock(error);
        [[self allTasks] removeObject:session];
        
    }];
    
    [session resume];
    
    if (session) [[self allTasks] addObject:session];
    
    return session;
}

#pragma mark - 多文件上传
+ (NSArray *)uploadMultFileWithUrl:(NSString *)url
                         fileDatas:(NSArray *)datas
                              type:(NSString *)type
                              name:(NSString *)name
                          mimeType:(NSString *)mimeTypes
                     progressBlock:(YJYYUploadProgressBlock)progressBlock
                      successBlock:(YJYYMultUploadSuccessBlock)successBlock
                         failBlock:(YJYYMultUploadFailBlock)failBlock {
    
    if (networkStatus == YJYYNetworkStatusNotReachable) {
        if (failBlock) failBlock(@[YJYY_ERROR]);
        return nil;
    }
    
    __block NSMutableArray *sessions = [NSMutableArray array];
    __block NSMutableArray *responses = [NSMutableArray array];
    __block NSMutableArray *failResponse = [NSMutableArray array];
    
    dispatch_group_t uploadGroup = dispatch_group_create();
    
    NSInteger count = datas.count;
    for (int i = 0; i < count; i++) {
        YJYYURLSessionTask *session = nil;
        
        dispatch_group_enter(uploadGroup);
        
        session = [self uploadFileWithUrl:url
                                 fileData:datas[i]
                                     type:type name:name
                                 mimeType:mimeTypes
                            progressBlock:^(int64_t bytesWritten, int64_t totalBytes) {
                                if (progressBlock) progressBlock(bytesWritten,
                                                                 totalBytes);
                                
                            } successBlock:^(id response) {
                                [responses addObject:response];
                                
                                dispatch_group_leave(uploadGroup);
                                
                                [sessions removeObject:session];
                                
                            } failBlock:^(NSError *error) {
                                NSError *Error = [NSError errorWithDomain:url code:-999 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"第%d次上传失败",i]}];
                                
                                [failResponse addObject:Error];
                                
                                dispatch_group_leave(uploadGroup);
                                
                                [sessions removeObject:session];
                            }];
        
        [session resume];
        
        if (session) [sessions addObject:session];
    }
    
    [[self allTasks] addObjectsFromArray:sessions];
    
    dispatch_group_notify(uploadGroup, dispatch_get_main_queue(), ^{
        if (responses.count > 0) {
            if (successBlock) {
                successBlock([responses copy]);
                if (sessions.count > 0) {
                    [[self allTasks] removeObjectsInArray:sessions];
                }
            }
        }
        
        if (failResponse.count > 0) {
            if (failBlock) {
                failBlock([failResponse copy]);
                if (sessions.count > 0) {
                    [[self allTasks] removeObjectsInArray:sessions];
                }
            }
        }
        
    });
    
    return [sessions copy];
}

#pragma mark - 下载
+ (YJYYURLSessionTask *)downloadWithUrl:(NSString *)url
                        progressBlock:(YJYYDownloadProgress)progressBlock
                         successBlock:(YJYYDownloadSuccessBlock)successBlock
                            failBlock:(YJYYDownloadFailBlock)failBlock {
    NSString *type = nil;
    NSArray *subStringArr = nil;
    YJYYURLSessionTask *session = nil;
    
    NSURL *fileUrl = [self getDownloadDataFromCacheWithRequestUrl:url];
    
    if (fileUrl) {
        if (successBlock) successBlock(fileUrl);
        return session;
    }
    
    if (url) {
        subStringArr = [url componentsSeparatedByString:@"."];
        if (subStringArr.count > 0) {
            type = subStringArr[subStringArr.count - 1];
        }
    }
    
    AFHTTPSessionManager *manager = [self manager];
    //响应内容序列化为二进制
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    session = [manager GET:url
                parameters:nil
                  progress:^(NSProgress * _Nonnull downloadProgress) {
                      if (progressBlock) progressBlock(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
                      
                  } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                      if (successBlock) {
                          NSData *dataObj = (NSData *)responseObject;
                          
                          [self storeDownloadData:dataObj requestUrl:url];
                          
                          NSURL *downFileUrl = [self getDownloadDataFromCacheWithRequestUrl:url];
                          
                          successBlock(downFileUrl);
                      }
                      
                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                      if (failBlock) {
                          failBlock (error);
                      }
                  }];
    
    [session resume];
    
    if (session) [[self allTasks] addObject:session];
    
    return session;
    
}

#pragma mark - other method
+ (void)setupTimeout:(NSTimeInterval)timeout {
    requestTimeout = timeout;
}

+ (void)cancleAllRequest {
    @synchronized (self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(YJYYURLSessionTask  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[YJYYURLSessionTask class]]) {
                [obj cancel];
            }
        }];
        [[self allTasks] removeAllObjects];
    }
}

+ (void)cancelRequestWithURL:(NSString *)url {
    if (!url) return;
    @synchronized (self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(YJYYURLSessionTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[YJYYURLSessionTask class]]) {
                if ([obj.currentRequest.URL.absoluteString hasSuffix:url]) {
                    [obj cancel];
                    *stop = YES;
                }
            }
        }];
    }
}

+ (void)configHttpHeader:(NSDictionary *)httpHeader {
    headers = httpHeader;
}


@end
