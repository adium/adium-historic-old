/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import <acid.h>

@class AIGroup;

@interface JabberAccount : AIAccount <AIAccount_Content, AIAccount_Handles, JabberRosterDelegate>
{
    JabberID *myID;
    NSString *myPassword;
    NSMutableDictionary *handleDict;
    NSMutableDictionary *chatDict;
    JabberSession *session;
    JabberGroupTracker *groupTracker;
    NSTimer *initialTimer;
    bool silentAndDelayed;
}

//AIAccount_Content
// Send a message object to its destination
- (BOOL)sendContentObject:(AIContentObject *)object;
// Returns YES if the contact is available for receiving content of the specified type
- (BOOL)availableForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inListObject;

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

/*AIAccount_Groups
// Add a group to this account
- (BOOL)addGroup:(NSString *)inGroup;
// Remove a group from this account
- (BOOL)removeGroup:(NSString *)inGroup;*/

- (void)displayError:(NSString *)errorDesc;

- (void)startupEnded;

//AIAccount subclassed methods
- (void)initAccount; 				//Init anything relating to the account
- (id <AIAccountViewController>)accountView;	//Return a view controller for the connection window

- (NSString *)accountID; 		//Specific to THIS account plugin, and the user's account name
- (NSString *)UID;			//The user's account name
- (NSString *)serviceID;		//The service ID (shared by any account code accessing this service)
- (NSString *)accountDescription;	//Return a readable description of this account's username

- (void)statusForKey:(NSString *)key willChangeTo:(id)inValue;	//The account's status should change

@end
