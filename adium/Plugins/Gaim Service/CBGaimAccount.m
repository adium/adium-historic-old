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
#define SCREEN_NAME "themindoverall"

//don't change this
#define PROTOCOL "prpl-oscar"
#define NO_GROUP @"__NoGroup__"

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
        
        //create the handle, group-less for now
        AIHandle *theHandle = [AIHandle 
            handleWithServiceID:[[service handleServiceType] identifier]
            UID:[NSString stringWithCString:buddy->name]
            serverGroup:NO_GROUP
            temporary:NO
            forAccount:self];
        
        //stuff it in the dict
        [handleDict setObject:theHandle forKey:[NSString stringWithFormat:@"%s", buddy->name]];
        
        //set up our ui_data
        node->ui_data = [theHandle retain];
    
        //[[owner contactController] handlesChangedForAccount:self];
    }
}

- (void)accountBlistUpdate:(GaimBuddyList *)list withNode:(GaimBlistNode *)node
{
    //NSLog(@"Update");
    if(node)
    {
        //extract the GaimBuddy from whatever we were passed
        GaimBuddy *buddy;
        if(GAIM_BLIST_NODE_IS_BUDDY(node))
            buddy = (GaimBuddy *)node;
        else if(GAIM_BLIST_NODE_IS_CONTACT(node))
            buddy = ((GaimContact *)node)->priority;
            
        NSMutableArray *modifiedKeys = [NSMutableArray array];
        AIHandle *theHandle = (AIHandle *)node->ui_data;
        
        int online = (GAIM_BUDDY_IS_ONLINE(buddy) ? 1 : 0);
        
        //NSLog(@"%d", online);
        
        //see if our online state is up to date
        if([[[theHandle statusDictionary] objectForKey:@"Online"] intValue] != online)
        {
            [[theHandle statusDictionary]
                setObject:[NSNumber numberWithInt:online] 
                forKey:@"Online"];
            [modifiedKeys addObject:@"Online"];
        }
        
        //snag the correct alias, and the current display name
        char *alias = (char *)gaim_get_buddy_alias(buddy);
        char *disp_name = (char *)[[[theHandle statusDictionary] objectForKey:@"Display Name"] cString];
        if(!disp_name) disp_name = "";
        
        //check 'em and update
        if(alias && strcmp(disp_name, alias))
        {
            [[theHandle statusDictionary] 
                setObject:[NSString stringWithCString:alias]
                forKey:@"Display Name"];
            [modifiedKeys addObject:@"Display Name"];
        }
        
        //did the group change (or did we finally find out what group the buddy is in?)
        GaimGroup *g = gaim_find_buddys_group(buddy);
        if(g && strcmp([[theHandle serverGroup] cString], g->name))
        {
            [[owner contactController] handle:[theHandle copy] removedFromAccount:self];
            NSLog(@"Changed to group %s", g->name);
            [theHandle setServerGroup:[NSString stringWithCString:g->name]];
            [[owner contactController] handle:theHandle addedToAccount:self];
        }
        
        //if anything chnaged
        if([modifiedKeys count] > 0)
        {
            //NSLog(@"Changed %@", modifiedKeys);
            
            //tell the contact controller, silencing if necessary
            [[owner contactController] handleStatusChanged:theHandle
                modifiedStatusKeys:modifiedKeys
                delayed:NO
                silent:online
                    ? (gaim_connection_get_state(gaim_account_get_connection(buddy->account)) != GAIM_CONNECTING)
                    : (buddy->present != GAIM_BUDDY_SIGNING_OFF)];
        }
        //nothing changed. boring. :P
        else
            NSLog(@"Nothing Changed");
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
                //get password
                [[owner accountController] passwordForAccount:self 
                    notifyingTarget:self selector:@selector(finishConnect:)];
            }
        }
        else //Disconnect
        {
            if(status == STATUS_ONLINE)
            {
                //we're signing off, give us a minute.
                [[owner accountController] 
                    setProperty:[NSNumber numberWithInt:STATUS_DISCONNECTING]
                    forKey:@"Status" account:self];
                
                //delete the account, sign everybody off
                GaimAccount *account;
                if(account = gaim_accounts_find(SCREEN_NAME, PROTOCOL))
                {
                    gaim_account_disconnect(account);
                    gaim_accounts_delete(account);
                }
                
                //done
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
        //now we start to connect
        [[owner accountController] 
            setProperty:[NSNumber numberWithInt:STATUS_CONNECTING]
            forKey:@"Status" account:self];

        //setup the account, get things ready
        GaimAccount *testAccount = gaim_account_new(SCREEN_NAME, PROTOCOL);
        gaim_account_set_password(testAccount, [inPassword cString]);
        
        //this is a bit of a hack, but it will do for now
        GaimConnection *conn =  gaim_account_connect(testAccount);
        if(gaim_connection_get_state(conn) != GAIM_DISCONNECTED) //if we're not disconneted, signed on!
        {
            gaim_accounts_add(testAccount);
            
            [[owner accountController]
                setProperty:[NSNumber numberWithInt:STATUS_ONLINE]
                forKey:@"Status" account:self];
        }
        else //aw nuts, something must have happened.
        {
            [[owner accountController] 
                    setProperty:[NSNumber numberWithInt:STATUS_OFFLINE]
                    forKey:@"Status" account:self];
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
