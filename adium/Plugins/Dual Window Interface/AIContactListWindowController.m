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

#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIContactListWindowController.h"
#import "AIAdium.h"
#import "AIDualWindowInterfacePlugin.h"

#define CONTACT_LIST_WINDOW_NIB			@"ContactListWindow"		//Filename of the contact list window nib
#define CONTACT_LIST_TOOLBAR			@"ContactList"			//ID of the contact list toolbar
#define	KEY_DUAL_CONTACT_LIST_WINDOW_FRAME	@"Dual Contact List Frame"

@interface AIContactListWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName interface:(id <AIContainerInterface>)inInterface owner:(id)inOwner;
- (void)contactSelectionChanged:(NSNotification *)notification;
- (void)windowDidLoad;
- (BOOL)windowShouldClose:(id)sender;
@end

@implementation AIContactListWindowController

//Return a new contact list window controller
+ (AIContactListWindowController *)contactListWindowControllerForInterface:(id <AIContainerInterface>)inInterface owner:(id)inOwner
{
    return([[[self alloc] initWithWindowNibName:CONTACT_LIST_WINDOW_NIB interface:inInterface owner:inOwner] autorelease]);
}

//Make this container active
- (void)makeActive:(id)sender
{
    [self showWindow:nil];
}

//Close this container
- (void)close:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}


//Private ----------------------------------------------------------------
//init the contact list window controller
- (id)initWithWindowNibName:(NSString *)windowNibName interface:(id <AIContainerInterface>)inInterface owner:(id)inOwner
{
    [super initWithWindowNibName:windowNibName owner:self];

    owner = [inOwner retain];
    interface = [inInterface retain];
        
    return(self);
}

//dealloc
- (void)dealloc
{
    [owner release];
    [interface release];

    [super dealloc];
}

//Called when the user selects a new contact object
- (void)contactSelectionChanged:(NSNotification *)notification
{
    AIContactObject	*object = [[notification userInfo] objectForKey:@"Object"];

    //Configure our toolbar for the new object
    [toolbar_bottom configureForObjects:[NSDictionary dictionaryWithObjectsAndKeys:[self window],@"Window",object,@"ContactObject",nil]];
}

//Setup the window after it had loaded
- (void)windowDidLoad
{
    NSString	*savedFrame;
    
    //Restore the window position
    savedFrame = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_DUAL_CONTACT_LIST_WINDOW_FRAME];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }

    //Swap in the contact list view
    contactListViewController = [[[owner interfaceController] contactListViewController] retain];
    contactListView = [[contactListViewController contactListView] retain];
    [scrollView_contactList setAndSizeDocumentView:contactListView];

    //Register for the selection notification
    [[owner notificationCenter] addObserver:self selector:@selector(contactSelectionChanged:) name:Interface_ContactSelectionChanged object:contactListView];

    //Exclude this window from the window menu (since we add it manually)
    [[self window] setExcludedFromWindowsMenu:YES];

    [toolbar_bottom setIdentifier:CONTACT_LIST_TOOLBAR];
}

//Close the contact list window
- (BOOL)windowShouldClose:(id)sender
{
    //Close the contact list view
    [contactListViewController closeContactListView:contactListView];
    [contactListViewController release];
    [contactListView release];

    //Stop observing
    [[owner notificationCenter] removeObserver:self name:Interface_ContactSelectionChanged object:contactListView];

    
    //Save the window position
    [[owner preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                         forKey:KEY_DUAL_CONTACT_LIST_WINDOW_FRAME
                                          group:PREF_GROUP_WINDOW_POSITIONS];

    //Tell the interface to unload our window
    [interface containerDidClose:self];
    
    return(YES);
}

- (BOOL)shouldCascadeWindows
{
    return(NO);
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
    [interface containerDidBecomeActive:self];
}

- (void)windowDidResignMain:(NSNotification *)notification
{
    [interface containerDidBecomeActive:nil];
}

@end
