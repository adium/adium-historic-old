/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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


#define	PREF_GROUP_DUAL_WINDOW_INTERFACE	@"Dual Window Interface"

#define KEY_DUAL_RESIZE_VERTICAL                @"Autoresize Vertical"
#define KEY_DUAL_RESIZE_HORIZONTAL              @"Autoresize Horizontal"

#define KEY_ALWAYS_CREATE_NEW_WINDOWS 		@"Always Create New Windows"
#define KEY_USE_LAST_WINDOW			@"Use Last Window"
#define KEY_AUTOHIDE_TABBAR			@"Autohide Tab Bar"
#define KEY_DUAL_MESSAGE_WINDOW_FRAME           @"Dual Message Window Frame"

#define TAB_CELL_IDENTIFIER                     @"Tab Cell Identifier"

@class AIAdium, AIContactListWindowController, AIMessageWindowController, AIMessageViewController, AIDualWindowPreferences, AIDualWindowAdvancedPrefs, ESDualWindowMessageWindowPreferences, ESDualWindowMessageAdvancedPreferences;
@protocol AIMessageView, AIInterfaceController, AITabHoldingInterface, AIContactListCleanup;

@protocol AIInterfaceContainer <NSObject>
- (void)makeActive:(id)sender;	//Make the container active/front
- (void)close:(id)sender;	//Close the container
@end

@protocol AIContainerInterface <NSObject>
- (void)containerDidOpen:(id <AIInterfaceContainer>)inContainer;
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

    NSMenuItem				*menuItem_openInNewWindow;
    NSMenuItem				*menuItem_openInPrimaryWindow;
    NSMenuItem				*menuItem_consolidate;
    
    //Containers
    AIContactListWindowController 	*contactListWindowController;
    id <AIInterfaceContainer>		activeContainer;

    //messageWindow stuff
    NSMutableArray			*messageWindowControllerArray;
    AIMessageWindowController		*lastUsedMessageWindow;
    
    //Preferences
    AIDualWindowPreferences                 *preferenceController;
    AIDualWindowAdvancedPrefs               *preferenceAdvController;
    ESDualWindowMessageWindowPreferences    *preferenceMessageController;
    ESDualWindowMessageAdvancedPreferences  *preferenceMessageAdvController;
    
    BOOL				alwaysCreateNewWindows;
    BOOL				useLastWindow;
    
    BOOL				forceIntoNewWindow; //Override preference for next opened chat
    BOOL				forceIntoTab; //Override preference for next opened chat
}

- (IBAction)showContactList:(id)sender;


@end
