/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@class AIAdium, AIContactListWindowController, AIMessageWindowController, AIMessageViewController;
@protocol AIMessageView, AIInterfaceController, AITabHoldingInterface, AIContactListCleanup;

@protocol AIInterfaceContainer <NSObject>
- (void)makeActive:(id)sender;	//Make the container active/front
- (void)close:(id)sender;	//Close the container
@end

@protocol AIContainerInterface <NSObject>
- (void)containerDidClose:(id <AIInterfaceContainer>)inContainer;
- (void)containerDidBecomeActive:(id <AIInterfaceContainer>)inContainer;
- (void)containerOrderDidChange;
@end

@interface AIDualWindowInterfacePlugin : AIPlugin <AIInterfaceController, AIContainerInterface> {
    //Menus
    NSMutableArray			*windowMenuArray;
    NSMenuItem				*menuItem_close;
    NSMenuItem				*menuItem_closeTab;
    NSMenuItem				*menuItem_nextMessage;
    NSMenuItem				*menuItem_previousMessage;

    //Containers
    AIContactListWindowController 	*contactListWindowController;
    id <AIInterfaceContainer>		activeContainer;

    //
    AIMessageWindowController		*messageWindowController;

}

- (IBAction)showContactList:(id)sender;

@end
