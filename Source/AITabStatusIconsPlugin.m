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

#import "AITabStatusIconsPlugin.h"
#import "AIContactController.h"
#import "AIContentController.h"
#import <AIUtilities/AIMutableOwnerArray.h>
#import <Adium/AIChat.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListContact.h>
#import <Adium/AIStatusIcons.h>

@interface AITabStatusIconsPlugin (PRIVATE)
- (NSString *)_stateIDForChat:(AIChat *)inChat;
- (NSString *)_statusIDForListObject:(AIListObject *)listObject;
@end

/*
 * @class AITabStatusIconsPlugin
 * @brief Tab status icons component
 *
 * This component is effectively glue to AIStatusIcons to provide status and typing/unviewed content icons
 * for chats.
 */
@implementation AITabStatusIconsPlugin

/*
 * @brief Install
 */
- (void)installPlugin
{
	//Observe list object changes
	[[adium contactController] registerListObjectObserver:self];
	
	//Observe chat changes
	[[adium contentController] registerChatObserver:self];
	
	[[adium notificationCenter] addObserver:self
								   selector:@selector(statusIconSetDidChange:)
									   name:AIStatusIconSetDidChangeNotification
									 object:nil];
}

/*
 * @brief The status icon set changed; update our objects and chats.
 */
- (void)statusIconSetDidChange:(NSNotification *)aNotification
{
	[[adium contactController] updateAllListObjectsForObserver:self];
	[[adium contentController] updateAllChatsForObserver:self];
}

/*
 * @brief Apply the correct tab icon according to status
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
    NSSet		*modifiedAttributes = nil;
	
	if(inModifiedKeys == nil ||
	   [inModifiedKeys containsObject:@"Stranger"] ||
	   [inModifiedKeys containsObject:@"StatusState"] ||
	   [inModifiedKeys containsObject:@"IsIdle"] ||
	   [inModifiedKeys containsObject:@"Online"]){
		
		//Tab
		NSImage	*icon = [AIStatusIcons statusIconForListObject:inObject
														type:AIStatusIconTab
												   direction:AIIconNormal];
		[[inObject displayArrayForKey:@"Tab Status Icon"] setObject:icon withOwner:self];

		//List
		icon = [AIStatusIcons statusIconForListObject:inObject
											   type:AIStatusIconList
										  direction:AIIconNormal];
		[[inObject displayArrayForKey:@"List Status Icon"] setObject:icon withOwner:self];
		
		modifiedAttributes = [NSSet setWithObjects:@"Tab Status Icon", @"List Status Icon", nil];
	}
	
	return(modifiedAttributes);
}

/*
 * @brief Update a chat for typing and unviewed content icons
 */
- (NSSet *)updateChat:(AIChat *)inChat keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	NSSet		*modifiedAttributes = nil;
	
	if (inModifiedKeys == nil ||
		[inModifiedKeys containsObject:KEY_TYPING] ||
		[inModifiedKeys containsObject:KEY_UNVIEWED_CONTENT]){
		
		//Apply the state icon to our chat
		NSImage	*icon = [AIStatusIcons statusIconForChat:inChat
														type:AIStatusIconTab
												   direction:AIIconNormal];
		[[inChat displayArrayForKey:@"Tab State Icon"] setObject:icon withOwner:self];
		modifiedAttributes = [NSSet setWithObject:@"Tab State Icon"];

		//Also apply the state icon to our contact if this is a one-on-one chat
		if([inChat listObject]){
			AIListContact *contact = [[adium contactController] parentContactForListObject:[inChat listObject]];
			
			NSImage	*icon = [AIStatusIcons statusIconForChat:inChat
														type:AIStatusIconList
												   direction:AIIconNormal];
			[[contact displayArrayForKey:@"List State Icon"] setObject:icon withOwner:self];
			[[adium contactController] listObjectAttributesChanged:contact
													  modifiedKeys:[NSSet setWithObject:@"List State Icon"]];
		}		
	}
	
	return(modifiedAttributes);
}

@end
