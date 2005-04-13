//
//  ESAwayStatusWindowPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on 4/12/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "ESAwayStatusWindowPlugin.h"
#import "ESAwayStatusWindowController.h"
#import "AIContactController.h"
#import "AIPreferenceController.h"
#import "AIStatusController.h"
#import <Adium/AIAccount.h>
#import <Adium/AIListObject.h>

/*
 * @class ESAwayStatusWindowPlugin
 * @brief Component to manage the status window optionally displayed when one or more accounts are away
 */
@implementation ESAwayStatusWindowPlugin

/*
 * @brief Install
 */
- (void)installPlugin
{
	showStatusWindow = FALSE;
	awayAccounts = [[NSMutableSet alloc] init];

	//Observe preference changes for updating if we should show the status window
	[[adium preferenceController] registerPreferenceObserver:self 
													forGroup:PREF_GROUP_STATUS_PREFERENCES];
}

/*
 * @brief Deallocate
 */
- (void)dealloc
{
	[awayAccounts release];
	[[adium preferenceController] unregisterPreferenceObserver:self];
	
	[super dealloc];
}

/*
 * @brief Preferences changed
 *
 * Note whether we are supposed to should show the status window, and toggle it if necessary
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	BOOL oldShowStatusWindow = showStatusWindow;
	
	showStatusWindow = [[prefDict objectForKey:KEY_STATUS_SHOW_STATUS_WINDOW] boolValue];
	
	if(showStatusWindow != oldShowStatusWindow){
		if(showStatusWindow){
			/* Register as a list object observer, which will update all objects for us immediately leading to the proper
			 * status window toggling. */
			[[adium contactController] registerListObjectObserver:self];
		
		}else{
			//Hide the status window if it is currently visible
			[ESAwayStatusWindowController setStatusWindowVisible:NO];
			
			//Clear our away account tracking
			[awayAccounts removeAllObjects];
			
			//Stop observing list objects
			[[adium contactController] unregisterListObjectObserver:self];
		}
	}
}

/*!
 * @brief Account status changed.
 *
 * Show or hide our status window as appropriate
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if([inObject isKindOfClass:[AIAccount class]] &&
	   (!inModifiedKeys || [inModifiedKeys containsObject:@"StatusState"])){
		
		if([inObject online] && ([inObject statusType] != AIAvailableStatusType)){
			[awayAccounts addObject:inObject];
		}else{
			[awayAccounts removeObject:inObject];
		}
		
		[ESAwayStatusWindowController setStatusWindowVisible:([awayAccounts count] > 0)];
	}
	
	//We don't modify any keys
	return nil;
}

@end
