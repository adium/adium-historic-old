/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
#import "AIAccount.h"

@implementation AIAccountViewController

//Create a new account view controller
+ (id)accountViewController
{
    return([[[self alloc] init] autorelease]);
}

//Init
- (id)init
{
    [super init];
    account = nil;
    
	//Load our default views
	[NSBundle loadNibNamed:@"AccountViews" owner:self];

	//Load custom views and tabs for our subclass (If it specified a nib name)
	if([self nibName]){
		[NSBundle loadNibNamed:[self nibName] owner:self];
		auxiliaryTabs = [[self loadAuxiliaryTabsFromTabView:view_auxiliaryTabView] retain];
	}
	
    return(self);
}

//Dealloc
- (void)dealloc
{    
    [[adium contactController] unregisterListObjectObserver:self];
    [[adium notificationCenter] removeObserver:self];
//    [view_accountView release];
//	[view_auxiliaryTabView release];
	[auxiliaryTabs release];
    
    [super dealloc];
}


//Account specific views -----------------------------------------------------------------------------------------------
#pragma mark Account specific views
//Setup view
- (NSView *)setupView
{
    return(view_setup);
}

//Connection view
- (NSView *)connectionView
{
    return(view_connection);
}

//Auxilliary tabs
- (NSArray *)auxiliaryTabs
{
	return(auxiliaryTabs);
}

//Nib containing custom views or tabs (Optional, for subclasses)
- (NSString *)nibName
{
    return(@"");    
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


//Preferences ----------------------------------------------------------------------------------------------------------
#pragma mark Preferences
//Configure the account view
- (void)configureForAccount:(AIAccount *)inAccount
{
    NSString		*savedPassword = nil;
	
	if(account != inAccount){
		account = inAccount;
		
		//UID
		NSString	*formattedUID = [account preferenceForKey:@"FormattedUID" group:GROUP_ACCOUNT_STATUS];
		[textField_accountUID setStringValue:(formattedUID && [formattedUID length] ? formattedUID : [account UID])];

		//Password
		if([account UID] && [[account UID] length]){
			savedPassword = [[adium accountController] passwordForAccount:account];
		}
		if(savedPassword && [savedPassword length] != 0){
			[textField_password setStringValue:savedPassword];
		}else{
			[textField_password setStringValue:@""];
		}
		
		//Host
//		hostName = [theAccount host];
//		[textField_hostName setStringValue:(hostName ? hostName : @"")];

		
		
//		- (NSString *)host{
//			NSString *hostKey = [self hostKey];
//			return (hostKey ? [self preferenceForKey:hostKey group:GROUP_ACCOUNT_STATUS] : nil); 
//		}
//		- (int)port{ 
//			NSString *portKey = [self portKey];
//			return (portKey ? [[self preferenceForKey:portKey group:GROUP_ACCOUNT_STATUS] intValue] : nil); 
//		}
		
		
		
		
		
		//Port number
//		port = [theAccount port];
//		if (port){
//			[textField_portNumber setIntValue:port];
//		}else{
//			[textField_portNumber setStringValue:@""];	
//		}
		
		
		
		//Port
		
		
	}
}

//Save preference changes as they are made
- (IBAction)changedPreference:(id)sender
{
	if(sender == textField_accountUID){
		NSString *newUID = [textField_accountUID stringValue];
		
		if(![[account UID] isEqualToString:newUID]){
			[[adium accountController] changeUIDOfAccount:account to:newUID];			
		}
		
	}else if(sender == textField_password){
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

//Save changes made in delayed controls
- (void)saveFieldsImmediately
{
	[self changedPreference:textField_password];
}

@end
