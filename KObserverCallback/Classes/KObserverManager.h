//
//  KObserverManager.h
//  ObserverManager
//
//  Created by 柯平 on 2019/4/10.
//  Copyright © 2019 柯平. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol KObserverManager <NSObject>

-(void)notifyObserver:(NSInteger)type state:(NSInteger)state param:(NSDictionary*)params;

-(void)addObserver:(id)observer withType:(NSInteger)type;

-(void)deleteObserver:(id)observer withType:(NSInteger)type;

-(void)removeAllObserver:(id)observer;

#ifdef __cplusplus
extern "C"{
#endif
    
    id<KObserverManager> kGetObserverManager(void);
    
#ifdef __cplueplus
}
#endif

@end

@protocol KObserverCallback <NSObject>

-(void)observerCallbackWithType:(NSInteger)type state:(NSInteger)state object:(NSDictionary*)params;

@end

NS_ASSUME_NONNULL_END
