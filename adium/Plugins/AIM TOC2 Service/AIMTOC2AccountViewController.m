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

#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "AIMTOC2ServicePlugin.h"
#import "AIMTOC2AccountViewController.h"
#import "AIMTOC2Account.h"

@interface AIMTOC2AccountViewController (PRIVATE)
- (id)initForOwner:(id)inOwner account:(id)inAccount;
- (void)dealloc;
- (void)accountPropertiesChanged:(NSNotification *)notification;
- (void)initAccountView;
- (void)_configurePasswordField;
@end

@implementation AIMTOC2AccountViewController

+ (id)accountViewForOwner:(id)inOwner account:(id)inAccount
{
    return([[[self alloc] initForOwner:inOwner account:inAccount] autorelease]);
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
    //highlight the accountname field
    [[[view_accountView superview] window] setInitialFirstResponder:textField_handle];

    //Fill in our host & port
    [textField_host setStringValue:[[owner accountController] propertyForKey:AIM_TOC2_KEY_HOST account:account]];
    [textField_port setStringValue:[[owner accountController] propertyForKey:AIM_TOC2_KEY_PORT account:account]];

    //Full name
    [textField_fullName setStringValue:[[owner accountController] propertyForKey:@"FullName" account:account]];
    
    //Profile
    NSAttributedString	*profile = [NSAttributedString stringWithData:[[owner accountController] propertyForKey:AIM_TOC2_KEY_PROFILE account:account]];
    if(!profile) profile = [[[NSAttributedString alloc] initWithString:@""] autorelease];

    [[textView_textProfile textStorage] setAttributedString:profile];
}


// Private ------------------------------------------------------------------------------
- (id)initForOwner:(id)inOwner account:(id)inAccount
{
    [super init];

    //Retain the owner and account
    owner = [inOwner retain];
    account = [inAccount retain];

    //Open a new instance of the account view
    if([NSBundle loadNibNamed:@"AIMTOCAccountView" owner:self]){
        [self initAccountView];
    }else{
        NSLog(@"couldn't load account view bundle");
    }

    [[owner notificationCenter] addObserver:self selector:@selector(accountPropertiesChanged:) name:Account_PropertiesChanged object:account];
    [self accountPropertiesChanged:nil];

    //Configure the account name field
    [textField_handle setFormatter:[AIStringFormatter stringFormatterAllowingCharacters:[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789 "] length:16 caseSensitive:NO errorMessage:@"You user name must be 16 characters or less, contain only letters and numbers, and must start with a letter."]];

    //Pull out our tabs
    auxilaryTabs = [[view_auxilaryTabView tabViewItems] copy];
    [view_auxilaryTabView removeTabViewItem:[view_auxilaryTabView tabViewItemAtIndex:0]];
    [view_auxilaryTabView removeTabViewItem:[view_auxilaryTabView tabViewItemAtIndex:0]];
    [[view_auxilaryTabView window] release];
    
    //Observer account name changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userNameChanged:) name:NSControlTextDidChangeNotification object:textField_handle];
    
    return(self);
}

- (void)dealloc
{
    [[owner notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    //Cleanup our nib
    [view_accountView release];
    
    [owner release];
    [account release];

    [super dealloc];
}

//User changed the username
- (IBAction)userNameChanged:(id)sender
{
    //Apply the changes
    [[owner accountController] setProperty:[textField_handle stringValue]
                                    forKey:AIM_TOC2_KEY_USERNAME
                                   account:account];

    //Reset the password field
    [self _configurePasswordField];
}

//Save changes made to a preference control
- (IBAction)preferenceChanged:(id)sender
{
    if(sender == textField_host){
        [[owner accountController] setProperty:[sender stringValue]
                                        forKey:AIM_TOC2_KEY_HOST
                                       account:account];

    }else if(sender == textField_port){
        [[owner accountController] setProperty:[sender stringValue]
                                        forKey:AIM_TOC2_KEY_PORT
                                       account:account];

    }else if(sender == textField_fullName){
        [[owner accountController] setProperty:[sender stringValue]
                                        forKey:@"FullName"
                                       account:account];    

    }else if(sender == textField_password){
        NSString	*password = [sender stringValue];

        //Apply the changes
        if(password && [password length] != 0){
            [[owner accountController] setPassword:password forAccount:account];
        }else{
            [[owner accountController] forgetPasswordForAccount:account];
        }
        
    }
}

//Profile text was changed
- (void)textDidEndEditing:(NSNotification *)notification
{
    [[owner accountController] setProperty:[[textView_textProfile textStorage] dataRepresentation]
                                        forKey:AIM_TOC2_KEY_PROFILE
                                       account:account];
}

//The properties of our account changed
- (void)accountPropertiesChanged:(NSNotification *)notification
{
    NSString	*key = [[notification userInfo] objectForKey:@"Key"];

    //Dim unavailable controls
    if(notification == nil || [key compare:@"Online"] == 0){
        BOOL	isOnline = [[[owner accountController] propertyForKey:@"Online" account:account] boolValue];

        [textField_handle setEnabled:!isOnline];
        [textField_password setEnabled:!isOnline];
    }
}

//Set up the connect view using the saved properties
- (void)initAccountView
{
    NSString		*savedScreenName;

    //ScreenName
    savedScreenName = [[owner accountController] propertyForKey:AIM_TOC2_KEY_USERNAME account:account];
    if(savedScreenName != nil && [savedScreenName length] != 0){
        [textField_handle setStringValue:savedScreenName];
    }else{
        [textField_handle setStringValue:@""];
    }

    //Password
    [self _configurePasswordField];
}

//
- (void)_configurePasswordField
{
    NSString		*savedPassword;
    
    savedPassword = [[owner accountController] passwordForAccount:account];
    if(savedPassword != nil && [savedPassword length] != 0){
        [textField_password setStringValue:savedPassword];
    }else{
        [textField_password setStringValue:@""];
    }
}

@end
