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

@interface AIAccountSelectionView (PRIVATE)
- (void)_addMenusForAccounts:(NSArray *)accounts;
@end

@implementation AIAccountSelectionView

- (id)initWithFrame:(NSRect)frameRect delegate:(id <AIAccountSelectionViewDelegate>)inDelegate
{
    [super initWithFrame:frameRect];

    delegate = inDelegate;
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

- (void)setDelegate:(id <AIAccountSelectionViewDelegate>)inDelegate
{
    delegate = inDelegate;
}
- (id <AIAccountSelectionViewDelegate>)delegate
{
    return delegate;
}

- (void)dealloc
{
    delegate = nil;
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

+ (BOOL)optionsAvailableForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inObject
{
	return([[[[AIObject sharedAdiumInstance] contentController] sourceAccountsForSendingContentType:inType
																					   toListObject:inObject
																						  preferred:YES] count]
		   +
		   [[[[AIObject sharedAdiumInstance] contentController] sourceAccountsForSendingContentType:inType
																					   toListObject:inObject
																						  preferred:NO] count]> 1);
}

//Configures the account menu (dimming invalid accounts if applicable)
- (void)configureAccountMenu
{
    if(delegate){
		AIListObject	*listObject = [delegate listObject];
		int				selectedIndex;
		
		//
		[popUp_accounts setMenu:[[adium accountController] menuOfAccountsForSendingContentType:CONTENT_MESSAGE_TYPE
																				  toListObject:listObject
																					withTarget:self]];
		
		//Select our current account
		selectedIndex = [popUp_accounts indexOfItemWithRepresentedObject:[delegate account]];
		if ((selectedIndex != NSNotFound) && (selectedIndex >= 0 && selectedIndex < [popUp_accounts numberOfItems])){
			[popUp_accounts selectItemAtIndex:selectedIndex];
		}
		[self updateMenu];
	}
}


//An account's status changed
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent;
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
- (IBAction)selectAccount:(id)sender
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
	int index = [popUp_accounts indexOfItemWithRepresentedObject:account];
    if(index < [popUp_accounts numberOfItems] && index >= 0){
		[popUp_accounts selectItemAtIndex:index];
	}

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
