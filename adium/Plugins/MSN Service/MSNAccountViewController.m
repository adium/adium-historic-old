//
//  MSNAccountViewController.m
//  Adium
//
//  Created by Colin Barrett on Thu Jul 31 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "MSNAccountViewController.h"
#import "MSNAccount.h"

@interface MSNAccountViewController (PRIVATE)
- (id)initForOwner:(id)inOwner account:(id)inAccount;
- (void)dealloc;
- (void)accountStatusChanged:(NSNotification *)notification;
- (void)initAccountView;
@end

@implementation MSNAccountViewController

+ (id)accountViewForOwner:(id)inOwner account:(id)inAccount;
{
    return [[[self alloc] initForOwner:inOwner account:inAccount] autorelease];
}

- (NSView *)view
{
    return view_accountView;
}

//
- (NSArray *)auxilaryTabs
{
    return(nil);
}


//Save the changed properties
- (IBAction)saveChanges:(id)sender
{
    [[owner accountController] setProperty:[textField_email stringValue]
                                    forKey:@"Email"
                                   account:account];
    [[owner accountController] setProperty:[textField_friendlyName stringValue]
                                    forKey:@"FriendlyName"
                                   account:account];
}

- (void)configureViewAfterLoad
{
    //highlight the accountname field
    [[[view_accountView superview] window] setInitialFirstResponder:textField_email];
}

/*******************/
/* PRIVATE METHODS */
/*******************/

- (id)initForOwner:(id)inOwner account:(id)inAccount
{
    [super init];
    
    owner = [inOwner retain];
    account = [inAccount retain];
    
    if([NSBundle loadNibNamed:@"MSNAccountView" owner:self]){
        [self initAccountView];
    }else{
        NSLog(@"couldn't load account view bundle");
    }
    
    [[owner notificationCenter] addObserver:self selector:@selector(accountStatusChanged:) name:Account_PropertiesChanged object:account];
    
    [textField_email setFormatter:[AIStringFormatter stringFormatterAllowingCharacters:[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789+-._@"] length:129 caseSensitive:NO errorMessage:@"Improper Format"]];
    
    [textField_friendlyName setFormatter:[AIStringFormatter stringFormatterAllowingCharacters:[NSCharacterSet decomposableCharacterSet] length:129 caseSensitive:NO errorMessage:@"Improper Format"]];
    
    return self;
}

- (void)dealloc
{
    [[owner notificationCenter] removeObserver:self name:Account_PropertiesChanged object:account];
    
    [view_accountView release];
    
    [owner release];
    [account release];
    
    [super dealloc];
}

- (void)accountStatusChanged:(NSNotification *)notification
{
    BOOL	isOnline = [[[owner accountController] propertyForKey:@"Online" account:account] boolValue];

    //Dim unavailable controls
    [textField_email setEnabled:isOnline];
}

- (void)initAccountView
{
    NSString *savedEmail;
    NSString *savedFriendlyName;
    
    //Email
    savedEmail = [[owner accountController] propertyForKey:@"Email" account:account];
    if(savedEmail != nil && [savedEmail length] != 0){
        [textField_email setStringValue:savedEmail];
    }else{
        [textField_email setStringValue:@""];
    }
    
    //FriendlyName
    savedFriendlyName = [[owner accountController] propertyForKey:@"FriendlyName" account:account];
    if(savedFriendlyName != nil && [savedFriendlyName length] != 0){
        [textField_friendlyName setStringValue:savedFriendlyName];
    }else{
        [textField_friendlyName setStringValue:@""];
    }
}
@end
