//
//  AIFacebookStatusManager.h
//  Adium
//
//  Created by Evan Schoenberg on 5/12/08.
//

#import <Cocoa/Cocoa.h>

@class AIFacebookAccount;

@interface AIFacebookStatusManager : NSObject {

}

+ (void)setFacebookStatusMessage:(NSString *)statusMessage forAccount:(AIFacebookAccount *)account;

@end
