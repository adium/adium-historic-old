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

#import "AIContactController.h"
#import "AIContentController.h"
#import "AIExtendedStatusPlugin.h"
#import "AIPreferenceController.h"
#import <AIUtilities/AIMutableOwnerArray.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIMutableStringAdditions.h>
#import <Adium/AIAbstractListController.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListContact.h>

#define STATUS_MAX_LENGTH	100

@interface AIExtendedStatusPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

/*!
 * @class AIExtendedStatusPlugin
 * @brief Manage the 'extended status' shown in the contact list
 *
 * If the contact list layout calls for displaying a status message or idle time (or both), this component manages
 * generating the appropriate string, storing it in the @"ExtendedStatus" status object, and updating it as necessary.
 */
@implementation AIExtendedStatusPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_LIST_LAYOUT];
	
	whitespaceAndNewlineCharacterSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] retain];
}

/*!
 * @brief Uninstall
 */
- (void)uninstallPlugin
{
	[[adium preferenceController] unregisterPreferenceObserver:self];
	[[adium contactController] unregisterListObjectObserver:self];
}

/*!
 * @brief Preferences changes
 *
 * PREF_GROUP_LIST_LAYOUT changed; update our list objects if needed.
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	BOOL oldShowStatus = showStatus;
	BOOL oldShowIdle = showIdle;
	
	EXTENDED_STATUS_STYLE statusStyle = [[prefDict objectForKey:KEY_LIST_LAYOUT_EXTENDED_STATUS_STYLE] intValue];
	showStatus = ((statusStyle == STATUS_ONLY) || (statusStyle == IDLE_AND_STATUS));
	showIdle = ((statusStyle == IDLE_ONLY) || (statusStyle == IDLE_AND_STATUS));
	
	if (firstTime) {
		[[adium contactController] registerListObjectObserver:self];
	} else {
		if ((oldShowStatus != showStatus) || (oldShowIdle != oldShowIdle)) {
			[[adium contactController] updateAllListObjectsForObserver:self];
		}
	}
}

/*!
 * @brief Update list object's extended status messages
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	NSSet		*modifiedAttributes = nil;

	//Idle time
    if ((inModifiedKeys == nil || 
		 (showIdle && [inModifiedKeys containsObject:@"Idle"]) ||
		 (showStatus && ([inModifiedKeys containsObject:@"StatusMessage"] ||
						 [inModifiedKeys containsObject:@"ContactListStatusMessage"] ||
						 [inModifiedKeys containsObject:@"StatusName"]))) &&
		[inObject isKindOfClass:[AIListContact class]]){
		NSMutableString	*statusMessage = nil;
		NSString		*finalMessage = nil;
		int				idle;
		
		if (showStatus) {
			NSAttributedString	*attributedStatusMessage = [[adium contentController] filterAttributedString:[(AIListContact *)inObject contactListStatusMessage]
																							 usingFilterType:AIFilterDisplay
																								   direction:AIFilterIncoming
																									 context:inObject];
			//Convert attachments to strings so emoticons become their text equivalents, etc.
			attributedStatusMessage = [attributedStatusMessage attributedStringByConvertingAttachmentsToStrings];
			
			statusMessage = [[[[attributedStatusMessage string] stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet] mutableCopy] autorelease];
			
			//Incredibly long status messages are slow to size, so we crop them to a reasonable length
			if ([statusMessage length] > STATUS_MAX_LENGTH) {
				[statusMessage deleteCharactersInRange:NSMakeRange(STATUS_MAX_LENGTH,
																   [statusMessage length] - STATUS_MAX_LENGTH)];
			}
			
	
			/* Linebreaks in the status message cause vertical alignment issues. */
			[statusMessage convertNewlinesToSlashes];	
		}

		idle = (showIdle ? [inObject integerStatusObjectForKey:@"Idle"] : 0);

		//
		if (idle > 0 && statusMessage) {
			finalMessage = [NSString stringWithFormat:@"(%@) %@",[self idleStringForSeconds:idle], statusMessage];
		} else if (idle > 0) {
			finalMessage = [NSString stringWithFormat:@"(%@)",[self idleStringForSeconds:idle]];
		} else {
			finalMessage = statusMessage;
		}

		[[inObject displayArrayForKey:@"ExtendedStatus"] setObject:finalMessage withOwner:self];
		modifiedAttributes = [NSSet setWithObject:@"ExtendedStatus"];
	}
	
   return modifiedAttributes;
}


/*!
 * @brief Determine the idle string
 *
 * @param seconds Number of seconds idle
 * @result A localized string to display for the idle time
 */
- (NSString *)idleStringForSeconds:(int)seconds
{
	NSString	*idleString;
	
	//Create the idle string
	if (seconds > 599400) {//Cap idle at 999 Hours (999*60*60 seconds)
		idleString = AILocalizedString(@"Idle",nil);
	} else if (seconds >= 600) {
		idleString = [NSString stringWithFormat:@"%ih",seconds / 60];
	} else if (seconds >= 60) {
		idleString = [NSString stringWithFormat:@"%i:%02i",seconds / 60, seconds % 60];
	} else {
		idleString = [NSString stringWithFormat:@"%i",seconds];
	}
	
	return idleString;
}

@end
