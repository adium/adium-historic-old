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

#warning change this to your username to connect :)
#define SCREEN_NAME "otsku"

//don't change this
#define PROTOCOL "prpl-oscar"

@implementation CBGaimAccount

/************************/
/* accountBlist methods */
/************************/

- (void)accountBlistNewNode:(GaimBlistNode *)node
{
    //NSLog(@"New node");
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
    
        [[owner contactController] handlesChangedForAccount:self];
    }
}

- (void)accountBlistUpdate:(GaimBuddyList *)list withNode:(GaimBlistNode *)node
{
    //NSLog(@"Update");
    if(node)
    {
        GaimBuddy *buddy;
        if(GAIM_BLIST_NODE_IS_BUDDY(node))
            buddy = (GaimBuddy *)node;
        else if(GAIM_BLIST_NODE_IS_CONTACT(node))
            buddy = ((GaimContact *)node)->priority;
            
        if(GAIM_BUDDY_IS_ONLINE(buddy))
        {
            NSLog(@"Online");
            AIHandle *theHandle = (AIHandle *)node->ui_data;
            
            [[theHandle statusDictionary] 
                setObject:[NSNumber numberWithInt:1] 
                forKey:@"Online"];
            
            if(buddy->server_alias) //if there is a server alias
                [[theHandle statusDictionary] 
                    setObject:[NSString stringWithCString:buddy->server_alias]
                    forKey:@"Display Name"];
            
            [[owner contactController] handleStatusChanged:theHandle
                modifiedStatusKeys:[NSArray arrayWithObjects:@"Online", @"Display Name",nil]
                delayed:NO
                silent:(gaim_connection_get_state(gaim_account_get_connection(buddy->account)) 
                    != GAIM_CONNECTING)];
        }
        else
        {
            //NSLog(@"Offline");
            
            AIHandle *theHandle = (AIHandle *)node->ui_data;
            
            [[theHandle statusDictionary] 
                setObject:[NSNumber numberWithInt:0] 
                forKey:@"Online"];
            
            [[owner contactController] handleStatusChanged:theHandle
                modifiedStatusKeys:[NSArray arrayWithObjects:@"Online", nil]
                delayed:NO
                silent:(buddy->present != GAIM_BUDDY_SIGNING_OFF)];
        }
    }
}

- (void)accountBlistRemove:(GaimBuddyList *)list withNode:(GaimBlistNode *)node
{
    [handleDict removeObjectForKey:[NSString stringWithFormat:@"%s", ((GaimBuddy *)node)->name]];
    [(AIHandle *)node->ui_data release];
    node->ui_data = NULL;
    
    [[owner contactController] handlesChangedForAccount:self];
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
                
                //get password
                [[owner accountController] passwordForAccount:self 
                    notifyingTarget:self selector:@selector(finishConnect:)];
                
            }
        }
        else //Disconnect
        {
            if(status == STATUS_ONLINE)
            {
                [[owner accountController] 
                    setProperty:[NSNumber numberWithInt:STATUS_DISCONNECTING]
                    forKey:@"Status" account:self];

                GaimAccount *account;
                if(account = gaim_accounts_find(SCREEN_NAME, PROTOCOL))
                {
                    gaim_account_disconnect(account);
                    gaim_accounts_delete(account);
                }
                
                [[owner accountController] 
                    setProperty:[NSNumber numberWithInt:STATUS_OFFLINE]
                    forKey:@"Status" account:self];
            }
        }
    }
}

- (void)finishConnect:(NSString *)inPassword
{
    if(inPassword && [inPassword length] != 0)
    {
        //****** Create a test account *********
        GaimAccount *testAccount = gaim_account_new(SCREEN_NAME, PROTOCOL);
        gaim_account_set_password(testAccount, [inPassword cString]);
        gaim_account_connect(testAccount);
        gaim_accounts_add(testAccount);
        //**************************************
        
        [[owner accountController]
            setProperty:[NSNumber numberWithInt:STATUS_ONLINE]
            forKey:@"Status" account:self];

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
