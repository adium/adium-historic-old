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

/**
 * $Revision: 1.7 $
 * $Date: 2004/01/14 19:02:30 $
 * $Author: adamiser $
 **/

#define Account_ListChanged 					@"Account_ListChanged"
#define Account_HandlesChanged					@"Account_HandlesChanged"

@class AIServiceType, AIAdium, AIAccount, AIListObject;

@protocol AIServiceController <NSObject>
- (NSString *)identifier;
- (NSString *)description;
- (AIServiceType *)handleServiceType;
- (id)accountWithUID:(NSString *)inUID;
@end

@protocol AIAccountViewController <NSObject>
- (NSView *)view;
- (NSArray *)auxiliaryTabs;
- (void)configureViewAfterLoad;
@end

@interface AIAccountController : NSObject{
    IBOutlet	AIAdium		*owner;	
	
    NSMutableArray			*accountArray;			//Array of active accounts
    NSMutableDictionary		*availableServiceDict;
    NSMutableDictionary		*lastAccountIDToSendContent;
    NSMutableDictionary		*accountStatusDict;
	
    NSMutableArray			*sleepingOnlineAccounts;
    
    NSImage					*defaultUserIcon;
    NSString				*defaultUserIconFilename;
}

//Access to the account list
- (NSArray *)accountArray;
- (AIAccount *)accountWithID:(NSString *)inID;
- (AIAccount *)accountForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inObject;
- (int)numberOfAccountsAvailableForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inObject;

//Managing accounts
- (AIAccount *)newAccountAtIndex:(int)index;
- (void)deleteAccount:(AIAccount *)inAccount;
- (int)moveAccount:(AIAccount *)account toIndex:(int)destIndex;
- (AIAccount *)changeUIDOfAccount:(AIAccount *)inAccount to:(NSString *)inUID;
- (AIAccount *)switchAccount:(AIAccount *)inAccount toService:(id <AIServiceController>)inService;
- (void)connectAllAccounts;
- (void)disconnectAllAccounts;

//Account password storage
- (void)setPassword:(NSString *)inPassword forAccount:(AIAccount *)inAccount;
- (NSString *)passwordForAccount:(AIAccount *)inAccount;
- (void)passwordForAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget selector:(SEL)inSelector;
- (void)forgetPasswordForAccount:(AIAccount *)inAccount;

//Access to services
- (void)registerService:(id <AIServiceController>)inService;
- (id <AIServiceController>)serviceControllerWithIdentifier:(NSString *)inType;
- (NSDictionary *)availableServices;

//Private
- (void)initController;
- (void)closeController;
- (void)finishIniting;
- (void)disconnectAllAccounts;

@end
