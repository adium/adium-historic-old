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
+ (id)accountView
{
    return([[[self alloc] init] autorelease]);
}

//Init
- (id)init
{
    [super init];
    account = nil;

    //Observe account changes
    [[adium contactController] registerListObjectObserver:self];
    
	//Load our auxiliary tabs and view
	[NSBundle loadNibNamed:[self nibName] owner:self];
    auxiliaryTabs = [[self loadAuxiliaryTabsFromTabView:view_auxiliaryTabView] retain];
	
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

//Configure the account view
- (void)configureForAccount:(AIAccount *)inAccount
{
    NSString		*savedPassword = nil;
	
	//Remember the account
	account = inAccount;
	
    //Display saved password
	if ([inAccount UID] && [[inAccount UID] length]){
		savedPassword = [[adium accountController] passwordForAccount:account];
	}
	
    if(savedPassword && [savedPassword length] != 0){
        [textField_password setStringValue:savedPassword];
    }else{
        [textField_password setStringValue:@""];
    }
    
    //Enable/Disable controls
	[self updateListObject:nil keys:nil silent:NO];
}

//Extract auxiliary tabs from an NSTabView inside an NSWindow
- (NSArray *)loadAuxiliaryTabsFromTabView:(NSTabView *)inTabView
{
	NSMutableArray *auxTabs = [NSMutableArray array];
	
	if(inTabView){
        //Get the array of tabs
        NSArray *tabViewItems = [inTabView tabViewItems];
		[auxTabs addObjectsFromArray:tabViewItems];
		
        //Now release the tabs and the window they came from
        NSEnumerator    *enumerator = [tabViewItems objectEnumerator];
        NSTabViewItem   *tabViewItem;
        
        while(tabViewItem = [enumerator nextObject]){
            [inTabView removeTabViewItem:tabViewItem];
        }
        
        [[inTabView window] release];
    }
	
	return(auxTabs);
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
        NSString		*password = [sender stringValue];
        NSString		*oldPassword;
		
        if(password && [password length] != 0){
			oldPassword = [[adium accountController] passwordForAccount:account];
			if (![password isEqualToString:oldPassword]){
				[[adium accountController] setPassword:password forAccount:account];
			}
        }else{
            [[adium accountController] forgetPasswordForAccount:account];
        }
    }
}

- (void)saveFieldsImmediately
{
	[self changedPreference:textField_password];
}

@end
