//
//  MKB.m
//  Test
//
//  Created by Dan Lee on 2018/11/8.
//  Copyright © 2018 Dan Lee. All rights reserved.
//

#import "MKB.h"
#import <UIKit/UIKit.h>
#import "ScopedLock.hpp"

#define DEFAULT_MKB_NAME @"mkb.default"

@interface MKB ()

@property (nonatomic, strong) NSMutableDictionary *dict;
@property (nonatomic, strong) NSRecursiveLock *rLock;
@property (nonatomic, copy) NSString *mkbID;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, assign) BOOL isNeedRestore;
@property (nonatomic, assign) BOOL hasSaved;
- (BOOL)saveData;

@end

static NSRecursiveLock *mkb_g_instanceLock;
static NSMutableDictionary *mkb_g_id2InstanceDict;
static NSUncaughtExceptionHandler *mkb_g_originalExceptionHandler;

static void mkb_g_uncaughtExceptionHandler(NSException *exception) {
    for (MKB *mkb in mkb_g_id2InstanceDict.allValues) {
        [mkb saveData];
    }
    if (mkb_g_originalExceptionHandler) {
        mkb_g_originalExceptionHandler(exception);
    }
}

@implementation MKB

+ (void)initialize {
    if (self == MKB.class) {
        mkb_g_id2InstanceDict = [NSMutableDictionary dictionary];
        mkb_g_originalExceptionHandler = NSGetUncaughtExceptionHandler();
        mkb_g_instanceLock = [[NSRecursiveLock alloc] init];
        NSSetUncaughtExceptionHandler(&mkb_g_uncaughtExceptionHandler);
    }
}

+ (instancetype)defaultMKB {
    return [self mkbWithID:DEFAULT_MKB_NAME];
}

+ (instancetype)mkbWithID:(NSString *)mkbId {
    if (mkbId.length <= 0) return nil;
    CScopedLock lock(mkb_g_instanceLock);
    MKB *mkb = mkb_g_id2InstanceDict[mkbId];
    if (mkb == nil) {
        mkb = [[MKB alloc] initWithMKBID:mkbId];
        mkb_g_id2InstanceDict[mkbId] = mkb;
    }
    return mkb;
}

+ (NSString *)filePathWithID:(NSString *)mkbID {
    NSString *documentPath = (NSString *)[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *folderPath = [documentPath stringByAppendingFormat:@"/mkb"];
    if (![NSFileManager.defaultManager fileExistsAtPath:folderPath]) {
        NSError *error;
        [NSFileManager.defaultManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"%@", error);
        }
    }
    return [folderPath stringByAppendingFormat:@"/%@", mkbID];
}

- (instancetype)initWithMKBID:(NSString *)mkbID {
    self = [super init];
    if (self) {
        _dict = [NSMutableDictionary dictionary];
        _mkbID = mkbID;
        _filePath = [MKB filePathWithID:mkbID];
        [self restoreData];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willTerminate) name:UIApplicationWillTerminateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(significantTimeDidChange) name:UIApplicationSignificantTimeChangeNotification object:nil];
        
    }
    return self;
}

#pragma mark - Util Methods

- (BOOL)saveData {
    CScopedLock lock(self.rLock);
    if (self.hasSaved) return YES;
    if (![NSJSONSerialization isValidJSONObject:self.dict]) {
        return NO;
    }
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.dict options:NSJSONWritingPrettyPrinted error:&error];
    if (error != nil) {
        NSLog(@"%@", error);
        return NO;
    }
    if (!data) return NO;
    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [jsonString writeToFile:self.filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error != nil) {
        NSLog(@"%@", error);
        return NO;
    }
    self.hasSaved = true;
    return YES;
}

- (void)restoreData {
    CScopedLock lock(self.rLock);
    NSData *data = [[NSData alloc] initWithContentsOfFile:self.filePath];
    if (!data) return;
    NSError *error;
    NSDictionary *savedDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (error != nil) {
        NSLog(@"%@", error);
    }
    if (savedDict != nil) {
        self.isNeedRestore = NO;
        for (id key in savedDict.allKeys) {
            self.dict[key] = savedDict[key];
        }
    }
}

- (void)clearAll {
    CScopedLock lock(self.rLock);
    [self.dict removeAllObjects];
    self.isNeedRestore = YES;
}

#pragma mark - Notifications Methods

- (void)onMemoryWarning {
    [self saveData];
    [self clearAll];
}

- (void)didEnterBackground {
    [self saveData];
}

- (void)didBecomeActive {
    [self saveData];
}

- (void)willResignActive {
    [self saveData];
}

- (void)willTerminate {
    [self saveData];
}

- (void)significantTimeDidChange {
    [self saveData];
}

#pragma mark - Public Methods

- (nullable id)objectForKey:(NSString *)defaultName {
    if (self.isNeedRestore) {
        [self restoreData];
    }
    return self.dict[defaultName];
}

- (void)setObject:(nullable id)value forKey:(NSString *)defaultName {
    self.hasSaved = NO;
    self.dict[defaultName] = value;
}

- (void)removeObjectForKey:(NSString *)defaultName {
    self.hasSaved = NO;
    [self.dict removeObjectForKey:defaultName];
}

- (BOOL)synchronize {
    return [self saveData];
}

// TODO: lots of easy methods to write...

@end
