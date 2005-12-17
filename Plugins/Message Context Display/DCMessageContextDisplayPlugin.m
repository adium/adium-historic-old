/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIContentController.h"
#import "AIPreferenceController.h"
#import "DCMessageContextDisplayPlugin.h"
#import "DCMessageContextDisplayPreferences.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentContext.h>
#import "SMSQLiteLoggerPlugin.h"
#import "AICoreComponentLoader.h"
#import <Cocoa/Cocoa.h>

@interface DCMessageContextDisplayPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (BOOL)contextShouldBeDisplayed:(NSCalendarDate *)inDate;
@end

@implementation DCMessageContextDisplayPlugin

- (void)installPlugin
{
	isObserving = NO;
	
	//Setup our preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CONTEXT_DISPLAY_DEFAULTS
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_CONTEXT_DISPLAY];
    preferences = [[DCMessageContextDisplayPreferences preferencePane] retain];
	
    //Observe preference changes
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_CONTEXT_DISPLAY];
}

- (void)uninstallPlugin
{
	[[adium preferenceController] unregisterPreferenceObserver:self];
	[[adium notificationCenter] removeObserver:self];
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	//Only change our preferences in response to global preference notifications; specific objects use this group as well.
	if (object == nil) {
		haveTalkedDays = [[prefDict objectForKey:KEY_HAVE_TALKED_DAYS] intValue];
		haveNotTalkedDays = [[prefDict objectForKey:KEY_HAVE_NOT_TALKED_DAYS] intValue];
		displayMode = [[prefDict objectForKey:KEY_DISPLAY_MODE] intValue];
		
		haveTalkedUnits = [[prefDict objectForKey:KEY_HAVE_TALKED_UNITS] intValue];
		haveNotTalkedUnits = [[prefDict objectForKey:KEY_HAVE_NOT_TALKED_UNITS] intValue];
		
		shouldDisplay = [[prefDict objectForKey:KEY_DISPLAY_CONTEXT] boolValue];
		linesToDisplay = [[prefDict objectForKey:KEY_DISPLAY_LINES] intValue];
				
		if (shouldDisplay && linesToDisplay > 0 && !isObserving) {
			//Observe new message windows only if we aren't already observing them
			isObserving = YES;
			[[adium notificationCenter] addObserver:self
										   selector:@selector(addContextDisplayToWindow:)
											   name:Chat_DidOpen 
											 object:nil];
			
		} else if (isObserving && (!shouldDisplay || linesToDisplay <= 0)) {
			//Remove observer
			isObserving = NO;
			[[adium notificationCenter] removeObserver:self name:Chat_DidOpen object:nil];
			
		}
	}
}

- (void)addContextDisplayToWindow:(NSNotification *)notification
{
	AIChat * chat = (AIChat *)[notification object];
	
	if(!logger)
		logger = (SMSQLiteLoggerPlugin *)[[[AIObject sharedAdiumInstance] componentLoader] pluginWithClassName:@"SMSQLiteLoggerPlugin"];
	
	NSArray	* context = [[logger context:linesToDisplay inChat:chat]retain];
	
	if (context && [context count] > 0 && shouldDisplay) {
		
		//Check if the history fits the date restrictions
		
		NSCalendarDate *mostRecentMessage = [[(AIContentContext *)[context objectAtIndex:0] date] dateWithCalendarFormat:nil timeZone:nil];
		
		if ([self contextShouldBeDisplayed:mostRecentMessage]) {
			
			NSEnumerator * contextEnu = [context reverseObjectEnumerator];
			AIContentContext	*contextMessage;
			//Add messages until: we add our max (linesToDisplay) OR we run out of saved messages
			while((contextMessage = [contextEnu nextObject])) {
				/* Don't display immediately, so the message view can aggregate multiple message history items.
				 * As required, we post Content_ChatDidFinishAddingUntrackedContent when finished adding. */
				[contextMessage setDisplayContentImmediately:NO];
				
				[[adium contentController] displayContentObject:contextMessage
											usingContentFilters:YES
													immediately:YES];
			}

		//We finished adding untracked content
		[[adium notificationCenter] postNotificationName:Content_ChatDidFinishAddingUntrackedContent
												  object:chat];

		} /* [self contextShouldBeDisplayed:mostRecentMessage] */
	} /* chatDict && shouldDisplay && linesToDisplay > 0  */
	[context release];
}


- (BOOL)contextShouldBeDisplayed:(NSCalendarDate *)inDate
{
	BOOL dateIsGood = YES;
	int thresholdDays = 0;
	int thresholdHours = 0;
	
	if ( displayMode != MODE_ALWAYS ) {
		
		if ( displayMode == MODE_HAVE_TALKED ) {
			if ( haveTalkedUnits == UNIT_DAYS )
				thresholdDays = haveTalkedDays;
			else if ( haveTalkedUnits == UNIT_HOURS )
				thresholdHours = haveTalkedDays;
			
		} else if ( displayMode == MODE_HAVE_NOT_TALKED ) {
			if ( haveTalkedUnits == UNIT_DAYS )
				thresholdDays = haveNotTalkedDays;
			else if ( haveTalkedUnits == UNIT_HOURS )
				thresholdHours = haveNotTalkedDays;
		}
		
		// Take the most recent message's date, add our limits to it
		// See if the new date is earlier or later than today's date
		NSCalendarDate *newDate = [inDate dateByAddingYears:0 months:0 days:thresholdDays hours:thresholdHours minutes:0 seconds:0];

		NSComparisonResult comparison = [newDate compare:[NSDate date]];
		
		if ( ((displayMode == MODE_HAVE_TALKED) && (comparison == NSOrderedAscending)) ||
			((displayMode == MODE_HAVE_NOT_TALKED) && (comparison == NSOrderedDescending)) ) {
			dateIsGood = NO;
		}
	}
	
	return  dateIsGood ;
}
@end
