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

#import <Cocoa/Cocoa.h>

@class AIAdium, AIContactHandle, AIContactGroup, AIHandleIdentifier, AIServiceType, AIMessageObject, AIContactObject;
@protocol AIContentObject, AIServiceController, AIAccountViewController;

typedef enum {
    STATUS_NA = -1,
    STATUS_OFFLINE,
    STATUS_CONNECTING,
    STATUS_ONLINE,
    STATUS_DISCONNECTING

} ACCOUNT_STATUS;


//Account code must implement the required protocol
@protocol AIAccount_Required
    // Init anything relating to the account
    - (void)initAccount;
    // Return a view controller for the connection window
    - (id <AIAccountViewController>)accountView;
    // Return a unique ID for this account type and username
    - (NSString *)accountID;
    // Return a readable description of this account's username
    - (NSString *)accountDescription;
@end

//Support for sending content to contacts
@protocol AIAccount_Content
    // Send a message object to its destination
    - (BOOL)sendContentObject:(id <AIContentObject>)object toHandle:(AIContactHandle *)inHandle;
@end

//Support for standard UID based contacts (ungrouped)
@protocol AIAccount_Contacts
    // Contact list is editable
    - (BOOL)contactListEditable;

    //Add an object
    - (BOOL)addObject:(AIContactObject *)object;
    // Remove an object
    - (BOOL)removeObject:(AIContactObject *)object;
    // Rename an object
    - (BOOL)renameObject:(AIContactObject *)object to:(NSString *)inName;
@end

//Support for UID based, grouped contacts
@protocol AIAccount_GroupedContacts
    // Contact list is editable
    - (BOOL)contactListEditable;

    // Add an object to the specified groups
    - (BOOL)addObject:(AIContactObject *)object toGroup:(AIContactGroup *)group;    
    // Remove an object from the specified groups
    - (BOOL)removeObject:(AIContactObject *)object fromGroup:(AIContactGroup *)group;
    // Rename an object
    - (BOOL)renameObject:(AIContactObject *)object inGroup:(AIContactGroup *)group to:(NSString *)inName;
    // Move an object
    - (BOOL)moveObject:(AIContactObject *)object fromGroup:(AIContactGroup *)sourceGroup toGroup:(AIContactGroup *)destGroup;

//If the service doesn't support groups within groups, group arrays can be compressed, or 'super'groups can be ignored
@end

//Support for the basic status of offline, online, connecting, and disconnecting
@protocol AIAccount_Status
    // Return the current connection status
    - (ACCOUNT_STATUS)status;
    
    - (void)connect;
    
    - (void)disconnect;
    
    //Services that are always connected (or not connection based) need not implement this protocol
@end

@protocol AIAccount_IdleTime

- (void)setIdleTime:(double)inSeconds manually:(BOOL)setManually;
- (BOOL)idleWasSetManually;
- (BOOL)isIdle;

@end

@interface AIAccount : NSObject <AIAccount_Required> {
    AIAdium			*owner;
    id <AIServiceController>	service;

    NSMutableDictionary		*propertiesDict;
    ACCOUNT_STATUS		status;
}

- (id)initWithProperties:(NSDictionary *)inProperties service:(id <AIServiceController>)inService owner:(id)inOwner;
- (NSMutableDictionary *)properties;
- (id <AIServiceController>)service;

@end
