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

/**
 * $Revision: 1.26 $
 * $Date: 2004/07/15 18:29:27 $
 * $Author: evands $
 **/

#define Account_ListChanged 					@"Account_ListChanged"
#define Account_HandlesChanged					@"Account_HandlesChanged"

//Connecting is faded by 40%
#define CONNECTING_MENU_IMAGE_FRACTION  0.60

//Offline is faded by 70%
#define OFFLINE_MENU_IMAGE_FRACTION		0.30

@class AIServiceType, AIAdium, AIAccount, AIListObject;

@protocol AIServiceController <NSObject>
- (NSString *)identifier;
- (NSString *)description;
- (AIServiceType *)handleServiceType;
- (id)accountWithUID:(NSString *)inUID objectID:(int)inObjectID;
- (AIAccountViewController *)accountView;	//Return a view controller for the connection window
@end

@protocol AccountMenuPlugin <NSObject>
- (NSString *)identifier;
- (void)addAccountMenuItems:(NSArray *)menuItemArray;
- (void)removeAccountMenuItems:(NSArray *)menuItemArray;
@end

@interface AIAccountController : NSObject<AIListObjectObserver>{
    IBOutlet	AIAdium		*owner;	
	
    NSMutableArray			*accountArray;				//Array of active accounts
    NSMutableDictionary		*availableServiceDict;		//Array of available services
    NSMutableDictionary		*lastAccountIDToSendContent;//Last account to send content
    NSMutableDictionary		*accountStatusDict;			//Account status
	
    NSMutableArray			*sleepingOnlineAccounts;	//Accounts that were connected before we slept
	NSMutableArray			*unloadableAccounts;
	
	NSMutableArray			*accountMenuPluginsArray;
	NSMutableDictionary		*accountMenuItemArraysDict;
	
	NSArray					*_cachedActiveServiceTypes;
}

//Services
- (NSArray *)availableServices;
- (NSArray *)activeServiceTypes;
- (id <AIServiceController>)serviceControllerWithIdentifier:(NSString *)inType;
- (void)registerService:(id <AIServiceController>)inService;
- (NSMenu *)menuOfServicesWithTarget:(id)target;

//Accounts
- (NSArray *)accountArray;
- (AIAccount *)accountWithObjectID:(NSString *)inID;
- (NSArray *)accountsWithServiceID:(NSString *)serviceID;
- (AIAccount *)defaultAccount;
- (AIAccount *)createAccountOfType:(NSString *)inType withUID:(NSString *)inUID objectID:(int)inObjectID;

//Account Editing
- (AIAccount *)newAccountAtIndex:(int)index;
- (void)insertAccount:(AIAccount *)inAccount atIndex:(int)index save:(BOOL)shouldSave;
- (void)deleteAccount:(AIAccount *)inAccount save:(BOOL)shouldSave;
- (AIAccount *)switchAccount:(AIAccount *)inAccount toService:(id <AIServiceController>)inService;
- (AIAccount *)changeUIDOfAccount:(AIAccount *)inAccount to:(NSString *)inUID;
- (int)moveAccount:(AIAccount *)account toIndex:(int)destIndex;

//AccountMenuPlugin
- (void)registerAccountMenuPlugin:(id<AccountMenuPlugin>)accountMenuPlugin;
- (void)unregisterAccountMenuPlugin:(id<AccountMenuPlugin>)accountMenuPlugin;

//Preferred Source Accounts 
- (AIAccount *)preferredAccountForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inObject;
- (NSMenu *)menuOfAccountsWithTarget:(id)target;
- (NSArray *)menuItemsForAccountsWithTarget:(id)target;
- (NSMenu *)menuOfAccountsForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inObject withTarget:(id)target includeOffline:(BOOL)includeOffline;

//Connection convenience methods
- (void)autoConnectAccounts;
- (void)connectAllAccounts;
- (void)disconnectAllAccounts;

//Password Storage
- (void)setPassword:(NSString *)inPassword forAccount:(AIAccount *)inAccount;
- (NSString *)passwordForAccount:(AIAccount *)inAccount;
- (void)passwordForAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget selector:(SEL)inSelector;
- (void)forgetPasswordForAccount:(AIAccount *)inAccount;

- (void)setPassword:(NSString *)inPassword forProxyServer:(NSString *)server userName:(NSString *)userName;
- (NSString *)passwordForProxyServer:(NSString *)server userName:(NSString *)userName;
- (void)passwordForProxyServer:(NSString *)server userName:(NSString *)userName notifyingTarget:(id)inTarget selector:(SEL)inSelector;

//Private
- (void)initController;
- (void)closeController;
- (void)finishIniting;

@end
