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

#import "AIInterfaceController.h"
#import "AIPreferenceController.h"
#import "CBContactLastSeenPlugin.h"
#import <AIUtilities/ESDateFormatterAdditions.h>
#import <Adium/AIListObject.h>

#define PREF_GROUP_LAST_SEEN	@"Last Seen"
#define KEY_LAST_SEEN_STATUS	@"Last Seen Status"
#define KEY_LAST_SEEN_DATE		@"Last Seen Date"

@interface CBContactLastSeenPlugin(PRIVATE)
- (void)update:(NSNotification *)notification;
@end

@implementation CBContactLastSeenPlugin

- (void)installPlugin
{
    //Install our tooltip entry
    [[adium interfaceController] registerContactListTooltipEntry:self secondaryEntry:NO];
	
	//Install our observers
	[[adium notificationCenter] addObserver:self
								   selector:@selector(update:)
									   name:CONTACT_SEEN_ONLINE_YES
									 object:nil];
									 
	[[adium notificationCenter] addObserver:self
								   selector:@selector(update:)
									   name:CONTACT_STATUS_ONLINE_NO
									 object:nil];

	[[adium notificationCenter] addObserver:self
								   selector:@selector(update:)
									   name:CONTACT_SEEN_ONLINE_NO
									 object:nil];


									 
}

- (void)update:(NSNotification *)notification
{
	AIListObject	*inObject = [notification object];
	
	//Either their online, or we've come online. Either way, update both their status and the time
	if([[notification name] isEqualToString:CONTACT_SEEN_ONLINE_YES]){
	
		[[adium preferenceController] setPreference:@"Online"
											 forKey:KEY_LAST_SEEN_STATUS
											  group:PREF_GROUP_LAST_SEEN
											 object:inObject];
											 
		[[adium preferenceController] setPreference:[NSDate date]
											 forKey:KEY_LAST_SEEN_DATE
											  group:PREF_GROUP_LAST_SEEN
											 object:inObject];
											 
	//They've signed off, update their status and the time		
	}else if([[notification name] isEqualToString:CONTACT_STATUS_ONLINE_NO]){

		[[adium preferenceController] setPreference:@"Signing off"
											 forKey:KEY_LAST_SEEN_STATUS
											  group:PREF_GROUP_LAST_SEEN
											 object:inObject];


		[[adium preferenceController] setPreference:[NSDate date]
											 forKey:KEY_LAST_SEEN_DATE
											  group:PREF_GROUP_LAST_SEEN
											 object:inObject];
	
	//Don't update the status, just the date
	}else if([[notification name] isEqualToString:CONTACT_SEEN_ONLINE_NO]){
	
		[[adium preferenceController] setPreference:[NSDate date]
											 forKey:KEY_LAST_SEEN_DATE
											  group:PREF_GROUP_LAST_SEEN
											 object:inObject];
	}
}

#pragma mark Tooltip entry
//Tooltip entry ---------------------------------------------------------------------------------------
- (NSString *)labelForObject:(AIListObject *)inObject
{
    return(@"Last Seen");
}

- (NSAttributedString *)entryForObject:(AIListObject *)inObject
{
	NSString			*lastSeenStatus;
	NSDate				*lastSeenDate;
	NSDateFormatter		*sinceDateFormatter;
	NSAttributedString	*entry = nil;
	
	//Only display for offline contacts
	if(![inObject online]){
	
		lastSeenStatus = [[adium preferenceController] preferenceForKey:KEY_LAST_SEEN_STATUS 
																  group:PREF_GROUP_LAST_SEEN
																 object:inObject];
		
		lastSeenDate = [[adium preferenceController] preferenceForKey:KEY_LAST_SEEN_DATE 
																group:PREF_GROUP_LAST_SEEN
															   object:inObject];
		if(lastSeenStatus && lastSeenDate){
			
			sinceDateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:[NSString stringWithFormat:@"%@, %@", 
																				[[NSDateFormatter localizedShortDateFormatter] dateFormat],
																				[NSDateFormatter localizedDateFormatStringShowingSeconds:NO showingAMorPM:YES]]
														 allowNaturalLanguage:YES] autorelease];
									
			entry = [[NSAttributedString alloc] 
						initWithString:[NSString stringWithFormat:
							@"%@\n%@ ago\n%@", 
							lastSeenStatus,
							[NSDateFormatter stringForTimeIntervalSinceDate:lastSeenDate],
							[sinceDateFormatter stringForObjectValue:lastSeenDate]]]; 
		}
	}
	
	return [entry autorelease];
}

@end
