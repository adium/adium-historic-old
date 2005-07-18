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

#import "AIContactAwayPlugin.h"
#import "AIInterfaceController.h"
#import <Adium/AIListObject.h>
#import <AIUtilities/AIAttributedStringAdditions.h>

#define	AWAY_LABEL			AILocalizedString(@"Away",nil)
#define	AWAY_MESSAGE_LABEL	AILocalizedString(@"Away Message",nil)
#define	STATUS_LABEL		AILocalizedString(@"Status",nil)

#define AWAY_YES			AILocalizedString(@"Yes",nil)

/*!
 * @class AIContactAwayPlugin
 * @brief Tooltip component: Away messages and states
 */
@implementation AIContactAwayPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
    //Install our tooltip entry
    [[adium interfaceController] registerContactListTooltipEntry:self secondaryEntry:YES];
}

/*!
 * @brief Tooltip label
 *
 * @result A label, or nil if no tooltip entry should be shown
 */
- (NSString *)labelForObject:(AIListObject *)inObject
{
    NSString			*label = nil;
    NSAttributedString 	*statusMessage = nil;
    BOOL				away;
    
    away = ([inObject statusType] == AIAwayStatusType);
    
    //Get the status message
    statusMessage = [inObject statusMessage];
    
    //Return the correct string
    if (statusMessage != nil && [statusMessage length] != 0) {
		if (away) {
			
			//Check to make sure we're not duplicating server display name information
			NSString	*serverDisplayName = [inObject statusObjectForKey:@"Server Display Name"];
			
			//Return the correct string
			if ([serverDisplayName isEqualToString:[statusMessage string]]) {
				label = AWAY_LABEL;
			} else {
				label = AWAY_MESSAGE_LABEL;
			}
			
		} else {
			label = STATUS_LABEL;
		}
    } else if (away) {
		label = AWAY_LABEL;
    }
    
    return label;
}

/*!
 * @brief Tooltip entry
 *
 * @result The tooltip entry, or nil if no tooltip should be shown
 */
- (NSAttributedString *)entryForObject:(AIListObject *)inObject
{
    NSAttributedString	*entry = nil;
    NSAttributedString 	*statusMessage = nil;
	NSString			*serverDisplayName = nil;
    BOOL				away;
    
    away = ([inObject statusType] == AIAwayStatusType);
    
    //Get the status message
    statusMessage = [inObject statusMessage];

	//Check to make sure we're not duplicating server display name information
	serverDisplayName = [inObject statusObjectForKey:@"Server Display Name"];

    //Return the correct string
	if ([serverDisplayName isEqualToString:[statusMessage string]]) {
		//If the status and server display name are the same, just display YES for away since we'll display the
		//server display name itself in the proper place.
		if (away) {
			entry = [[[NSAttributedString alloc] initWithString:AWAY_YES] autorelease];
		}
	} else {
		if (statusMessage != nil && [statusMessage length] != 0) {
			if ([[statusMessage string] rangeOfString:@"\t" options:NSLiteralSearch].location == NSNotFound) {
				entry = statusMessage;
				
			} else {
				/* We don't display tabs well in the tooltips because we use them for alignment, so
				 * turn them into 4 spaces. */
				NSMutableAttributedString	*mutableStatusMessage = [[statusMessage mutableCopy] autorelease];
				[mutableStatusMessage replaceOccurrencesOfString:@"\t"
													  withString:@"    "
														 options:NSLiteralSearch
														   range:NSMakeRange(0, [mutableStatusMessage length])];
				entry = mutableStatusMessage;
			}
			
			
			
		} else if (away) {
			entry = [[[NSAttributedString alloc] initWithString:AWAY_YES] autorelease];
		}
	}
	
    return entry;
}

@end
