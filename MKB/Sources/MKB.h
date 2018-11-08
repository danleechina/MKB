//
//  MKB.h
//  Test
//
//  Created by Dan Lee on 2018/11/8.
//  Copyright © 2018 Dan Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKB : NSObject

+ (instancetype)defaultMKB;
+ (instancetype)mkbWithID:(NSString *)mkbId;

- (nullable id)objectForKey:(NSString *)defaultName;
- (void)setObject:(nullable id)value forKey:(NSString *)defaultName;
- (void)removeObjectForKey:(NSString *)defaultName;
- (BOOL)synchronize;

@end

NS_ASSUME_NONNULL_END
