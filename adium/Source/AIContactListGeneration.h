/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

@class AIAdium, AIHandle, AIAccount, AIListGroup, AIListContact;

@interface AIContactListGeneration : NSObject {
    AIAdium			*owner;

    AIListGroup 		*contactList;
    
    NSMutableDictionary		*groupDict;
    NSMutableDictionary		*abandonedContacts;
    NSMutableDictionary		*abandonedGroups;
    
}

- (id)initWithContactList:(AIListGroup *)inContactList owner:(id)inOwner;
- (void)handle:(AIHandle *)inHandle addedToAccount:(AIAccount *)inAccount;
- (void)handle:(AIHandle *)inHandle removedFromAccount:(AIAccount *)inAccount;
- (void)handlesChangedForAccount:(AIAccount *)inAccount;
- (void)saveGroupState;
- (AIListContact *)createContactWithUID:(NSString *)inUID serviceID:(NSString *)inServiceID;

@end
