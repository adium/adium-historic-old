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

#import <Foundation/Foundation.h>

@class AIListContact, AIAccount, AIMutableOwnerArray;
@protocol AIContentObject;

@interface AIHandle : NSObject {
    NSString		*UID;
    NSString		*serviceID;
    NSString		*UIDAndServiceID;
    NSString		*serverGroup;
    AIAccount		*account;
    float		index;
    BOOL		temporary;

    AIListContact	*containingContact;

    NSMutableDictionary	*statusDictionary;
}

//Init
+ (id)handleWithServiceID:(NSString *)inServiceID UID:(NSString *)inUID serverGroup:(NSString *)inGroup temporary:(BOOL)inTemporary forAccount:(AIAccount *)inAccount;
- (id)initWithServiceID:(NSString *)inServiceID UID:(NSString *)inUID serverGroup:(NSString *)inGroup temporary:(BOOL)inTemporary forAccount:(AIAccount *)inAccount;

//Identifying information
- (NSString *)UID;
- (NSString *)serviceID;
- (NSString *)UIDAndServiceID;
- (NSString *)serverGroup;
- (void)setServerGroup:(NSString *)inServerGroup;
- (BOOL)temporary;

//Ownership
- (AIAccount *)account;
- (void)setContainingContact:(AIListContact *)inContact;
- (AIListContact *)containingContact;

//Status
- (NSMutableDictionary *)statusDictionary;

@end
