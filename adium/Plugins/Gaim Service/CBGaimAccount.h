//
//  CBGaimAccount.h
//  Adium
//
//  Created by Colin Barrett on Sun Oct 19 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@interface CBGaimAccount : AIAccount <AIAccount_Handles>
{
    NSMutableDictionary	*handleDict;
}


//AIAccount sublcassed methods
- (void)initAccount;
- (void)dealloc;
- (NSArray *)supportedPropertyKeys;
- (void)statusForKey:(NSString *)key willChangeTo:(id)inValue;
- (NSDictionary *)defaultProperties;
- (id <AIAccountViewController>)accountView;
- (NSString *)accountID;
- (NSString *)UID;
- (NSString *)serviceID;
- (NSString *)UIDAndServiceID;
- (NSString *)accountDescription;

//AIAccount_Handles
// Returns a dictionary of AIHandles available on this account
- (NSDictionary *)availableHandles; //return nil if no contacts/list available

// Returns YES if the list is editable
- (BOOL)contactListEditable;

// Add a handle to this account
- (AIHandle *)addHandleWithUID:(NSString *)inUID serverGroup:(NSString *)inGroup temporary:(BOOL)inTemporary;
// Remove a handle from this account
- (BOOL)removeHandleWithUID:(NSString *)inUID;

// Add a group to this account
- (BOOL)addServerGroup:(NSString *)inGroup;
// Remove a group
- (BOOL)removeServerGroup:(NSString *)inGroup;
// Rename a group
- (BOOL)renameServerGroup:(NSString *)inGroup to:(NSString *)newName;
@end
