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
	
    //Open a new instance of the account view
    if(![NSBundle loadNibNamed:[self nibName] owner:self]){
        NSLog(@"couldn't load account view bundle");
    }
	
	//Extract our auxilary tabs from the nib
	if(view_auxilaryTabView){
		auxilaryTabs = [[view_auxilaryTabView tabViewItems] copy];
		[view_auxilaryTabView removeTabViewItem:[view_auxilaryTabView tabViewItemAtIndex:0]];
		[view_auxilaryTabView removeTabViewItem:[view_auxilaryTabView tabViewItemAtIndex:0]];
		[[view_auxilaryTabView window] release];
	}
	
	//Observer account changes
	[[adium notificationCenter] addObserver:self
								   selector:@selector(accountPreferencesChanged:)
									   name:Preference_GroupChanged
									 object:account];
	[[adium contactController] registerListObjectObserver:self];
	
    return(self);
}

//Dealloc
- (void)dealloc
{    
	[[adium contactController] unregisterListObjectObserver:self];
    [[adium notificationCenter] removeObserver:self];
    [view_accountView release];
    [auxilaryTabs release];
	
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

	//Display formatted account name
	accountName = [account preferenceForKey:KEY_ACCOUNT_NAME group:GROUP_ACCOUNT_STATUS];
    if(accountName != nil && [accountName length] != 0){
        [textField_accountName setStringValue:accountName];
    }else{
        [textField_accountName setStringValue:[account UID]];
    }
	
    //Display saved password
    savedPassword = [[adium accountController] passwordForAccount:account];
    if(savedPassword != nil && [savedPassword length] != 0){
        [textField_password setStringValue:savedPassword];
    }else{
        [textField_password setStringValue:@""];
    }

	//Enable/Disable controls
	[self updateListObject:nil keys:nil delayed:NO silent:NO];

}

//Return the inline view for this account
- (NSView *)view
{
    return(view_accountView);
}

//Return the auxilary tabs for this account
- (NSArray *)auxilaryTabs
{    
    return(auxilaryTabs);
}

//Update display for account status change
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys delayed:(BOOL)delayed silent:(BOOL)silent
{
	if(inObject == nil || inObject == account){
		if(inModifiedKeys == nil || [inModifiedKeys containsObject:@"Online"]){
			[textField_accountName setEnabled:![[account statusObjectForKey:@"Online"] boolValue]];
			[textField_password setEnabled:![[account statusObjectForKey:@"Online"] boolValue]];
		}
	}
	
	return(nil);
}

//Display changed account preferences
- (void)accountPreferencesChanged:(NSNotification *)notification
{
    NSString    *group = [[notification userInfo] objectForKey:@"Group"];
    
    if(notification == nil || [group compare:GROUP_ACCOUNT_STATUS] == 0){
		NSString    *key = [[notification userInfo] objectForKey:@"Key"];
		
		//Redisplay if the username changes
		if([key compare:KEY_ACCOUNT_NAME] == 0){
			[self configureViewAfterLoad];
		}
    }
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

//User changed the account name
- (IBAction)accountNameChanged:(id)sender
{
    NSString    *accountName = [textField_accountName stringValue];
    
    if([[accountName compactedString] compare:[account UID]] != 0){
		//If the name has changed completely, create a new account
		//
		// ####
		// When we call changeUIDOfAccount, the account controller will delete us from the account list.
		// This deletion will spawn a rebuild of the account preferences window, which will in turn delete
		// this account view controller and all it's views.  The act of deleting the view which sent us this
		// message will cause a crash as we exit below.
		// 
		// I've implemented a quick 'patchy' fix.  If you see a real fix for this problem, make it be :)
		// ####
		//
		[self performSelector:@selector(_delayedChangeTo:) withObject:accountName afterDelay:0.0001];

    }else{
		[account setPreference:accountName forKey:KEY_ACCOUNT_NAME group:GROUP_ACCOUNT_STATUS];

	}
}
- (void)_delayedChangeTo:(NSString *)toName{
    NSString    *flatUserName = [toName compactedString];
    AIAccount   *targetAccount = account;
    
    //Create a new account
    targetAccount = [[adium accountController] changeUIDOfAccount:account to:flatUserName];
    
    //Update our custom formatting
    [targetAccount setPreference:toName forKey:KEY_ACCOUNT_NAME group:GROUP_ACCOUNT_STATUS];
}


@end
