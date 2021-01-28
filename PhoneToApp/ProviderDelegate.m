//
//  ProviderDelegate.m
//  PhoneToApp
//
//  Created by Abdulhakim Ajetunmobi on 27/01/2021.
//  Copyright © 2021 Vonage. All rights reserved.
//

#import "PushKit/PushKit.h"
#import "ProviderDelegate.h"
#import <CallKit/CallKit.h>
#import <NexmoClient/NexmoClient.h>
#import <AVFoundation/AVFoundation.h>


@interface PushCall: NSObject
@property (nonatomic, nullable) NXMCall *call;
@property (nonatomic, nullable) NSUUID *uuid;
@property (nonatomic, nullable) void (^answerBlock)(void);
@end

@implementation PushCall


@end

@interface ProviderDelegate () <NXMCallDelegate, CXProviderDelegate>
@property (nonatomic, nonnull) CXProvider *provider;
@property (nonatomic, nonnull) CXCallController *callController;
@property (nonatomic, nullable) PushCall *activeCall;
@end

@implementation ProviderDelegate

- (instancetype)init
{
    self = [super init];
    if (self) {
        CXProviderConfiguration *config = [[CXProviderConfiguration alloc] initWithLocalizedName:@"Vonage Call"];
        config.supportsVideo = NO;
        config.maximumCallsPerCallGroup = 1;
        config.supportedHandleTypes = [[NSSet alloc] initWithObjects:[NSNumber numberWithInt:CXHandleTypeGeneric], nil];
        self.provider = [[CXProvider alloc] initWithConfiguration:config];
        [self.provider setDelegate:self queue:nil];
        
        self.callController = [[CXCallController alloc] init];
        self.activeCall = [[PushCall alloc] init];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(callReceived:) name:@"Call" object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(callHandled:) name:@"CallHandledApp" object:nil];
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

// MARK:-  NXMCallDelegate

/*
 The NXMCallDelegate keeps track of the call.
 Particularly, when the call receives an error
 or enters an end state hangup is called.
 */
- (void)call:(NXMCall *)call didReceive:(NSError *)error {
    NSLog(@"%@", error.localizedDescription);
    [self hangup];
}

- (void)call:(NXMCall *)call didUpdate:(NXMCallMember *)callMember withStatus:(NXMCallMemberStatus)status {
    switch (status) {
        case NXMCallMemberStatusCanceled:
        case NXMCallMemberStatusFailed:
        case NXMCallMemberStatusTimeout:
        case NXMCallMemberStatusRejected:
        case NXMCallMemberStatusCompleted:
            [self hangup];
            break;
        default :
            break;
    }
}

- (void)call:(NXMCall *)call didUpdate:(NXMCallMember *)callMember isMuted:(BOOL)muted {}

/*
 When a call is ended,
 the callController.request function completes the action.
 */
- (void)hangup {
    if (self.activeCall.uuid != nil && self.activeCall.call != nil) {
        [self.activeCall.call hangup];
        self.activeCall = [[PushCall alloc] init];
        
        CXEndCallAction *action = [[CXEndCallAction alloc] initWithCallUUID:self.activeCall.uuid];
        CXTransaction *transaction = [[CXTransaction alloc] initWithAction:action];
        
        [self.callController requestTransaction:transaction completion:^(NSError * _Nullable error) {
            if (error != nil) {
                NSLog(@"%@", error.localizedDescription);
            }
        }];
    }
}

// MARK:-  CXProviderDelegate

- (void)providerDidReset:(CXProvider *)provider {
    self.activeCall = [[PushCall alloc] init];
}

/*
 When the call is answered via the CallKit UI, this function is called.
 If the device is locked, the client needs time to reinitialize,
 so the answerCall actions are store in a closure. If the app is in the
 foreground, the call is ready to be answered.
 
 The handledCallCallKit notification is sent so that the ViewController
 knows that the call has been handled by CallKit and can dismiss the alert.
 */
- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallHandledCallKit" object:nil];
    if (self.activeCall.call != nil) {
        [self answerCallWithAction:action];
    } else {
        __weak typeof(self) weakSelf = self;
        self.activeCall.answerBlock = ^void() {
            if (self.activeCall != nil) {
                __strong typeof(self) strongSelf = weakSelf;
                [strongSelf answerCallWithAction:action];
            }
        };
    }
}

- (void)answerCallWithAction:(CXAnswerCallAction *)action {
    [self configureAudioSession];
    [self.activeCall.call answer:nil];
    [self.activeCall.call setDelegate:self];
    self.activeCall.uuid = action.callUUID;
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action {
    [self hangup];
}

- (void)reportCall:(NSString *)callerID {
    CXCallUpdate *update = [[CXCallUpdate alloc] init];
    NSUUID *callerUUID = [[NSUUID alloc] init];
    
    update.remoteHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:callerID];
    update.localizedCallerName = callerID;
    update.hasVideo = false;
    
    [self.provider reportNewIncomingCallWithUUID:callerUUID update:update completion:^(NSError * _Nullable error) {
        if (error != nil) {
            self.activeCall.uuid = callerUUID;
        }
    }];
}

/*
 If the app is in the foreground and the call is answered via the
 ViewController alert, there is no need to display the CallKit UI.
 */
- (void)callHandled:(NSNotification *) notification {
    [self.provider invalidate];
}

/*
 This function is called with the incomingCall notification.
 If the device is locked, it will call the answer call closure
 created in the CXAnswerCallAction delegate function.
 */
- (void)callReceived:(NSNotification *) notification {
    NXMCall *call = notification.object;
    if (call != nil) {
        self.activeCall.call = call;
        if (self.activeCall.answerBlock != nil) {
            self.activeCall.answerBlock();
        }
    }
}

/*
 When the device is locked, the AVAudioSession needs to be configured.
 You can read more about this issue here https://forums.developer.apple.com/thread/64544
 */
- (void)configureAudioSession {
    AVAudioSession *audioSession = AVAudioSession.sharedInstance;
    NSError *error = nil;
    
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    [audioSession setMode:AVAudioSessionModeVoiceChat error:&error];
    
    if (error != nil) {
        NSLog(@"%@", error.localizedDescription);
    }
}

@end
