//
//  CBGaimAccount.m
//  Adium
//
//  Created by Colin Barrett on Sun Oct 19 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "CBGaimAccount.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"

#include "internal.h"
#include "connection.h"
#include "conversation.h"
#include "core.h"
#include "debug.h"
#include "ft.h"
#include "notify.h"
#include "plugin.h"
#include "pounce.h"
#include "prefs.h"
#include "privacy.h"
#include "proxy.h"
#include "request.h"
#include "signals.h"
#include "sslconn.h"
#include "sound.h"
#include "util.h"

@implementation CBGaimAccount

/********************************/
/* AIAccount subclassed methods */
/********************************/

- (void)initAccount
{
    handleDict = [[NSMutableDictionary alloc] init];
}

- (void)dealloc
{
    [handleDict release];
    
    [super dealloc];
}

- (NSArray *)supportedPropertyKeys
{
    return([NSArray arrayWithObjects:@"Online", @"Offline", nil]);
}

- (void)statusForKey:(NSString *)key willChangeTo:(id)inValue
{
    NSLog(@"gaim: statusForKey: %@ willChangeTo: %@", key, inValue);
    ACCOUNT_STATUS status = [[[owner accountController] propertyForKey:@"Status" account:self] intValue];
        
    if([key compare:@"Online"] == 0)
    {
        if([inValue boolValue]) //Connect
        { 
            if(status == STATUS_OFFLINE)
            {
                [[owner accountController] 
                    setProperty:[NSNumber numberWithInt:STATUS_CONNECTING]
                    forKey:@"Status" account:self];
                    
                //****** Create a test account *********
                //#warning put username and pass here to connect!! :)
                GaimAccount *testAccount = gaim_account_new("otsku", "prpl-oscar");
                gaim_account_set_password(testAccount, "UJ3Vj48Z");
                gaim_account_connect(testAccount);
                //**************************************
                
                [[owner accountController]
                    setProperty:[NSNumber numberWithInt:STATUS_ONLINE]
                    forKey:@"Status" account:self];
            }
        }
        else //Disconnect
        {
            if(status == STATUS_ONLINE)
            {
                NSLog(@"We don't do that yet. :P Quit to disconnect");
            }
        }
    }
}

- (NSDictionary *)defaultProperties
{
    return([NSDictionary dictionary]);
}

- (id <AIAccountViewController>)accountView{
    return(nil);
}

- (NSString *)accountID{
    return(@"GAIM");
}

- (NSString *)UID{
    return(@"GAIM");
}
    
- (NSString *)serviceID{
    return(@"GAIM");
}

- (NSString *)UIDAndServiceID{
    return(@"TEST.TEST");
}

- (NSString *)accountDescription
{
    return(@"LIBGAIM! :D");
}

/*********************/
/* AIAccount_Handles */
/*********************/

// Returns a dictionary of AIHandles available on this account
- (NSDictionary *)availableHandles //return nil if no contacts/list available
{
    int	status = [[[owner accountController] propertyForKey:@"Status" account:self] intValue];
    
    if(status == STATUS_ONLINE || status == STATUS_CONNECTING)
    {
        return(handleDict);
    }
    else
    {
        return(nil);
    }
}
// Returns YES if the list is editable
- (BOOL)contactListEditable
{
    return NO;
}

// Add a handle to this account
- (AIHandle *)addHandleWithUID:(NSString *)inUID serverGroup:(NSString *)inGroup temporary:(BOOL)inTemporary
{
    return nil;
}
// Remove a handle from this account
- (BOOL)removeHandleWithUID:(NSString *)inUID
{
    return NO;
}

// Add a group to this account
- (BOOL)addServerGroup:(NSString *)inGroup
{
    return NO;
}
// Remove a group
- (BOOL)removeServerGroup:(NSString *)inGroup
{
    return NO;
}
// Rename a group
- (BOOL)renameServerGroup:(NSString *)inGroup to:(NSString *)newName
{
    return NO;
}

- (void)displayError:(NSString *)errorDesc
{
    [[owner interfaceController] handleErrorMessage:@"Gaim error"
                                    withDescription:errorDesc];
}


@end
