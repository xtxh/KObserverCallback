//
//  KObserverOperation.m
//  ObserverManager
//
//  Created by 柯平 on 2019/4/10.
//  Copyright © 2019 柯平. All rights reserved.
//

#import "KObserverOperation.h"

#ifndef kObserver_LOCK
#define kObserver_LOCK(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#endif

#ifndef kObserver_UNLOCK
#define kObserver_UNLOCK(lock) dispatch_semaphore_signal(lock);
#endif

@interface KObserverOperation () <KObserverManager>

@property(nonatomic, strong, nonnull) NSMutableDictionary *observerCache;
@property(nonatomic, strong, nonnull) dispatch_semaphore_t lock;

+(instancetype)sharedOperation;

@end

@implementation KObserverOperation

+(instancetype)sharedOperation{
    static KObserverOperation* _operation = nil;
    static dispatch_once_t oncetoken;
    dispatch_once(&oncetoken, ^{
        _operation = [[KObserverOperation alloc] init];
    });
    return _operation;
}

-(instancetype)init{
    self = [super init];
    if (self) {
        _observerCache = [NSMutableDictionary dictionaryWithCapacity:0];
        _lock = dispatch_semaphore_create(1);
    }
    return self;
}

-(NSMutableArray*)noRetainArray{
    return [self noRetainArrayWithCapacity:0];
}

-(NSMutableArray*)noRetainArrayWithArray:(NSArray*)array{
    NSMutableArray* noRetainArray = [self noRetainArray];
    if (array && array.count) [noRetainArray addObjectsFromArray:array];
    return noRetainArray;
}

-(NSMutableArray*)noRetainArrayWithCapacity:(NSUInteger)capacity{
    //CFArrayCallBacks callbacks = {0};
    CFArrayCallBacks callbacks = {0, NULL, NULL, CFCopyDescription, CFEqual};
    CFMutableArrayRef cfArray = CFArrayCreateMutable(CFAllocatorGetDefault(), capacity, &callbacks);
    return CFBridgingRelease(cfArray);
}

#pragma mark - KObserverManager
id <KObserverManager> kGetObserverManager(void) {
    return [KObserverOperation sharedOperation];
}

-(void)addObserver:(id)observer withType:(NSInteger)type{
    if (!observer) return;
    NSNumber* key = [NSNumber numberWithInteger:type];
    kObserver_LOCK(self.lock)
    NSMutableArray* observers = [self.observerCache objectForKey:key];
    if (!observers) {
        observers = [self noRetainArrayWithCapacity:0];
        [self.observerCache setObject:observers forKey:key];
    }
    if (![observers containsObject:observer]) {
        [observers addObject:observer];
    }
    kObserver_UNLOCK(self.lock)
}

-(void)deleteObserver:(id)observer withType:(NSInteger)type{
    if (!observer) return;
    NSNumber* key = [NSNumber numberWithInteger:type];
    kObserver_LOCK(self.lock);
    NSMutableArray* observers = [self.observerCache objectForKey:key];
    if (observers && [observers containsObject:observer]) {
        [observers removeObject:observer];
        if (observers.count == 0) [self.observerCache removeObjectForKey:key];
    }
    kObserver_UNLOCK(self.lock);
}

-(void)removeAllObserver:(id)observer{
    if (!observer) return;
    for (NSNumber* key in [self.observerCache allKeys]) {
        [self deleteObserver:observer withType:key.integerValue];
    }
}

-(void)notifyObserver:(NSInteger)type state:(NSInteger)state param:(NSDictionary *)params{
    NSNumber* key = [NSNumber numberWithInteger:type];
    kObserver_LOCK(self.lock)
    NSMutableArray* observers = [self.observerCache objectForKey:key];
    if (observers && observers.count > 0) {
        for (id obj in observers) {
            if (obj && [obj conformsToProtocol:@protocol(KObserverCallback)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [obj observerCallbackWithType:type state:state object:params];
                });
            }
        }
    }
    kObserver_UNLOCK(self.lock)
}

@end
