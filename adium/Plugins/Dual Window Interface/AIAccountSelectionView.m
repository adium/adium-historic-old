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

#import "AIAccountSelectionView.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"

#define ACCOUNT_SELECTION_NIB		@"AccountSelectionView"

@implementation AIAccountSelectionView

- (id)initWithFrame:(NSRect)frameRect delegate:(id <AIAccountSelectionViewDelegate>)inDelegate owner:(id)inOwner
{
    [super initWithFrame:frameRect];

    delegate = inDelegate;
    owner = inOwner;

    [self configureView];
    [self configureAccountMenu];

    //register for notifications
    [[owner notificationCenter] addObserver:self selector:@selector(accountListChanged:) name:Account_ListChanged object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(accountListChanged:) name:Account_PropertiesChanged object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(accountListChanged:) name:Account_StatusChanged object:nil];

    return(self);
}

- (void)dealloc
{
    [[owner notificationCenter] removeObserver:self];

    [super dealloc];
}

//Load and configure our contents
- (void)configureView
{
    NSEnumerator	*enumerator;
    NSView		*view;
    NSArray		*viewArray;

    //Load our contents
    [NSBundle loadNibNamed:ACCOUNT_SELECTION_NIB owner:self];

    //Set our height correctly (width is flexible)
    [self setFrameSize:NSMakeSize([self frame].size.width, [view_contents frame].size.height)];

    //Transfer the contents to our view
    viewArray = [[[view_contents subviews] copy] autorelease];
    enumerator = [viewArray objectEnumerator];
    while((view = [enumerator nextObject])){
        [view retain];
        [view removeFromSuperview];
        [self addSubview:view];

        [view resizeWithOldSuperviewSize:[view_contents frame].size];
        [view release];
    }
    [view_contents release];

    //
    [[popUp_accounts menu] setAutoenablesItems:NO];
}

//Configures the account menu (dimming invalid accounts if applicable)
- (void)configureAccountMenu
{
    AIListContact	*contact = [delegate contact];
    NSEnumerator	*enumerator;
    AIAccount		*anAccount;

    //remove any existing menu items
    [popUp_accounts removeAllItems];

    //insert a menu for each account
    enumerator = [[[owner accountController] accountArray] objectEnumerator];
    while((anAccount = [enumerator nextObject])){
        
        //Accounts only show up in the menu if they're the correct handle type.
        if(!contact || [[contact serviceID] compare:[[[anAccount service] handleServiceType] identifier]] == 0){
            NSMenuItem	*menuItem;

            menuItem = [[[NSMenuItem alloc] initWithTitle:[anAccount accountDescription] target:nil action:nil keyEquivalent:@""] autorelease];
            [menuItem setRepresentedObject:anAccount];

            //They are disabled if the account is offline
            if(![(AIAccount<AIAccount_Content> *)anAccount availableForSendingContentType:CONTENT_MESSAGE_TYPE toHandle:nil]){
                [menuItem setEnabled:NO];
            }

            [[popUp_accounts menu] addItem:menuItem];
        }
    }
    
    //Select our current account
    [popUp_accounts selectItemAtIndex:[popUp_accounts indexOfItemWithRepresentedObject:[delegate account]]];
}

//The account list/status changed
- (void)accountListChanged:(NSNotification *)notification
{
    [self configureAccountMenu]; //rebuild the account menu
}

//User selected a new account from the account menu
- (IBAction)selectNewAccount:(id)sender
{
    //Inform our delegate of the new selection
    [delegate setAccount:[[sender selectedItem] representedObject]];
}

@end
