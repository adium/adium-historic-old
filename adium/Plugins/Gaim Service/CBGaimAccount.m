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

//don't change this
#define NO_GROUP @"__NoGroup__"

@implementation CBGaimAccount

/************************/
/* accountBlist methods */
/************************/

- (void)accountBlistNewNode:(GaimBlistNode *)node
{
//    NSLog(@"New node");
    if(node && GAIM_BLIST_NODE_IS_BUDDY(node))
    {
        GaimBuddy *buddy = (GaimBuddy *)node;
        
        //create the handle, group-less for now
        AIHandle *theHandle = [AIHandle 
            handleWithServiceID:[self serviceID]
            UID:[[NSString stringWithUTF8String:buddy->name] compactedString]
            serverGroup:NO_GROUP
            temporary:NO
            forAccount:self];
//        NSLog(@"created handle %@",[[NSString stringWithUTF8String:buddy->name] compactedString]);
        //stuff it in the dict - we store as a compactedString (that is, lowercase without spaces) for now because the TOC2 plugin does 
        [handleDict setObject:theHandle forKey:[[NSString stringWithFormat:@"%s", buddy->name] compactedString]];
        
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
                setObject:[NSString stringWithUTF8String:alias]
                forKey:@"Display Name"];
            [modifiedKeys addObject:@"Display Name"];
        }
                
        //update their idletime
        if(buddy->idle != (int)([[[theHandle statusDictionary] objectForKey:@"IdleSince"] timeIntervalSince1970]))
        {
            if(buddy->idle != 0)
            {
                [[theHandle statusDictionary]
                    setObject:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)buddy->idle]
                    forKey:@"IdleSince"];
            }
            else
            {
                [[theHandle statusDictionary] removeObjectForKey:@"IdleSince"];
            }
            [modifiedKeys addObject:@"IdleSince"];
        }
        
        //did the group change/did we finally find out what group the buddy is in
        GaimGroup *g = gaim_find_buddys_group(buddy);
        if(g && strcmp([[theHandle serverGroup] cString], g->name))
        {
            [[owner contactController] handle:[theHandle copy] removedFromAccount:self];
            NSLog(@"Changed to group %s", g->name);
            [theHandle setServerGroup:[NSString stringWithUTF8String:g->name]];
            [[owner contactController] handle:theHandle addedToAccount:self];
        }
        
        //grab their data, and compare
        GaimBuddyIcon *buddyIcon = gaim_buddy_get_icon(buddy);
        if(buddyIcon)
        {
            if(buddyIcon != [[[theHandle statusDictionary] objectForKey:@"BuddyImagePointer"] pointerValue])
            {
                NSLog(@"Icon for %s", buddy->name);
                                
                //save this for convenience
                [[theHandle statusDictionary]
                    setObject:[NSValue valueWithPointer:buddyIcon]
                    forKey:@"BuddyImagePointer"];
            
                //set the buddy image
                [[theHandle statusDictionary]
                    setObject:[[[NSImage alloc] initWithData:[NSData dataWithBytes:gaim_buddy_icon_get_data(buddyIcon, &(buddyIcon->len)) length:buddyIcon->len]] autorelease]
                    forKey:@"BuddyImage"];
                
                //BuddyImagePointer is just for us, shh, keep it secret ;)
                [modifiedKeys addObject:@"BuddyImage"];
            }
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
                    ? (gaim_connection_get_state(gaim_account_get_connection(buddy->account)) == GAIM_CONNECTING)
                    : (buddy->present != GAIM_BUDDY_SIGNING_OFF)];
            /* the silencing code does -not- work. I either need to change the way gaim works, or get someone to change it. */
        }
    }
}

- (void)accountBlistRemove:(GaimBuddyList *)list withNode:(GaimBlistNode *)node
{
    //stored the key as a compactedString originally
    [handleDict removeObjectForKey:[[NSString stringWithFormat:@"%s", ((GaimBuddy *)node)->name] compactedString]];
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
    return([NSArray arrayWithObjects:
        @"Display Name",
        @"Online",
        @"Offline",
        @"IdleSince",
        @"BuddyImage",
        nil]);
}

//subclasseds override these
- (NSDictionary *)defaultProperties { return([NSDictionary dictionary]); }
- (id <AIAccountViewController>)accountView{ return(nil); }
- (NSString *)accountID { return nil; }
- (NSString *)UID { return nil; }
- (NSString *)serviceID { return nil; }
- (NSString *)UIDAndServiceID { return nil; }
- (NSString *)accountDescription { return nil; }
- (void)statusForKey:(NSString *)key willChangeTo:(id)inValue { };

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
