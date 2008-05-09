//
//  AIFacebookIncomingMessageManager.h
//  Adium
//
//  Created by Evan Schoenberg on 5/8/08.
//

#import <Adium/AIObject.h>

@class AIFacebookAccount;

@interface AIFacebookIncomingMessageManager : AIObject {
	AIFacebookAccount	*account;
	NSURLConnection		*loveConnection;
	NSMutableData		*receivedData;
	
	NSString	*channel;
	NSString	*facebookUID;
	int			sequenceNumber;
}

+ (AIFacebookIncomingMessageManager *)incomingMessageManagerForAccount:(AIFacebookAccount *)inAccount;
- (void)disconnect;

@end
