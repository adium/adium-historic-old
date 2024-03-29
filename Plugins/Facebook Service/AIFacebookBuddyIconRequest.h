//
//  AIFacebookBuddyIconRequest.h
//  Adium
//
//  Created by Evan Schoenberg on 5/8/08.
//

#import <Cocoa/Cocoa.h>

@class AIListContact;

@interface AIFacebookBuddyIconRequest : NSObject {
	AIListContact *contact;
	NSURLConnection *connection;
	NSMutableData	*receivedData;
}

+ (void)retrieveBuddyIconForContact:(AIListContact *)inContact withThumbSrc:(NSString *)thumbSrc;

@end
