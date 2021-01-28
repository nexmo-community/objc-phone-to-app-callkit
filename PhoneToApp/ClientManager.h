//
//  ClientManager.h
//  PhoneToApp
//
//  Created by Abdulhakim Ajetunmobi on 27/01/2021.
//  Copyright © 2021 Vonage. All rights reserved.
//

#import <Foundation/Foundation.h>
@class PKPushPayload;

NS_ASSUME_NONNULL_BEGIN

@interface ClientManager : NSObject
@property (nonatomic, nullable) NSData *pushToken;
@property (nonatomic, nullable) PKPushPayload *payload;
@property (nonatomic, nullable) void (^completion)(void);

+ (nonnull ClientManager *)shared;

- (void)initializeClient;
- (void)login;
- (void)invalidatePushToken;
- (BOOL)isNexmoPushWith:(NSDictionary<NSObject *, id> *)userInfo;

@end

NS_ASSUME_NONNULL_END
