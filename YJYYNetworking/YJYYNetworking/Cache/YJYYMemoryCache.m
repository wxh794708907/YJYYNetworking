//
//  YJYYMemoryCache.m
//  YJYYNetworking
//
//  Created by YJYY on 2016/7/25.
//  Copyright © 2016年 YJYY. All rights reserved.
//

#import "YJYYMemoryCache.h"

static NSCache *shareCache;

@implementation YJYYMemoryCache

+ (NSCache *)shareCache {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (shareCache == nil) shareCache = [[NSCache alloc] init];
    });
    return shareCache;
}

+ (void)writeData:(id)data forKey:(NSString *)key {
    assert(data);
    
    assert(key);
    
    NSCache *cache = [YJYYMemoryCache shareCache];
    
    [cache setObject:data forKey:key];
    
}

+ (id)readDataWithKey:(NSString *)key {
    assert(key);
    
    id data = nil;
    
    NSCache *cache = [YJYYMemoryCache shareCache];
    
    data = [cache objectForKey:key];
    
    return data;
}

@end
