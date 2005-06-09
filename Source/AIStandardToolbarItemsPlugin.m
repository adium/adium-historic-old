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
#import "AIInterfaceController.h"
#import "AIStandardToolbarItemsPlugin.h"
#import "AIToolbarController.h"
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/ESImageAdditions.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>

#define MESSAGE	AILocalizedString(@"Message", nil)

/*!
 * @class AIStandardToolbarItemsPlugin
 * @brief Component to provide general-use toolbar items
 *
 * Just provides a Message toolbar item at present.
 */
@implementation AIStandardToolbarItemsPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
    //New Message
    NSToolbarItem   *toolbarItem = 
	[AIToolbarUtilities toolbarItemWithIdentifier:@"NewMessage"
											label:MESSAGE
									 paletteLabel:MESSAGE
										  toolTip:MESSAGE
										   target:self
								  settingSelector:@selector(setImage:)
									  itemContent:[NSImage imageNamed:@"message" forClass:[self class]]
										   action:@selector(newMessage:)
											 menu:nil];
    [[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"ListObject"];
}

/*!
 * @brief New chat with the selected list object
 */
- (IBAction)newMessage:(NSToolbarItem *)toolbarItem
{
    AIListObject	*object = [[adium contactController] selectedListObject];

    if ([object isKindOfClass:[AIListContact class]]) {
		AIChat  *chat = [[adium contentController] openChatWithContact:(AIListContact *)object];
        [[adium interfaceController] setActiveChat:chat];
    }
	
}

@end
