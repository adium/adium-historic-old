/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
#import "AIMTOC2AccountViewController.h"
#import "AIMTOC2Account.h"

@implementation AIMTOC2AccountViewController

+ (id)accountViewForOwner:(id)inOwner account:(id)inAccount
{
    return([[[self alloc] initForOwner:inOwner account:inAccount] autorelease]);
}

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

    return(self);
}

- (void)dealloc
{
    [owner release];
    [account release];

    [super dealloc];
}

- (NSView *)view
{
    return(view_accountView);
}

- (void)configureViewForStatus:(ACCOUNT_STATUS)inStatus
{
    //Dim unavailable controls
    if(inStatus == STATUS_OFFLINE){
        [textField_handle setEnabled:YES];
    }else{
        [textField_handle setEnabled:NO];
    }
}

//Save the changed properties
- (void)saveChanges
{
    [[account properties] setObject:[textField_handle stringValue] forKey:@"Handle"];

    //Broadcast a properties changed message
    [[[owner accountController] accountNotificationCenter] postNotificationName:Account_PropertiesChanged
                                                                         object:self
                                                                       userInfo:nil];
}

// Set up the connect view using the saved properties
- (void)initAccountView
{
    NSString		*savedScreenName;

    //ScreenName
    savedScreenName = [[account properties] objectForKey:@"Handle"];
    if(savedScreenName != nil && [savedScreenName length] != 0){
        [textField_handle setStringValue:savedScreenName];
    }else{
        [textField_handle setStringValue:@""];
    }

    //Configure the control dimming for the current status
    [self configureViewForStatus:[account status]];
}

@end
