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

#import "AIMTOC2ServicePlugin.h"
#import "AIMTOC2AccountViewController.h"
#import "AIMTOC2Account.h"

@interface AIMTOC2AccountViewController (PRIVATE)
- (id)initForAccount:(id)inAccount;
- (void)accountPropertiesChanged:(NSNotification *)notification;
- (void)_configurePasswordField;
@end

@implementation AIMTOC2AccountViewController

+ (id)accountViewForAccount:(id)inAccount
{
    return([[[self alloc] initForAccount:inAccount] autorelease]);
}

- (NSView *)view
{
    return(view_accountView);
}

- (NSArray *)auxilaryTabs
{    
    return(auxilaryTabs);
}

- (void)configureViewAfterLoad
{
    NSString		*savedScreenName;

    //Highlight the accountname field
    [[[view_accountView superview] window] setInitialFirstResponder:textField_handle];
    
    //ScreenName
    savedScreenName = [account preferenceForKey:AIM_TOC2_KEY_USERNAME group:GROUP_ACCOUNT_STATUS];
    if(savedScreenName != nil && [savedScreenName length] != 0){
        [textField_handle setStringValue:savedScreenName];
    }else{
        [textField_handle setStringValue:[account UID]];
    }
    
    //Password
    [self _configurePasswordField];

    //Fill in our host & port
    [textField_host setStringValue:[account preferenceForKey:AIM_TOC2_KEY_HOST group:GROUP_ACCOUNT_STATUS]];
    [textField_port setStringValue:[account preferenceForKey:AIM_TOC2_KEY_PORT group:GROUP_ACCOUNT_STATUS]];

    //Full name
    [textField_fullName setStringValue:[account preferenceForKey:@"FullName" group:GROUP_ACCOUNT_STATUS]];
    
    //Profile
    NSAttributedString	*profile = [NSAttributedString stringWithData:[account preferenceForKey:AIM_TOC2_KEY_PROFILE group:GROUP_ACCOUNT_STATUS]];
    if(!profile) profile = [[[NSAttributedString alloc] initWithString:@""] autorelease];

    [[textView_textProfile textStorage] setAttributedString:profile];
}


// Private ------------------------------------------------------------------------------
- (id)initForAccount:(id)inAccount
{
    [super init];
    account = inAccount;

    //Open a new instance of the account view
    if(![NSBundle loadNibNamed:@"AIMTOCAccountView" owner:self]){
        NSLog(@"couldn't load account view bundle");
    }

    //Configure the account name field
    [textField_handle setFormatter:
	[AIStringFormatter stringFormatterAllowingCharacters:[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789 "]
						      length:16
					       caseSensitive:NO
						errorMessage:@"You user name must be 16 characters or less, contain only letters and numbers, and must start with a letter."]];
    
    //Pull out our tabs
    auxilaryTabs = [[view_auxilaryTabView tabViewItems] copy];
    [view_auxilaryTabView removeTabViewItem:[view_auxilaryTabView tabViewItemAtIndex:0]];
    [view_auxilaryTabView removeTabViewItem:[view_auxilaryTabView tabViewItemAtIndex:0]];
    [[view_auxilaryTabView window] release];
    
    //Observer account changes
    [[adium notificationCenter] addObserver:self
				   selector:@selector(accountPreferencesChanged:)
				       name:Preference_GroupChanged
				     object:account];
    
    return(self);
}

//
- (void)dealloc
{    
    [[adium notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    //Cleanup our nib
    [view_accountView release];
    [auxilaryTabs release];

    [super dealloc];
}

//Account preferences changed
- (void)accountPreferencesChanged:(NSNotification *)notification
{
    NSString    *group = [[notification userInfo] objectForKey:@"Group"];
    
    if(notification == nil || [group compare:GROUP_ACCOUNT_STATUS] == 0){
	NSString    *key = [[notification userInfo] objectForKey:@"Key"];

	//Redisplay if the username changes
	if([key compare:AIM_TOC2_KEY_USERNAME] == 0){
	    [self configureViewAfterLoad];
	}
    }
}

//User changed the username
- (IBAction)userNameChanged:(id)sender
{
    NSString    *userName = [textField_handle stringValue];
    
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
    if([[userName compactedString] compare:[account UID]] != 0){
	[self performSelector:@selector(_delayedChangeTo:) withObject:userName afterDelay:0.0001];
    }
}
- (void)_delayedChangeTo:(NSString *)toName{
    NSString    *flatUserName = [toName compactedString];
    AIAccount   *targetAccount = account;
    
    //Create a new account
    targetAccount = [[adium accountController] changeUIDOfAccount:account to:flatUserName];
    
    //Update our custom formatting
    [targetAccount setPreference:toName forKey:AIM_TOC2_KEY_USERNAME group:GROUP_ACCOUNT_STATUS];
}

//Save changes made to a preference control
- (IBAction)changedPreference:(id)sender
{
    if(sender == textField_host){
        [account setPreference:[sender stringValue] forKey:AIM_TOC2_KEY_HOST group:GROUP_ACCOUNT_STATUS];

    }else if(sender == textField_port){
        [account setPreference:[sender stringValue] forKey:AIM_TOC2_KEY_PORT group:GROUP_ACCOUNT_STATUS];

    }else if(sender == textField_fullName){
        [account setPreference:[sender stringValue] forKey:@"FullName" group:GROUP_ACCOUNT_STATUS];    

    }else if(sender == textField_password){
        NSString	*password = [sender stringValue];

        //Apply the changes
        if(password && [password length] != 0){
            [[adium accountController] setPassword:password forAccount:account];
        }else{
            [[adium accountController] forgetPasswordForAccount:account];
        }

    }
}

//Profile text was changed
- (void)textDidEndEditing:(NSNotification *)notification
{
    [account setPreference:[[textView_textProfile textStorage] dataRepresentation] forKey:AIM_TOC2_KEY_PROFILE group:GROUP_ACCOUNT_STATUS];
}

//
- (void)_configurePasswordField
{
    NSString		*savedPassword;
    
    savedPassword = [[adium accountController] passwordForAccount:account];
    if(savedPassword != nil && [savedPassword length] != 0){
        [textField_password setStringValue:savedPassword];
    }else{
        [textField_password setStringValue:@""];
    }
}

@end
