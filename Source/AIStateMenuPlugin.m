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

#import "AIEditStateWindowController.h"
#import "AIMenuController.h"
#import "AIStateMenuPlugin.h"
#import "AIStatusController.h"

#define STATE_TITLE_MENU_LENGTH		30

/*!
 * @class AIStateMenuPlugin
 * @brief Implements a list of preset states in the status menu
 *
 * This plugin places a list of preset states in the status menu, allowing the user to easily view and change the
 * active state.
 */
@implementation AIStateMenuPlugin

/*!
 * @brief Initialize the state menu plugin
 *
 * Initialize the state menu, registering this class as a state menu plugin.  The status controller will then instruct
 * us to add and remove state menu items and handle all other details on its own.
 */
- (void)installPlugin
{
	//Wait for Adium to finish launching before we perform further actions
	[[adium notificationCenter] addObserver:self
								   selector:@selector(adiumFinishedLaunching:)
									   name:Adium_CompletedApplicationLoad
									 object:nil];
}

- (void)adiumFinishedLaunching:(NSNotification *)notification
{
	[[adium statusController] registerStateMenuPlugin:self];
}

- (void)uninstallPlugin
{
	[[adium statusController] unregisterStateMenuPlugin:self];
}

/*!
 * @brief Add state menu items to our location
 *
 * Implemented as required by the StateMenuPlugin protocol.
 *
 * @param menuItemArray An <tt>NSArray</tt> of <tt>NSMenuItem</tt> objects to be added to the menu
 */
- (void)addStateMenuItems:(NSArray *)menuItemArray
{
	NSEnumerator	*enumerator = [menuItemArray objectEnumerator];
	NSMenuItem		*menuItem;

	AIStatusType	activeStatusType = [[adium statusController] activeStatusType];
	AIStatusType	targetStatusType;
	AIStatus		*targetStatusState;
	BOOL			assignKeyEquivalents = NO;
	BOOL			assignOptionCmdY;
	
	if(activeStatusType == AIAvailableStatusType){
		targetStatusType = AIAwayStatusType;
		targetStatusState = nil;
		assignOptionCmdY = NO;
		assignKeyEquivalents = YES;
		
	}else if((activeStatusType == AIAwayStatusType) || (activeStatusType == AIInvisibleStatusType)){
		targetStatusType = AIAvailableStatusType;		
		targetStatusState = [[adium statusController] defaultInitialStatusState];
		assignOptionCmdY = YES;
		assignKeyEquivalents = YES;
		
	}
	   
    while((menuItem = [enumerator nextObject])){
		AIStatus	*representedStatus = [[menuItem representedObject] objectForKey:@"AIStatus"];
		int			tag = [menuItem tag];

		[[adium menuController] addMenuItem:menuItem toLocation:LOC_Status_State];
		
		if(assignKeyEquivalents){
			if((tag == targetStatusType) && 
			   (representedStatus == targetStatusState)){
				[menuItem setKeyEquivalent:@"y"];
				
			}else if(assignOptionCmdY && ((tag == AIAwayStatusType) && (representedStatus == nil))){
				[menuItem setKeyEquivalent:@"y"];
				[menuItem setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
				
			}
		}
    }
}

/*!
 * @brief Remove state menu items from our location
 *
 * Implemented as required by the StateMenuPlugin protocol.
 *
 * @param menuItemArray An <tt>NSArray</tt> of <tt>NSMenuItem</tt> objects to be removed from the menu
 */
- (void)removeStateMenuItems:(NSArray *)menuItemArray
{
	NSEnumerator	*enumerator = [menuItemArray objectEnumerator];
	NSMenuItem		*menuItem;
	
    while((menuItem = [enumerator nextObject])){    
        [[adium menuController] removeMenuItem:menuItem];
    }
}

@end
