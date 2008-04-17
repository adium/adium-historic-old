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

#import <Adium/AIContentControllerProtocol.h>
#import "AIMentionEventPlugin.h"
#import <Adium/AIContentObject.h>
#import <Adium/AIListObject.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIChat.h>
#import <Adium/AIContactAlertsControllerProtocol.h>

/*!
 * @class AIMentionEventPlugin
 * @brief Simple content filter to generate events when incoming messages mention the user, and tag them with a special display class
 */
@implementation AIMentionEventPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	[[adium contentController] registerContentFilter:self
											  ofType:AIFilterContent 
										   direction:AIFilterIncoming];
}

- (void)uninstallPlugin
{
	[[adium contentController] unregisterContentFilter:self];
}

#pragma mark -

/*!
 * @brief Filter
 */
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context;
{
	if([context isKindOfClass:[AIContentMessage class]]) {
		AIContentMessage *message = (AIContentMessage *)context;
		AIChat *chat = [message chat];
		if([chat isGroupChat]) {
			NSString *messageString = [inAttributedString string];
			AIListObject *me = [message destination];
			
			//TODO: This needs to respect per-room nicknames
			if([messageString rangeOfString:[me displayName] options:NSCaseInsensitiveSearch].location != NSNotFound ||
			   [messageString rangeOfString:[me formattedUID] options:NSCaseInsensitiveSearch].location != NSNotFound) 
			{
				[[adium contactAlertsController] generateEvent:CONTENT_GROUP_CHAT_MENTION
												 forListObject:[message source]
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:chat, @"AIChat", message, @"AIContentObject", nil]
								  previouslyPerformedActionIDs:nil];
				[message addDisplayClass:@"mention"];
			}
		}
	}
	return inAttributedString;
}

/*!
 * @brief Filter priority
 */
- (float)filterPriority
{
	return LOWEST_FILTER_PRIORITY;
}

@end
