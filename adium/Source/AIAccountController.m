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

// $Id: AIAccountController.m,v 1.38 2003/12/22 19:04:27 adamiser Exp $

#import "AIAccountController.h"
#import "AILoginController.h"
#import "AIPreferenceController.h"
#import "AIPasswordPromptController.h"

//Paths and Filenames
#define PREF_GROUP_PREFERRED_ACCOUNTS		@"Preferred Accounts"

//Preference keys
#define ACCOUNT_LIST				@"Account List"		//Array of accounts
#define ACCOUNT_TYPE				@"Type"			//Account type
#define ACCOUNT_SERVICE				@"Service"		//Account service
#define ACCOUNT_UID				@"UID"			//Account UID
//Other
#define KEY_PREFERRED_SOURCE_ACCOUNT		@"Preferred Account"
#define KEY_ACCOUNT_STATUS			@"Status"

#define DEFAULT_ICON_CACHE_PATH                 @"~/Library/Caches/Adium"

@interface AIAccountController (PRIVATE)
+ (NSBundle *)serviceBundleForAccountType:(NSString *)inType;
- (void)dealloc;
- (void)loadAccounts;
- (void)saveAccounts:(NSArray *)inAccounts;
- (AIAccount *)defaultAccount;
- (AIAccount *)accountOfType:(NSString *)inType withUID:(NSString *)inUID;
- (NSMutableArray *)loadServices;
- (void)accountListChanged;
- (void)buildAccountMenus;
- (void)autoConnectAccounts;
- (void)disconnectAllAccounts;
- (NSString *)_defaultIconCachePath;
- (void)insertAccount:(AIAccount *)inAccount atIndex:(int)index;
@end

@implementation AIAccountController

//init
- (void)initController
{
    availableServiceDict = [[NSMutableDictionary alloc] init];
    accountArray = nil;
    lastAccountIDToSendContent = [[NSMutableDictionary alloc] init];
    sleepingOnlineAccounts = nil;
    defaultUserIcon = nil;
    
    //Monitor sleep
    [[NSNotificationCenter defaultCenter] addObserver:self
					     selector:@selector(systemWillSleep:)
						 name:AISystemWillSleep_Notification
					       object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
					     selector:@selector(systemDidWake:)
						 name:AISystemDidWake_Notification
					       object:nil];
}

//
- (void)finishIniting
{
    //### TEMPORARY (OLD ACCOUNT PREFERENCE IMPORT CODE) #######
    NSArray     *oldAccountArray = [[[owner preferenceController] preferencesForGroup:@"Accounts"] objectForKey:ACCOUNT_LIST];
    if(oldAccountArray && [oldAccountArray count]){
	NSMutableArray     *importedAccounts = [NSMutableArray array];
	NSLog(@"Importing old accounts");
	
	NSEnumerator	*accountEnumerator = [oldAccountArray objectEnumerator];
	NSDictionary	*accountDict;
	
	while(accountDict = [accountEnumerator nextObject]){
	    NSDictionary	*propertyDict = [accountDict objectForKey:@"Properties"];
	    NSString		*serviceType = [accountDict objectForKey:@"Type"];
	    NSString		*accountUID = [[propertyDict objectForKey:@"Handle"] compactedString];
	    AIAccount		*tempAccount;
	    NSEnumerator	*propertyEnumerator;
	    NSString		*key;
	    
	    NSLog(@"  Importing %@ account '%@' ", serviceType, accountUID);
	    
	    tempAccount = [self accountOfType:serviceType withUID:accountUID];
	    propertyEnumerator = [[propertyDict allKeys] objectEnumerator];
	    while(key = [propertyEnumerator nextObject]){
		NSLog(@"    - %@",key);
		[tempAccount setPreference:[propertyDict objectForKey:key] forKey:key group:GROUP_ACCOUNT_STATUS];
	    }
	    
	    [importedAccounts addObject:tempAccount];
	}
	
	[self saveAccounts:importedAccounts];
	[[owner preferenceController] setPreference:nil forKey:@"Accounts" group:ACCOUNT_LIST];
    }
    //#########################################################
    
    //Load the user accounts
    [self loadAccounts];
    [self accountListChanged];
    
    //Observe content (for accountForSendingContentToHandle)
    [[owner notificationCenter] addObserver:self
				   selector:@selector(didSendContent:)
				       name:Content_DidSendContent
				     object:nil];
    
    //Autoconnect
    [self autoConnectAccounts];
}

