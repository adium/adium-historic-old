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

#import "AIAccountViewController.h"

@implementation AIAccountViewController

//Create a new account view
+ (id)accountViewForAccount:(id)inAccount
{
    return([[[self alloc] initForAccount:inAccount] autorelease]);
}

//Init
- (id)initForAccount:(id)inAccount
{
    [super init];
    account = inAccount;
	auxiliaryTabs = nil;

    //Open a new instance of the account view
    if(![NSBundle loadNibNamed:[self nibName] owner:self]){
        NSLog(@"couldn't load account view bundle");
    }
    
    [self loadAuxiliaryTabsFromTabView:view_auxiliaryTabView];

    //Observer account changes
    [[adium contactController] registerListObjectObserver:self];
    
    return(self);
}

//Dealloc
- (void)dealloc
{    
    [[adium contactController] unregisterListObjectObserver:self];
    [[adium notificationCenter] removeObserver:self];
    [view_accountView release];
    [auxiliaryTabs release];
    
    [super dealloc];
}

//Nib to load
- (NSString *)nibName
{
    return(@"");    
}

//Configure the account view
- (void)configureViewAfterLoad
{
    NSString		*accountName, *savedPassword;
	AIServiceType	*serviceType = [[account service] handleServiceType];

    //Display saved password
    savedPassword = [[adium accountController] passwordForAccount:account];
    if(savedPassword != nil && [savedPassword length] != 0){
        [textField_password setStringValue:savedPassword];
    }else{
        [textField_password setStringValue:@""];
    }
    
    //Enable/Disable controls
	[self updateListObject:nil keys:nil silent:NO];
    
}

//Return the inline view for this account
- (NSView *)view
{
    return(view_accountView);
}

//Return the auxiliary tabs for this account
- (NSArray *)auxiliaryTabs
{    
    return(auxiliaryTabs);
}

- (NSView *)auxiliaryAccountDetails
{
	return nil;
}

- (void)loadAuxiliaryTabsFromTabView:(NSTabView *)inTabView
{
    //Extract our auxiliary tabs from the nib, where they are stored in an NSTabView inside an NSWindow
    if(inTabView){
        //Get the array of tabs
        NSArray *tabViewItems = [inTabView tabViewItems];
		
		//Create the auxiliaryTabs array if this is an initial set of auxiliary tabs
		//or add to the array if auxiliaries already exist
		if (!auxiliaryTabs)
			auxiliaryTabs = [tabViewItems mutableCopy];
		else
			[auxiliaryTabs addObjectsFromArray:tabViewItems];
		
        //Now release the tabs and the window they came from
        NSEnumerator    *enumerator = [tabViewItems objectEnumerator];
        NSTabViewItem   *tabViewItem;
        
        while (tabViewItem = [enumerator nextObject]){
            [inTabView removeTabViewItem:tabViewItem];
        }
        
        [[inTabView window] release];
    }
}

//Update display for account status change
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
	if(inObject == nil || inObject == account){
		if(inModifiedKeys == nil || [inModifiedKeys containsObject:@"Online"]){
			[textField_password setEnabled:![[account statusObjectForKey:@"Online"] boolValue]];
		}
	}
	
	return(nil);
}

//Save changes made to a preference control
- (IBAction)changedPreference:(id)sender
{
    //Save changed password
    if(sender == textField_password){
        NSString	*password = [sender stringValue];
        
        if(password && [password length] != 0){
            [[adium accountController] setPassword:password forAccount:account];
        }else{
            [[adium accountController] forgetPasswordForAccount:account];
        }
    }
}

@end
