//
//  ESMSNService.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#import "GaimService.h"

#define PREF_GROUP_MSN_SERVICE			@"MSN"
#define	KEY_MSN_DISPLAY_NAMES_AS_STATUS	@"Display Names As Status"
#define	KEY_MSN_CONVERSATION_CLOSED		@"Conversation Closed"
#define	KEY_MSN_CONVERSATION_TIMED_OUT	@"Conversation Timed Out"


@class AIPreferencePane;

@interface ESMSNService : GaimService {
	AIPreferencePane	*MSNServicePrefs;
}
@end
