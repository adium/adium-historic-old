/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
- (void)configureContactsMenu;
- (void)configureAccountsMenu;

- (void)updateAccountsMenu;
- (void)updateContactsMenu;
- (void)updatePopUp:(NSPopUpButton *)popUpButton toObject:(id)object;
@end

@implementation AIAccountSelectionView

- (id)initWithFrame:(NSRect)frameRect delegate:(id <AIAccountSelectionViewDelegate>)inDelegate
{
    [super initWithFrame:frameRect];

    delegate = inDelegate;
    adium = [AIObject sharedAdiumInstance];

    [self configureView];
	[self configureContactsMenu];
    [self configureAccountsMenu];
	
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
}

+ (BOOL)optionsAvailableForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inObject
{
	return([self multipleContactsForListObject:inObject] ||
		   [self multipleAccountsForSendingContentType:inType toListObject:inObject]);
}

+ (BOOL)multipleAccountsForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inObject
{
	return(([[[[AIObject sharedAdiumInstance] contentController] sourceAccountsForSendingContentType:inType
																				toListObject:inObject
																				   preferred:YES] count] > 1)
	||
	([[[[AIObject sharedAdiumInstance] contentController] sourceAccountsForSendingContentType:inType
																				toListObject:inObject
																				   preferred:NO] count]> 1));
}

+ (BOOL)multipleContactsForListObject:(AIListObject *)inObject
{
	//Find the parent meta contact if possible
	AIListObject	*containingObject;
	while ([(containingObject = [inObject containingObject]) isKindOfClass:[AIMetaContact class]]){
		inObject = containingObject;
	}

	return ([inObject isKindOfClass:[AIMetaContact class]] && ![(AIMetaContact *)inObject containsOnlyOneUniqueContact]);
}

#pragma mark Acccounts
//Configures the account menu (dimming invalid accounts if applicable)
- (void)configureAccountsMenu
{
    if(delegate){
	
		AIListObject	*listObject = [delegate listObject];
		
//		if ([AIAccountSelectionView multipleAccountsForSendingContentType:CONTENT_MESSAGE_TYPE toListObject:listObject]){
			
			//I don't like magic numbers.  And I hate nibs.  How is this fixable?
			[box_accounts setFrame:NSMakeRect(0,0,212,38)];
						
			//
			[popUp_accounts setMenu:[[adium accountController] menuOfAccountsForSendingContentType:CONTENT_MESSAGE_TYPE
																					  toListObject:listObject
																						withTarget:self
																					includeOffline:NO]];
			//
			[[popUp_accounts menu] setAutoenablesItems:NO];
			
			//Select our current account
			[self updateAccountsMenu];
/*		}else{
			[box_accounts setFrame:NSMakeRect(0,0,0,0)];
		}
			*/
	}
}


//User selected a new account from the account menu
- (IBAction)selectAccount:(id)sender
{
	//This will end up triggering a call to updateMenu
    [delegate setAccount:[sender representedObject]];
}

#pragma mark Contacts
- (void)configureContactsMenu
{
	if(delegate){
		AIListObject	*listObject = [delegate listObject];

		//Find the parent meta contact if possible
		AIListObject	*containingObject;
		while ([(containingObject = [listObject containingObject]) isKindOfClass:[AIMetaContact class]]){
			listObject = containingObject;
		}
				
//		if ([AIAccountSelectionView multipleContactsForListObject:listObject]){
		BOOL isMeta = [listObject isKindOfClass:[AIMetaContact class]];
			
			//I don't like magic numbers.  And I hate nibs.  How is this fixable?
			[box_contacts setFrame:NSMakeRect(212,0,212,38)];
			
			//
			[popUp_contacts setMenu:[[adium contactController] menuOfContainedContacts:listObject
																			forService:nil
																			withTarget:self
																		includeOffline:!isMeta]]; //If not meta, include the contact even if it's offline
			//
			[[popUp_contacts menu] setAutoenablesItems:NO];
			
			
			[self updateContactsMenu];
			
//		}else{
//			[box_contacts setFrame:NSMakeRect(0,0,0,0)];
//		}
	}
	
	[self configureAccountsMenu];
}

- (void)selectContainedContact:(id)sender
{
	AIListContact	*listObject = [sender representedObject];
	NSString		*oldServiceID = [[delegate listObject] serviceID];
	
	[delegate setListObject:listObject];
	
	//If we changed services, set the account
	if (![oldServiceID isEqualToString:[listObject serviceID]]){
		[delegate setAccount:[[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
																				 toListObject:listObject]];
	}
	
	
	[self updateContactsMenu];
	[self configureAccountsMenu];
}

#pragma mark Notifications
//An account's status changed
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent;
{
    if([inObject isKindOfClass:[AIAccount class]]){
		[self configureContactsMenu];
    }
    
    return(nil);
}

//The account list/status changed
- (void)accountListChanged:(NSNotification *)notification
{
	[self configureContactsMenu];
}

#pragma mark Menu Updating
- (void)updateMenu
{
	[self updateAccountsMenu];
	[self updateContactsMenu];
}

- (void)updateAccountsMenu
{
    [self updatePopUp:popUp_accounts 
			 toObject:[delegate account]];
}

- (void)updateContactsMenu
{
    [self updatePopUp:popUp_contacts
			 toObject:[delegate listObject]];
}

- (void)updatePopUp:(NSPopUpButton *)popUpButton toObject:(id)object
{
	NSEnumerator	*enumerator;
    NSMenuItem		*menuItem;
	
    //Select the correct item
	int index = [popUpButton indexOfItemWithRepresentedObject:object];
    if(index < [popUpButton numberOfItems] && index >= 0){
		[popUpButton selectItemAtIndex:index];
	}
	
    //Update the 'Checked' menu item (NSPopUpButton doesn't like to do this automatically for us)
    enumerator = [[[popUpButton menu] itemArray] objectEnumerator];
    while(menuItem = [enumerator nextObject]){
        if([menuItem representedObject] == object){
            [menuItem setState:NSOnState];
        }else{
            [menuItem setState:NSOffState];
        }
    }
}
@end
