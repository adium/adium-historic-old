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

/*!
 * @class AIHandle
 * A unique handle to talk to on any IM protocol
 */
@interface AIHandle : NSObject {
    NSString		*UID;
    NSString		*serviceID;
    NSString		*UIDAndServiceID;
    NSString		*serverGroup;
    AIAccount		*account;
    //float		index;
    BOOL		temporary;

    AIListContact	*containingContact;

    NSMutableDictionary	*statusDictionary;
}

//Init
+ (id)handleWithServiceID:(NSString *)inServiceID UID:(NSString *)inUID serverGroup:(NSString *)inGroup temporary:(BOOL)inTemporary forAccount:(AIAccount *)inAccount;
- (id)initWithServiceID:(NSString *)inServiceID UID:(NSString *)inUID serverGroup:(NSString *)inGroup temporary:(BOOL)inTemporary forAccount:(AIAccount *)inAccount;

//Identifying information

/*!
 * @method UID
 * Returns the service-specific unique ID of this handle
 */
- (NSString *)UID;

/*!
 * @method serviceID
 * Returns the identifier of this service
 */
- (NSString *)serviceID;

/*!
 * @method UIDAndServiceID
 * Returns serviceID.UID, which together unique identify the handle.
 */
- (NSString *)UIDAndServiceID;

- (NSString *)serverGroup;
- (void)setServerGroup:(NSString *)inServerGroup;
- (BOOL)temporary;

//Ownership
- (AIAccount *)account;
- (void)setContainingContact:(AIListContact *)inContact;
- (AIListContact *)containingContact;

/*!
 * @method statusDictionary
 * These two properties are always applicable:
 *
 * Online          boolean
 * Display Name    NSString
 * BuddyImage      NSImage
 *
 * And these are applicable only when Online is true:
 *
 * Signon Date     NSDate
 * IdleSince       NSDate
 * StatusMessage   NSAttributedString
 * Typing          boolean
 * Away            boolean
 * Client          NSString
 * TextProfile     NSAttributedString
 */
- (NSMutableDictionary *)statusDictionary;

@end
