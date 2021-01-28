//
//  ClientManager.m
//  PhoneToApp
//
//  Created by Abdulhakim Ajetunmobi on 27/01/2021.
//  Copyright © 2021 Vonage. All rights reserved.
//

#import "ClientManager.h"
#import "PushKit/PushKit.h"
#import <NexmoClient/NexmoClient.h>

/*
 This class provides an interface to the Nexmo Client that can
 be accessed across the app. It handles logging the client in
 and updated to the client's status. The JWT is hardcoded but in
 your production app this should be retrieved from your server.
 */
@interface ClientManager () <NXMClientDelegate>
@property (nonatomic, nonnull) NSString *jwt;
@end

@implementation ClientManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.jwt = @"ALICE_JWT";
        [self initializeClient];
    }
    return self;
}

+ (nonnull ClientManager *)shared {
    static ClientManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [ClientManager new];
    });
    
    return sharedInstance;
}

- (void)initializeClient {
    [NXMClient.shared setDelegate:self];
}

- (void)login {
    if (![NXMClient.shared isConnected]) {
        [NXMClient.shared loginWithAuthToken:self.jwt];
    }
}

- (BOOL)isNexmoPushWith:(NSDictionary<NSObject *, id> *)userInfo {
    return [NXMClient.shared isNexmoPushWithUserInfo:userInfo];
}

- (void)invalidatePushToken {
    self.pushToken = nil;
    [NSUserDefaults.standardUserDefaults removeObjectForKey:@"NXMPushToken"];
    [NXMClient.shared disablePushNotifications:nil];
}

// MARK:-  Private


/*
 This function process the payload from the voip push notification.
 This in turn will call didReceive for the app to handle the incoming call.
 */
- (void)processNexmoPushPayloadWithPayload:(PKPushPayload *)payload completion:(void (^)(void))completion {
    if ([NXMClient.shared processNexmoPushPayload:payload.dictionaryPayload]) {
        self.completion();
        self.payload = nil;
        self.completion = nil;
    }
}

/*
 This function enabled push notifications with the client
 if it has not already been done for the current token.
 */
- (void)enableNXMPushIfNeededWithToken:(NSData *)token {
    if ([self shouldRegisterWithToken:token]) {
        [NXMClient.shared enablePushNotificationsWithPushKitToken:token userNotificationToken:nil isSandbox:YES completionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"registration error: %@", error.localizedDescription);
            }
            NSLog(@"push token registered");
            [NSUserDefaults.standardUserDefaults setValue:token forKey:@"NXMPushToken"];
        }];
    }
}

/*
 Push tokens only need to be registered once.
 So the token is stored locally and is invalidated if the incoming
 token is new.
 */
- (BOOL)shouldRegisterWithToken:(NSData *)token {
    NSData *storedToken = [NSUserDefaults.standardUserDefaults objectForKey:@"NXMPushToken"];
    
    if (storedToken != nil && [storedToken isEqualToData:token]) {
        return false;
    }
    
    [self invalidatePushToken];
    return true;
}


// MARK:-  NXMClientDelegate

/*
 When the status of the client changes, this function is called.
 The status is sent via the clientStatus notification.
 */
- (void)client:(nonnull NXMClient *)client didChangeConnectionStatus:(NXMConnectionStatus)status reason:(NXMConnectionStatusReason)reason {
    NSString *statusString = @"Unknown";
    
    switch (status) {
        case NXMConnectionStatusConnected:
            if (self.pushToken != nil) {
                [self enableNXMPushIfNeededWithToken:self.pushToken];
            }
            if (self.payload != nil && self.completion != nil) {
                [self processNexmoPushPayloadWithPayload:self.payload completion:self.completion];
            }
            statusString = @"Connected";
            break;
        case NXMConnectionStatusDisconnected:
            statusString = @"Disconnected";
            break;
        case NXMConnectionStatusConnecting:
            statusString = @"Connecting";
            break;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Status" object:statusString];
}

/*
 If the Nexmo client receives a call, this function is called.
 This is trigged by processing an incoming push notification.
 The call is sent via the incomingCall notification.
 */
- (void)client:(NXMClient *)client didReceiveCall:(NXMCall *)call {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Call" object:call];
}

/*
 If the Nexmo client receives and error, this function is called.
 The status is sent via the clientStatus notification.
 */
- (void)client:(nonnull NXMClient *)client didReceiveError:(nonnull NSError *)error {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Status" object:error.localizedDescription];
}

@end
