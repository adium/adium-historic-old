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

#define CONTACT_LIST_WINDOW_NIB		@"ContactListWindow"		//Filename of the contact list window nib
#define CONTACT_LIST_TOOLBAR		@"ContactList"			//ID of the contact list toolbar

@interface AIContactListWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner;
- (void)windowDidLoad;
@end

@implementation AIContactListWindowController

// Return an instance of AIContactListWindowController
+ (AIContactListWindowController *)contactListWindowControllerWithOwner:(id)inOwner
{
    return([[[self alloc] initWithWindowNibName:CONTACT_LIST_WINDOW_NIB owner:inOwner] autorelease]);
}     

//Private ----------------------------------------------------------------
// init the account window controller
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner
{
    NSParameterAssert(windowNibName != nil && [windowNibName length] != 0);

    //Retain our owner
    owner = [inOwner retain];
    
    //Listen

    [super initWithWindowNibName:windowNibName owner:self];
        
    return(self);
}

- (void)dealloc
{
    [owner release];

    [super dealloc];
}

//Called when the user selects a new contact object
- (void)contactSelectionChanged:(NSNotification *)notification
{
    AIContactObject	*object = [[notification userInfo] objectForKey:@"Object"];

    //Configure our toolbar for the new object
    [toolbar_bottom configureForObjects:[NSDictionary dictionaryWithObjectsAndKeys:[self window],@"Window",object,@"ContactObject",nil]];
}

- (void)windowDidLoad
{
    NSView	*newView;

    //Swap in the contact list view
    newView = [[owner interfaceController] contactListView];
    [scrollView_contactList setAndSizeDocumentView:newView];
    
    //Register for the selection notification
    [[[owner interfaceController] interfaceNotificationCenter] addObserver:self selector:@selector(contactSelectionChanged:) name:Interface_ContactSelectionChanged object:newView];

    //Exclude this window from the window menu (since we add it manually)
    [[self window] setExcludedFromWindowsMenu:YES];

    [toolbar_bottom setIdentifier:CONTACT_LIST_TOOLBAR];
}

@end
