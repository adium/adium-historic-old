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

#define SCREEN_NAME "libgadium"
#define PASSWORD "roxor"
#define PROTOCOL "prpl-oscar"

@implementation CBGaimAccount

/************************/
/* accountBlist methods */
/************************/

- (void)accountBlistNewNode:(GaimBlistNode *)node
{
    if(node && GAIM_BLIST_NODE_IS_BUDDY(node))
    {
        GaimBuddy *buddy = (GaimBuddy *)node;
                
        AIHandle *theHandle = [AIHandle 
            handleWithServiceID:[[service handleServiceType] identifier]
            UID:[NSString stringWithCString:buddy->name]
            serverGroup:@"Libgaim!"
            temporary:NO
            forAccount:self];
            
        [handleDict setObject:theHandle forKey:[NSString stringWithFormat:@"%s", buddy->name]];
        
        node->ui_data = [theHandle retain];
    }
}

- (void)accountBlistUpdate:(GaimBuddyList *)list withNode:(GaimBlistNode *)node
{
    if(node && GAIM_BLIST_NODE_IS_BUDDY(node))
    {
        GaimBuddy *buddy = (GaimBuddy *)node;
        if(buddy->present == GAIM_BUDDY_SIGNING_ON || buddy->present == GAIM_BUDDY_ONLINE)
        {
            AIHandle *theHandle = node->ui_data;
            
            [[theHandle statusDictionary] 
                setObject:[NSNumber numberWithInt:1] 
                forKey:@"Online"];
                
            [[theHandle statusDictionary] 
                setObject:[NSString stringWithCString:buddy->server_alias]
                forKey:@"Display Name"];
                
            [[owner contactController] handleStatusChanged:theHandle
                modifiedStatusKeys:[NSArray arrayWithObjects:@"Online", @"Display Name",nil]
                delayed:NO
                silent:NO];
        }
        else if(buddy->present == GAIM_BUDDY_SIGNING_OFF || buddy->present == GAIM_BUDDY_OFFLINE)
        {
            AIHandle *theHandle = (AIHandle *)node->ui_data;
            
            [[theHandle statusDictionary] 
                setObject:[NSNumber numberWithInt:0] 
                forKey:@"Online"];
            
            [[owner contactController] handleStatusChanged:theHandle
                modifiedStatusKeys:[NSArray arrayWithObjects:@"Online", nil]
                delayed:NO
                silent:NO];
        }
    }
}

- (void)accountBlistRemove:(GaimBuddyList *)list withNode:(GaimBlistNode *)node
{
    [handleDict removeObjectForKey:[NSString stringWithFormat:@"%s", ((GaimBuddy *)node)->name]];
    [(AIHandle *)node->ui_data release];
    node->ui_data = NULL;
}

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
                GaimAccount *testAccount = gaim_account_new(SCREEN_NAME, PROTOCOL);
                gaim_account_set_password(testAccount, PASSWORD);
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
    return([NSString stringWithCString:SCREEN_NAME]);
}

- (NSString *)UID{
    return([NSString stringWithCString:SCREEN_NAME]);
}
    
- (NSString *)serviceID{
    return([NSString stringWithCString:PROTOCOL]);
}

- (NSString *)UIDAndServiceID{
    return([NSString stringWithFormat:@"%s.%s", PROTOCOL, SCREEN_NAME]);
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
