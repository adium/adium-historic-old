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

#import "AIDockUnviewedContentPlugin.h"
#import "AIChatController.h"
#import "AIContentController.h"
#import "AIDockController.h"
#import <AIUtilities/AIArrayAdditions.h>
#import <Adium/AIChat.h>

/*
 * @class AIDockUnviewedContentPlugin
 * @brief Component responsible for triggering and removing the Alert dock icon state for unviewed content
 */
@implementation AIDockUnviewedContentPlugin

/*
 * @brief Install
 */
- (void)installPlugin
{
    //init
    unviewedObjectsArray = [[NSMutableArray alloc] init];
    unviewedState = NO;

    //Register as a chat observer (So we can catch the unviewed content status flag)
    [[adium chatController] registerChatObserver:self];
	
	[[adium notificationCenter] addObserver:self
								   selector:@selector(chatWillClose:)
									   name:Chat_WillClose object:nil];
}

/*
 * @brief Uninstall
 */
- (void)uninstallPlugin
{
	[[adium chatController] unregisterChatObserver:self];
	[[adium notificationCenter] removeObserver:self];
}

/*
 * @brief Chat was updated
 *
 * Check for whether inModifiedKeys contains a change to unviewed content. If so, put the dock in the Alert state
 * if it isn't already and there is unviewed content, or take it out of the Alert state if it is and there is none.
 *
 * The alert state, in the default dock icon set, is the Adium duck flapping its wings.
 */
- (NSSet *)updateChat:(AIChat *)inChat keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
    if ([inModifiedKeys containsObject:KEY_UNVIEWED_CONTENT]) {
		
        if ([inChat unviewedContentCount]) {
            //If this is the first contact with unviewed content, animate the dock
            if (!unviewedState) {
                [[adium dockController] setIconStateNamed:@"Alert"];
                unviewedState = YES;
            }

            [unviewedObjectsArray addObject:inChat];

        } else {
            if ([unviewedObjectsArray containsObjectIdenticalTo:inChat]) {
                [unviewedObjectsArray removeObject:inChat];

                //If there are no more contacts with unviewed content, stop animating the dock
                if ([unviewedObjectsArray count] == 0 && unviewedState) {
                    [[adium dockController] removeIconStateNamed:@"Alert"];
                    unviewedState = NO;
                }
            }
        }
    }

    return nil;
}

/*!
 * @brief Respond to a chat closing
 *
 * Ensure that when a chat closes we remove the Alert state if necessary.
 */
- (void)chatWillClose:(NSNotification *)notification
{
	AIChat	*inChat = [notification object];

	if ([unviewedObjectsArray containsObjectIdenticalTo:inChat]) {
		[unviewedObjectsArray removeObject:inChat];
		
		//If there are no more contacts with unviewed content, stop animating the dock
		if ([unviewedObjectsArray count] == 0 && unviewedState) {
			[[adium dockController] removeIconStateNamed:@"Alert"];
			unviewedState = NO;
		}
	}
}

@end
