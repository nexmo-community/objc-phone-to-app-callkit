//
//  ProviderDelegate.h
//  PhoneToApp
//
//  Created by Abdulhakim Ajetunmobi on 27/01/2021.
//  Copyright © 2021 Vonage. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProviderDelegate : NSObject
- (void)reportCall:(NSString *)callerID;
@end

NS_ASSUME_NONNULL_END
