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

#import "AIOscarAccountViewController.h"
#import "AIOscarAccount.h"

#define OSCAR_ACCOUNT_VIEW_NIB		@"OscarAccountView"

@interface AIOscarAccountViewController (PRIVATE)
- (id)initForOwner:(id)inOwner account:(id)inAccount;
- (void)accountStatusChanged:(NSNotification *)notification;
- (void)initAccountView;
@end

@implementation AIOscarAccountViewController

//
+ (id)accountViewForOwner:(id)inOwner account:(id)inAccount
{
    return([[[self alloc] initForOwner:inOwner account:inAccount] autorelease]);
}

//
- (NSView *)view
{
    return(view_accountView);
}

//
- (NSArray *)auxilaryTabs
{
    return(nil);
}

//Save the changed properties
- (IBAction)saveChanges:(id)sender
{
    [[owner accountController] setProperty:[textField_handle stringValue]
                                    forKey:@"Handle"
                                   account:account];
}

//
- (void)configureViewAfterLoad
{
    //Highlight the accountname field
    [[[view_accountView superview] window] setInitialFirstResponder:textField_handle];
}


// Private ------------------------------------------------------------------------------
//
- (id)initForOwner:(id)inOwner account:(id)inAccount
{
    [super init];

    //Retain the owner and account
    owner = [inOwner retain];
    account = [inAccount retain];

    //Open a new instance of the account view
    if([NSBundle loadNibNamed:OSCAR_ACCOUNT_VIEW_NIB owner:self]){
        [self initAccountView];
    }else{
        NSLog(@"couldn't load account view bundle");
    }

    [[owner notificationCenter] addObserver:self selector:@selector(accountStatusChanged:) name:Account_PropertiesChanged object:account];

    //Configure the account name field
    [textField_handle setFormatter:[AIStringFormatter stringFormatterAllowingCharacters:[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789@. "] length:16 caseSensitive:NO errorMessage:@"You account name must be 16 characters or less, contain only letters and numbers, and must start with a letter."]];

    return(self);
}

//
- (void)dealloc
{
    [[owner notificationCenter] removeObserver:self name:Account_PropertiesChanged object:account];

    //Cleanup our nib
    [view_accountView release];

    [owner release];
    [account release];

    [super dealloc];
}

//
- (void)accountStatusChanged:(NSNotification *)notification
{
    BOOL	isOnline = [[[owner accountController] propertyForKey:@"Online" account:account] boolValue];

    //Dim unavailable controls
    [textField_handle setEnabled:isOnline];
}

// Set up the connect view using the saved properties
- (void)initAccountView
{
    NSString		*savedScreenName;

    //ScreenName
    savedScreenName = [[owner accountController] propertyForKey:@"Handle" account:account];
    if(savedScreenName != nil && [savedScreenName length] != 0){
        [textField_handle setStringValue:savedScreenName];
    }else{
        [textField_handle setStringValue:@""];
    }
}

@end
