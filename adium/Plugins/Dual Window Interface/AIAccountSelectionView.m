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

#define ACCOUNT_SELECTION_NIB		@"AccountSelectionView"

@implementation AIAccountSelectionView

- (id)initWithFrame:(NSRect)frameRect delegate:(id <AIAccountSelectionViewDelegate>)inDelegate
{
    [super initWithFrame:frameRect];

    delegate = [inDelegate retain];
    adium = [AIObject sharedAdiumInstance];

    [self configureView];
    [self configureAccountMenu];

    //register for notifications
    [[adium notificationCenter] addObserver:self
				   selector:@selector(accountListChanged:)
				       name:Account_ListChanged
				     object:nil];
    [[adium contactController] registerListObjectObserver:self];

    return(self);
}

- (void)dealloc
{
    [delegate release]; delegate = nil;
    [[adium contactController] unregisterListObjectObserver:self];
    [[adium notificationCenter] removeObserver:self];
    
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
    NSLog(@"configureAccountMenu");
    AIListObject	*listObject = [delegate listObject];
    NSEnumerator	*enumerator;
    AIAccount		*anAccount;
    int			selectedIndex;

    //remove any existing menu items
    [[popUp_accounts menu] removeAllItems];

    //insert a menu for each account
    enumerator = [[[adium accountController] accountArray] objectEnumerator];
    while((anAccount = [enumerator nextObject])){

        //Accounts only show up in the menu if they're the correct handle type.
        if(!listObject || [[listObject serviceID] compare:[[[anAccount service] handleServiceType] identifier]] == 0){
            NSMenuItem	*menuItem;

            menuItem = [[[NSMenuItem alloc] initWithTitle:[anAccount displayName]
						   target:self
						   action:@selector(selectNewAccount:)
					    keyEquivalent:@""] autorelease];
            [menuItem setRepresentedObject:anAccount];

            //They are disabled if the account is offline
            if(![[adium contentController] availableForSendingContentType:CONTENT_MESSAGE_TYPE
							     toListObject:nil
								onAccount:anAccount]){
                [menuItem setEnabled:NO];
            }

            [[popUp_accounts menu] addItem:menuItem];
        }
    }

    //Select our current account
    selectedIndex = [popUp_accounts indexOfItemWithRepresentedObject:[delegate account]];
    [popUp_accounts selectItemAtIndex:selectedIndex];
    [self updateMenu];
}

//An account's status changed
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys delayed:(BOOL)delayed silent:(BOOL)silent;
{
    if([inObject isKindOfClass:[AIAccount class]]){
	[self configureAccountMenu]; //rebuild the account menu
    }
    
    return(nil);
}

//The account list/status changed
- (void)accountListChanged:(NSNotification *)notification
{
    [self configureAccountMenu]; //rebuild the account menu
}

//User selected a new account from the account menu
- (IBAction)selectNewAccount:(id)sender
{
    [delegate setAccount:[sender representedObject]];
    [self updateMenu];
}

- (void)updateMenu
{
    NSEnumerator	*enumerator;
    NSMenuItem		*menuItem;
    AIAccount		*account = [delegate account];
    
    //Select the correct item
    [popUp_accounts selectItem:[[popUp_accounts menu] itemAtIndex:[popUp_accounts indexOfItemWithRepresentedObject:account]]];

    //Update the 'Checked' menu item (NSPopUpButton doesn't like to do this automatically for us)
    enumerator = [[[popUp_accounts menu] itemArray] objectEnumerator];
    while(menuItem = [enumerator nextObject]){
        if([menuItem representedObject] == account){
            [menuItem setState:NSOnState];
        }else{
            [menuItem setState:NSOffState];
        }
    }
}

@end
