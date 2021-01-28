//
//  ViewController.m
//  PhoneToApp
//
//  Created by Abdulhakim Ajetunmobi on 21/08/2020.
//  Copyright © 2020 Vonage. All rights reserved.
//

#import "ViewController.h"
#import <NexmoClient/NexmoClient.h>

@interface ViewController ()
@property UILabel *connectionStatusLabel;
@property NXMCall *call;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.connectionStatusLabel = [[UILabel alloc] init];
    self.connectionStatusLabel.text = @"Unknown";
    self.connectionStatusLabel.textAlignment = NSTextAlignmentCenter;
    self.connectionStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.connectionStatusLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.connectionStatusLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
        [self.connectionStatusLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.connectionStatusLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20]
    ]];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(statusReceived:) name:@"Status" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(callReceived:) name:@"Call" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(callHandled:) name:@"CallHandledCallKit" object:nil];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

/*
 When the Nexmo client status changes,
 the clientStatus notification will call this function.
 This function will update the connectionStatusLabel.
 */
- (void)statusReceived:(NSNotification *) notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *status = notification.object;
        self.connectionStatusLabel.text = status;
    });
}

/*
 When the app receives a call,
 the incomingCall notification will call this function.
 It will display an alert to allow for the call to be answered.
 */
- (void)callReceived:(NSNotification *) notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        NXMCall *call = notification.object;
        if (call != nil) {
            [self displayIncomingCallAlert:call];
        }
    });
}

/*
 If the call is handled with the CallKit UI,
 the handledCallCallKit notification will call this function.
 This function will check if the incoming call alert is showing and dismiss it.
 */
- (void)callHandled:(NSNotification *) notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.presentedViewController != nil) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    });
}

- (void)displayIncomingCallAlert:(NXMCall *)call {
    NSString *from = call.otherCallMembers.firstObject.channel.from.data;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Incoming call from" message:from preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Answer" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.call = call;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CallHandledApp" object:nil];
        [call answer:nil];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Reject" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CallHandledApp" object:nil];
        [call reject:nil];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end
