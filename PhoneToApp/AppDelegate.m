//
//  AppDelegate.m
//  PhoneToApp
//
//  Created by Abdulhakim Ajetunmobi on 21/08/2020.
//  Copyright © 2020 Vonage. All rights reserved.
//

#import "AppDelegate.h"
#import "ClientManager.h"
#import "PushKit/PushKit.h"
#import "ProviderDelegate.h"

@interface AppDelegate () <PKPushRegistryDelegate>
//@property ClientManager* clientManager;
@property ProviderDelegate* providerDelegate;
@end

@implementation AppDelegate

- (instancetype)init
{
    self = [super init];
    if (self) {
//        self.clientManager = ;
        self.providerDelegate = [[ProviderDelegate alloc] init];
    }
    return self;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [AVAudioSession.sharedInstance requestRecordPermission:^(BOOL granted) {
        NSLog(@"Allow microphone use. Response: %d", granted);
    }];
    [self registerForVoIPPushes];
    [ClientManager.shared login];
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {}

/*
 Register for voip push notifications.
 */
- (void) registerForVoIPPushes {
    PKPushRegistry* voipRegistry = [[PKPushRegistry alloc] initWithQueue:nil];
    voipRegistry.delegate = self;
    voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

/*
 This provides the client manager with the push notification token.
 */
- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)pushCredentials forType:(PKPushType)type {
    ClientManager.shared.pushToken = pushCredentials.token;
}

/*
 If the push notification token becomes invalid,
 the client manager needs to remove it.
 */
- (void)pushRegistry:(PKPushRegistry *)registry didInvalidatePushTokenForType:(PKPushType)type {
    [ClientManager.shared invalidatePushToken];
}

/*
 This function is called when the app receives a voip push notification.
 The client checks if it is a valid Nexmo push,
 then reports the call to the system using the providerDelegate.
 */
- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type withCompletionHandler:(void (^)(void))completion {
    if ([ClientManager.shared isNexmoPushWith:payload.dictionaryPayload]) {
        ClientManager.shared.payload = payload;
        ClientManager.shared.completion = completion;
        [self.providerDelegate reportCall:@"Vonage Call"];
    }
}

@end
