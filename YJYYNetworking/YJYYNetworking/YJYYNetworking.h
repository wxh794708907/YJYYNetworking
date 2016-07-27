//
//  YJYYNetworking.h
//  YJYYNetworking
//
//  Created by YJYY on 2016/7/25.
//  Copyright © 2016年 YJYY. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  网络状态
 */
typedef NS_ENUM(NSInteger, YJYYNetworkStatus) {
    /**
     *  未知网络
     */
    YJYYNetworkStatusUnknown             = 1 << 0,
    /**
     *  无法连接
     */
    YJYYNetworkStatusNotReachable        = 1 << 1,
    /**
     *  WWAN网络
     */
    YJYYNetworkStatusReachableViaWWAN    = 1 << 2,
    /**
     *  WiFi网络
     */
    YJYYNetworkStatusReachableViaWiFi    = 1 << 3
};

/**
 *  请求任务
 */
typedef NSURLSessionTask YJYYURLSessionTask;

/**
 *  成功回调
 *
 *  @param response 成功后返回的数据
 */
typedef void(^YJYYResponseSuccessBlock)(id response);

/**
 *  失败回调
 *
 *  @param error 失败后返回的错误信息
 */
typedef void(^YJYYResponseFailBlock)(NSError *error);

/**
 *  下载进度
 *
 *  @param bytesWritten              已下载的大小
 *  @param totalBytes                总下载大小
 */
typedef void (^YJYYDownloadProgress)(int64_t bytesRead,
                                   int64_t totalBytes);

/**
 *  下载成功回调
 *
 *  @param url                       下载存放的路径
 */
typedef void(^YJYYDownloadSuccessBlock)(NSURL *url);


/**
 *  上传进度
 *
 *  @param bytesWritten              已上传的大小
 *  @param totalBytes                总上传大小
 */
typedef void(^YJYYUploadProgressBlock)(int64_t bytesWritten,
                                     int64_t totalBytes);
/**
 *  多文件上传成功回调
 *
 *  @param response 成功后返回的数据
 */
typedef void(^YJYYMultUploadSuccessBlock)(NSArray *responses);

/**
 *  多文件上传失败回调
 *
 *  @param error 失败后返回的错误信息
 */
typedef void(^YJYYMultUploadFailBlock)(NSArray *errors);

typedef YJYYDownloadProgress YJYYGetProgress;

typedef YJYYDownloadProgress YJYYPostProgress;

typedef YJYYResponseFailBlock YJYYDownloadFailBlock;

@interface YJYYNetworking : NSObject

/**
 *  配置请求头
 *
 *  @param httpHeader 请求头
 */
+ (void)configHttpHeader:(NSDictionary *)httpHeader;

/**
 *  取消GET请求
 */
+ (void)cancelRequestWithURL:(NSString *)url;

/**
 *  取消所有请求
 */
+ (void)cancleAllRequest;

/**
 *	设置超时时间
 *
 *  @param timeout 超时时间
 */
+ (void)setupTimeout:(NSTimeInterval)timeout;

/**
 *  GET请求
 *
 *  @param url              请求路径
 *  @param cache            是否缓存
 *  @param params           拼接参数
 *  @param progressBlock    进度回调
 *  @param successBlock     成功回调
 *  @param failBlock        失败回调
 *
 *  @return 返回的对象中可取消请求
 */
+ (YJYYURLSessionTask *)getWithUrl:(NSString *)url
                            cache:(BOOL)cache
                           params:(NSDictionary *)params
                    progressBlock:(YJYYGetProgress)progressBlock
                     successBlock:(YJYYResponseSuccessBlock)successBlock
                        failBlock:(YJYYResponseFailBlock)failBlock;




/**
 *  POST请求
 *
 *  @param url              请求路径
 *  @param cache            是否缓存
 *  @param params           拼接参数
 *  @param progressBlock    进度回调
 *  @param successBlock     成功回调
 *  @param failBlock        失败回调
 *
 *  @return 返回的对象中可取消请求
 */
+ (YJYYURLSessionTask *)postWithUrl:(NSString *)url
                             cache:(BOOL)cache
                            params:(NSDictionary *)params
                     progressBlock:(YJYYPostProgress)progressBlock
                      successBlock:(YJYYResponseSuccessBlock)successBlock
                         failBlock:(YJYYResponseFailBlock)failBlock;




/**
 *  文件上传
 *
 *  @param url              上传文件接口地址
 *  @param data             上传文件数据
 *  @param type             上传文件类型
 *  @param name             上传文件服务器文件夹名
 *  @param mimeType         mimeType
 *  @param progressBlock    上传文件路径
 *	@param successBlock     成功回调
 *	@param failBlock		失败回调
 *
 *  @return 返回的对象中可取消请求
 */
+ (YJYYURLSessionTask *)uploadFileWithUrl:(NSString *)url
                                fileData:(NSData *)data
                                    type:(NSString *)type
                                    name:(NSString *)name
                                mimeType:(NSString *)mimeType
                           progressBlock:(YJYYUploadProgressBlock)progressBlock
                            successBlock:(YJYYResponseSuccessBlock)successBlock
                               failBlock:(YJYYResponseFailBlock)failBlock;


/**
 *  多文件上传
 *
 *  @param url           上传文件地址
 *  @param datas         数据集合
 *  @param type          类型
 *  @param name          服务器文件夹名
 *  @param mimeType      mimeTypes
 *  @param progressBlock 上传进度
 *  @param successBlock  成功回调
 *  @param failBlock     失败回调
 *
 *  @return 任务集合
 */
+ (NSArray *)uploadMultFileWithUrl:(NSString *)url
                         fileDatas:(NSArray *)datas
                              type:(NSString *)type
                              name:(NSString *)name
                          mimeType:(NSString *)mimeTypes
                     progressBlock:(YJYYUploadProgressBlock)progressBlock
                      successBlock:(YJYYMultUploadSuccessBlock)successBlock
                         failBlock:(YJYYMultUploadFailBlock)failBlock;

/**
 *  文件下载
 *
 *  @param url           下载文件接口地址
 *  @param progressBlock 下载进度
 *  @param successBlock  成功回调
 *  @param failBlock     下载回调
 *
 *  @return 返回的对象可取消请求
 */
+ (YJYYURLSessionTask *)downloadWithUrl:(NSString *)url
                        progressBlock:(YJYYDownloadProgress)progressBlock
                         successBlock:(YJYYDownloadSuccessBlock)successBlock
                            failBlock:(YJYYDownloadFailBlock)failBlock;


@end
