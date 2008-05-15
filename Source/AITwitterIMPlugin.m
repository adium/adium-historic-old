//
//  AITwitterIMPlugin.m
//  Adium
//
//  Created by Colin Barrett on 5/14/08.

#import "AITwitterIMPlugin.h"

#define PREF_GROUP_CHARACTER_COUNTER	@"Character Counter"
#define KEY_CHARACTER_COUNTER_ENABLED	@"Character Counter Enabled"
#define KEY_MAX_NUMBER_OF_CHARACTERS	@"Maximum Number Of Characters"

@implementation AITwitterIMPlugin

- (void)installPlugin
{
	[[adium contactController] registerListObjectObserver:self];
}

- (void)dealloc
{
	[[adium contactController] unregisterListObjectObserver:self];
	[super dealloc];
}

- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if (!inModifiedKeys) {
		if ([[inObject UID] isEqualToString:@"twitter@twitter.com"] &&
			[[inObject serviceClass] isEqualToString:@"Jabber"]) {
						
			[inObject setPreference:[NSNumber numberWithBool:YES] forKey:KEY_CHARACTER_COUNTER_ENABLED group:PREF_GROUP_CHARACTER_COUNTER];
			[inObject setPreference:[NSNumber numberWithInt:140] forKey:KEY_MAX_NUMBER_OF_CHARACTERS group:PREF_GROUP_CHARACTER_COUNTER];
		}
	}
	
	return nil;
}

@end
