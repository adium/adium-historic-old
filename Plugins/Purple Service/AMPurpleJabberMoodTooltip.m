//
//  AMPurpleJabberMoodTooltip.m
//  Adium
//
//  Created by Andreas Monitzer on 2007-06-12.
//  Copyright 2007 Andreas Monitzer. All rights reserved.
//

#import "AMPurpleJabberMoodTooltip.h"
#import "AIListObject.h"
#import "ESPurpleJabberAccount.h"
#import <Libpurple/blist.h>

@implementation AMPurpleJabberMoodTooltip

- (id)initWithAccount:(ESPurpleJabberAccount*)_account {
	if((self = [super init])) {
		account = _account;
	}
	return self;
}

- (NSString *)labelForObject:(AIListObject *)inObject {
	if([inObject service] == [account service]) {
		PurpleBuddy *buddy = purple_find_buddy([account purpleAccount],[[inObject UID] UTF8String]);
		PurplePresence *presence = purple_buddy_get_presence(buddy);
		PurpleStatus *status = purple_presence_get_active_status(presence);
		PurpleValue *value = purple_status_get_attr_value(status, "mood");
		
		if(value && purple_value_get_type(value) == PURPLE_TYPE_STRING && purple_value_get_string(value))
			return AILocalizedString(@"Mood","user mood tooltip title");
	}
	return nil;
}

- (NSAttributedString *)entryForObject:(AIListObject *)inObject {
	if([inObject service] == [account service]) {
		PurpleBuddy *buddy = purple_find_buddy([account purpleAccount],[[inObject UID] UTF8String]);
		PurplePresence *presence = purple_buddy_get_presence(buddy);
		PurpleStatus *status = purple_presence_get_active_status(presence);
		PurpleValue *value = purple_status_get_attr_value(status, "mood");
		
		if(value && purple_value_get_type(value) == PURPLE_TYPE_STRING) {
			const char *mood = purple_value_get_string(value);
			if(mood) {
				NSString *str;
							
#warning Localization
				value = purple_status_get_attr_value(status, "moodtext");
				if(value && purple_value_get_type(value) == PURPLE_TYPE_STRING && purple_value_get_string(value) && purple_value_get_string(value)[0] != '\0')
					str = [NSString stringWithFormat:@"%@ (%@)",AILocalizedString([NSString stringWithUTF8String:mood],"This one won't work automatically. See XEP for all possible values"), [NSString stringWithUTF8String:purple_value_get_string(value)]];
				else
					str = [NSString stringWithString:AILocalizedString([NSString stringWithUTF8String:mood],"This one won't work automatically. See XEP for all possible values")];
				
				return [[[NSAttributedString alloc] initWithString:str attributes:nil] autorelease];
			}
		}
	}
	return nil;
}

@end