//close
- (void)closeController
{
    //Disconnect all accounts
    [self disconnectAllAccounts];
    
    //Remove observers (otherwise, every account added will be a duplicate next time around)
    [[owner notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Release storage
    [accountArray release];
    [availableServiceDict release];
    [lastAccountIDToSendContent release];
    [defaultUserIcon release];
}

//Call after making changes to the account list
- (void)accountListChanged
{
    //Save the changes
    [self saveAccounts:accountArray];
    
    //Broadcast an account list changed message
    [[owner notificationCenter] postNotificationName:Account_ListChanged object:nil userInfo:nil];
}

//Loads the saved accounts
- (void)loadAccounts
{
    NSArray		*savedAccountArray;
    int			loop;
    NSMutableArray	*tempArray = [NSMutableArray array];
    
    //Create an instance of every saved account
    savedAccountArray = [[owner preferenceController] preferenceForKey:ACCOUNT_LIST group:PREF_GROUP_ACCOUNTS];
    for(loop = 0;loop < [savedAccountArray count];loop++){
        NSDictionary	*serviceDict;
        NSString	*accountUID;
        NSString	*serviceType;
        AIAccount	*newAccount;
	
        //Fetch the service
        serviceDict = [savedAccountArray objectAtIndex:loop];
	
        //Get the accounts information
        serviceType = [serviceDict objectForKey:ACCOUNT_TYPE];		//Unique plugin ID
        accountUID = [serviceDict objectForKey:ACCOUNT_UID];
	
        //Create the connection and add it to our array
	if(serviceType && accountUID){
	    newAccount = [self accountOfType:serviceType withUID:accountUID];
	    if(newAccount){
		[tempArray addObject:newAccount];
	    }
	}
    }
    
    if(accountArray) [accountArray release];
    accountArray = [tempArray retain];
}

//Saves our accounts
- (void)saveAccounts:(NSArray *)inAccounts
{
    if(inAccounts){
	NSMutableArray	*accountDictArray = [[NSMutableArray alloc] init];
	NSString	*userDirectory;
	int		loop;
	
	//Get the user preference directory
	userDirectory = [[owner loginController] userDirectory];
	
	//Create a dictionary for every open connection
	for(loop = 0;loop < [inAccounts count];loop++){
	    NSMutableDictionary	*accountDict = [[NSMutableDictionary alloc] init];
	    AIAccount		*account = [inAccounts objectAtIndex:loop];

	    [accountDict setObject:[[account service] identifier] forKey:ACCOUNT_TYPE]; //Unique plugin ID
	    [accountDict setObject:[account serviceID] forKey:ACCOUNT_SERVICE];	    //Shared service ID
	    [accountDict setObject:[account UID] forKey:ACCOUNT_UID];		    //Account UID
	    [accountDictArray addObject:accountDict];
	    
	    [accountDict release];
	}
	
	//save
	[[owner preferenceController] setPreference:accountDictArray forKey:ACCOUNT_LIST group:PREF_GROUP_ACCOUNTS];
	[accountDictArray release];
    }
}

//Returns a default account
- (AIAccount *)defaultAccount
{
    return([self accountOfType:@"AIM (TOC2)" withUID:@""]);
}

//Returns a new account of the specified type (Unique service plugin ID)
- (AIAccount *)accountOfType:(NSString *)inType withUID:(NSString *)inUID
{
    id <AIServiceController>    serviceController;
    
    NSParameterAssert(inType != nil); NSParameterAssert([inType length] != 0);
    NSParameterAssert(inUID != nil);
    
    //Load the account
    if(serviceController = [self serviceControllerWithIdentifier:inType]){
	return([serviceController accountWithUID:inUID]);
    }else{
	return(nil);
    }
}

//Insert an account
- (void)insertAccount:(AIAccount *)inAccount atIndex:(int)index
{    
    NSParameterAssert(inAccount != nil);
    NSParameterAssert(accountArray != nil);
    NSParameterAssert(index >= 0 && index <= [accountArray count]);
    
    //Insert the account
    [accountArray insertObject:inAccount atIndex:index];
    [self accountListChanged];
}



//Services -------------------------------------------------------------------------------------------------------
//Return the available services
- (NSDictionary *)availableServices
{
    return(availableServiceDict);
}

//Returns the specified service controller
- (id <AIServiceController>)serviceControllerWithIdentifier:(NSString *)inType
{
    return([availableServiceDict objectForKey:inType]);
}

//Register service code
- (void)registerService:(id <AIServiceController>)inService
{
    [availableServiceDict setObject:inService forKey:[inService identifier]];
}


//Accounts -------------------------------------------------------------------------------------------------------
//Returns all available accounts
- (NSArray *)accountArray
{
    return(accountArray);
}

//Searches the account list for the specified account
- (AIAccount *)accountWithID:(NSString *)inID
{
    NSEnumerator	*enumerator;
    AIAccount		*account;
    
    enumerator = [accountArray objectEnumerator];
    while((account = [enumerator nextObject])){
        if([inID compare:[account UIDAndServiceID]] == 0){
            return(account);
        }
    }
    
    return(nil);
}

//Returns the number of accounts available to send the content
- (int)numberOfAccountsAvailableForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inObject
{
    NSEnumerator	*enumerator;
    AIAccount		*account;
    
    int number = 0;
    
    //Accounts that can see the object
    enumerator = [accountArray objectEnumerator];
    while((account = [enumerator nextObject])){
        if([(AIAccount<AIAccount_Content> *)account availableForSendingContentType:inType toListObject:inObject]){
            number++;
        }            
    }  
    
    return number;
}


//Account Editing -------------------------------------------------------------------------------------------------------
//Create a new default account
- (AIAccount *)newAccountAtIndex:(int)index
{
    NSParameterAssert(accountArray != nil);
    NSParameterAssert(index >= 0 && index <= [accountArray count]);

    AIAccount	*newAccount = [self defaultAccount];
    
    [self insertAccount:newAccount atIndex:index];
    
    return(newAccount);
}

//Delete an existing account
- (void)deleteAccount:(AIAccount *)inAccount
{
    NSParameterAssert(inAccount != nil);
    NSParameterAssert(accountArray != nil);
    NSParameterAssert([accountArray indexOfObject:inAccount] != NSNotFound);
    
    [inAccount retain]; //Don't let the account dealloc until we have a chance to notify everyone that it's gone
    [accountArray removeObject:inAccount];
    [self accountListChanged];
    [inAccount release];
}

//Change the UID of an existing account
- (AIAccount *)changeUIDOfAccount:(AIAccount *)inAccount to:(NSString *)inUID
{
    AIAccount   *newAccount;
    NSString    *serviceIdentifier = [[[[inAccount service] identifier] copy] autorelease]; //Deleting the account will release the serviceID
    int		index = [accountArray indexOfObject:inAccount];
    
    //Delete the existing account
    [self deleteAccount:inAccount];
    
    //Add an account with the new UID
    newAccount = [self accountOfType:serviceIdentifier withUID:inUID];
    [self insertAccount:newAccount atIndex:index];
    
    return(newAccount);
}

//Switches the service of the specified account
- (AIAccount *)switchAccount:(AIAccount *)inAccount toService:(id <AIServiceController>)inService
{
    AIAccount	*newAccount;
    NSString    *accountUID = [[[inAccount UID] copy] autorelease]; //Deleting the account will release the UID
    int		index = [accountArray indexOfObject:inAccount];

    //Delete the existing account
    [self deleteAccount:inAccount];
    
    //Add an account with the new UID
    newAccount = [self accountOfType:[inService identifier] withUID:accountUID];
    [self insertAccount:newAccount atIndex:index];
    
    return(newAccount);
}

//Re-orders an account on the list
- (int)moveAccount:(AIAccount *)account toIndex:(int)destIndex
{
    int sourceIndex = [accountArray indexOfObject:account];
    
    //Remove the account
    [account retain];
    [accountArray removeObject:account];
    
    //Re-insert the account
    if(destIndex > sourceIndex){
        destIndex -= 1;
    }
    
    [accountArray insertObject:account atIndex:destIndex];
    [account release];
    
    [self accountListChanged];
    
    return(destIndex);
}


//User Icons -------------------------------------------------------------------------------------------------------
//User icon methods
//- (void)setUserIcon:(NSImage *)inImage forAccount:(AIAccount *)account
//{
//#warning ** Doing icons with custom code, we should try to do them with the regular code **
///*    if([[account supportedPropertyKeys] containsObject:@"UserIcon"]){
//        [account statusForKey:@"UserIcon" willChangeTo:inImage];
//    }*/
//}

//- (void)setDefaultUserIcon:(NSImage *)inImage
//{
///*    //keep track of the image
//    [defaultUserIcon release]; defaultUserIcon = nil;
//    defaultUserIcon = [inImage retain];
//    
//    //cache the image to a file
//    if (defaultUserIcon) {
//        [defaultUserIconFilename release];
//        defaultUserIconFilename = [[self _defaultIconCachePath] retain];
//        NSData      *iconData = [defaultUserIcon JPEGRepresentation];
//        
//        [iconData writeToFile:defaultUserIconFilename atomically:YES];
//    } else {
//        defaultUserIconFilename = nil;       
//    }
//    
//    NSEnumerator	*enumerator;
//    AIAccount           *account;
//    
//    //Notify all accounts that support DefaultBuddyImage so they can inform their servers
//    enumerator = [accountArray objectEnumerator];
//    while((account = [enumerator nextObject])){
//        //Tell concerned accounts about the NSImage
//        if([[account supportedPropertyKeys] containsObject:@"DefaultUserIcon"]){
//            [account statusForKey:@"DefaultUserIcon" willChangeTo:defaultUserIcon];
//        }
//        //Tell concerned accounts about the filename
//        if([[account supportedPropertyKeys] containsObject:@"DefaultUserIconFilename"]){
//            [account statusForKey:@"DefaultUserIconFilename" willChangeTo:defaultUserIconFilename];
//        }
//    }*/
//}
//- (NSImage *)defaultUserIcon
//{
//    return defaultUserIcon;   
//}
//- (NSString *)defaultUserIconFilename
//{
//    return defaultUserIconFilename;
//}
//- (NSString *)_defaultIconCachePath
//{
//    return([[DEFAULT_ICON_CACHE_PATH stringByAppendingPathComponent:@"UserIcon_Default"] stringByExpandingTildeInPath]);
//}


//Preferred source account memory --------------------------------------------------------------------------------------
//Returns the desired source account for messaging the specified contact.  The account is the first one found online
//following the chain:
//- The last account used to message this contact
//- The last account used to message anyone
//- The first available account on the account list
- (AIAccount *)accountForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inObject
{
    NSEnumerator	*enumerator;
    AIAccount		*account;
    
    // Preferred account for this contact --
    // The preferred account always has priority, as long as it is available for sending content
    if(inObject){
        NSString    *accountID = [inObject preferenceForKey:KEY_PREFERRED_SOURCE_ACCOUNT group:PREF_GROUP_PREFERRED_ACCOUNTS];
	
        if(accountID && (account = [self accountWithID:accountID])){
            if([(AIAccount<AIAccount_Content> *)account availableForSendingContentType:inType toListObject:nil]){
                return(account);
            }
        }
    }
    
    // Last account used to message anyone --
    // Next, the last account used to message someone is picked, as long as it is available for sending content
    NSString	*lastAccountID = [lastAccountIDToSendContent objectForKey:[inObject serviceID]];
    if(lastAccountID && (account = [self accountWithID:lastAccountID])){
        if([(AIAccount<AIAccount_Content> *)account availableForSendingContentType:inType toListObject:nil]){
            return(account);
        }
    }
    
    // First available account that can see the object
    // If this is the first message opened in this session, the first account with the contact on it's contact list is
    // choosen
    {
        enumerator = [accountArray objectEnumerator];
        while((account = [enumerator nextObject])){
            if([(AIAccount<AIAccount_Content> *)account availableForSendingContentType:inType toListObject:inObject]){
                return(account);
            }
        }        
    }
    
    // If the handle does not exist on any contact lists, the first account available for sending content is used
    // First available account that can see the handle --
    enumerator = [accountArray objectEnumerator];
    while((account = [enumerator nextObject])){
        AIHandle	*handle = [(AIListContact *)inObject handleForAccount:account];
	
        if((!handle || [[handle serviceID] compare:[[[account service] handleServiceType] identifier]] == 0) &&
           [(AIAccount<AIAccount_Content> *)account availableForSendingContentType:inType toListObject:nil]){
            return(account);
        }
    }
    
    // Nothing found (no accounts are available to send)
    // If no accounts are available, the first one is returned
    return([accountArray objectAtIndex:0]);
}

//Watch outgoing content, remembering the user's choice of source account
- (void)didSendContent:(NSNotification *)notification
{
    AIChat		*chat = [notification object];
    AIListObject	*destObject = [chat listObject];
    
    if(chat && destObject){
        AIContentObject		*contentObject = [[notification userInfo] objectForKey:@"Object"];
        AIAccount		*sourceAccount = (AIAccount *)[contentObject source];
	
        [destObject setPreference:[sourceAccount UIDAndServiceID]
			   forKey:KEY_PREFERRED_SOURCE_ACCOUNT
			    group:PREF_GROUP_PREFERRED_ACCOUNTS];
	
        [lastAccountIDToSendContent setObject:[sourceAccount UIDAndServiceID] forKey:[destObject serviceID]];
    }
}


//Connection convenience methods ---------------------------------------------------------------------------------------
//Automatically connect to accounts flagged with an auto connect property
- (void)autoConnectAccounts
{
    NSEnumerator	*enumerator;
    AIAccount		*account;
    
    enumerator = [accountArray objectEnumerator];
    while((account = [enumerator nextObject])){
        if([[account supportedPropertyKeys] containsObject:@"Online"] &&
	   [[account preferenceForKey:@"AutoConnect" group:GROUP_ACCOUNT_STATUS] boolValue]){
            [account setPreference:[NSNumber numberWithBool:YES] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
        }
    }
}

//Connects all the accounts
- (void)connectAllAccounts
{
    NSEnumerator		*enumerator;
    AIAccount			*account;
    
    enumerator = [accountArray objectEnumerator];
    while((account = [enumerator nextObject])){
        if([[account supportedPropertyKeys] containsObject:@"Online"]){
            [account setPreference:[NSNumber numberWithBool:YES] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
        }
    }
}

//Disconnects all the accounts
- (void)disconnectAllAccounts
{
    NSEnumerator		*enumerator;
    AIAccount			*account;
    
    enumerator = [accountArray objectEnumerator];
    while((account = [enumerator nextObject])){
        if([[account supportedPropertyKeys] containsObject:@"Online"]){
            [account setPreference:[NSNumber numberWithBool:NO] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
        }
    }
}


//Disconnect / Reconnect on sleep --------------------------------------------------------------------------------------
//System is sleeping
- (void)systemWillSleep:(NSNotification *)notification
{
    NSEnumerator	*enumerator;
    AIAccount		*account;
    
    //Remove any existing online account array
    [sleepingOnlineAccounts release]; sleepingOnlineAccounts = [[NSMutableArray alloc] init];
    
    //Process each account, looking for any that are online
    enumerator = [accountArray objectEnumerator];
    while((account = [enumerator nextObject])){
        if([[account supportedPropertyKeys] containsObject:@"Online"] &&
	   [[account preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue]){
            //Remember that this account was online
            [sleepingOnlineAccounts addObject:account];
            
            //Disconnect it
            [account setPreference:[NSNumber numberWithBool:NO] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
        }
    }
}

//System is waking
- (void)systemDidWake:(NSNotification *)notification
{
    NSEnumerator	*enumerator;
    AIAccount		*account;
    
    //Reconnect all sleeping online accounts
    enumerator = [sleepingOnlineAccounts objectEnumerator];
    while((account = [enumerator nextObject])){
        //Connect it
        [account setPreference:[NSNumber numberWithBool:YES] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
    }
    
    //Cleanup
    [sleepingOnlineAccounts release]; sleepingOnlineAccounts = nil;
}


//Password Storage -----------------------------------------------------------------------------------------------------
//Save an account password
- (void)setPassword:(NSString *)inPassword forAccount:(AIAccount *)inAccount
{
    if(inPassword){
        [AIKeychain putPasswordInKeychainForService:[NSString stringWithFormat:@"Adium.%@",[inAccount UIDAndServiceID]]
					    account:[inAccount UIDAndServiceID] password:inPassword];
    }
}

//Fetches a saved account password (returns nil if no password is saved)
- (NSString *)passwordForAccount:(AIAccount *)inAccount
{
    NSString	*password = [AIKeychain getPasswordFromKeychainForService:[NSString stringWithFormat:@"Adium.%@",[inAccount UIDAndServiceID]]
								  account:[inAccount UIDAndServiceID]];
    
    return(password);
}

//Fetches a saved account password (Prompts the user to enter if no password is saved)
- (void)passwordForAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget selector:(SEL)inSelector
{
    NSString	*password;
    
    //check the keychain for this password
    password = [AIKeychain getPasswordFromKeychainForService:[NSString stringWithFormat:@"Adium.%@",[inAccount UIDAndServiceID]]
						     account:[inAccount UIDAndServiceID]];
    
    if(password && [password length] != 0){
        //Invoke the target right away
        [inTarget performSelector:inSelector withObject:password afterDelay:0.0001];    
    }else{
        //Prompt the user for their password
        [AIPasswordPromptController showPasswordPromptForAccount:inAccount notifyingTarget:inTarget selector:inSelector];
    }
}

//Forget a saved password
- (void)forgetPasswordForAccount:(AIAccount *)inAccount
{
    [AIKeychain removePasswordFromKeychainForService:[NSString stringWithFormat:@"Adium.%@",[inAccount UIDAndServiceID]]
					     account:[inAccount UIDAndServiceID]];
}


@end

