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

#import "AIAccountController.h"
#import "AILoginController.h"
#import "AIPreferenceController.h"
#import "AIPasswordPromptController.h"


//Paths and Filenames
#define PREF_GROUP_PREFERRED_ACCOUNTS		@"Preferred Accounts"
#define PREF_GROUP_ACCOUNT_STATUS		@"Account Status"

//#define DIRECTORY_INTERNAL_SERVICES		@"/Contents/Plugins"	//Path to the internal services
//Preference keys
#define ACCOUNT_LIST				@"Account List"		//Array of accounts
#define ACCOUNT_TYPE				@"Type"			//Account type
#define ACCOUNT_PROPERTIES			@"Properties"		//Account properties
//Other
#define KEY_PREFERRED_SOURCE_ACCOUNT		@"Preferred Account"
#define KEY_ACCOUNT_STATUS			@"Status"
//#define EXTENSION_ADIUM_SERVICE			@"AdiumService"		//File extension on a service

#define DEFAULT_ICON_CACHE_PATH                 @"~/Library/Caches/Adium"

@interface AIAccountController (PRIVATE)
+ (NSBundle *)serviceBundleForAccountType:(NSString *)inType;
- (void)dealloc;
- (void)loadAccounts;
- (void)saveAccounts:(NSArray *)inAccounts;
- (AIAccount *)defaultAccount;
- (AIAccount *)accountOfType:(NSString *)inType withProperties:(NSDictionary *)inProperties;
- (NSMutableArray *)loadServices;
- (void)accountListChanged;
- (void)buildAccountMenus;
- (void)autoConnectAccounts;
- (void)disconnectAllAccounts;
- (NSString *)_defaultIconCachePath;
@end

@implementation AIAccountController

// init
- (void)initController
{
    availableServiceArray = [[NSMutableArray alloc] init];
    accountArray = nil;
    lastAccountIDToSendContent = [[NSMutableDictionary alloc] init];
    sleepingOnlineAccounts = nil;
    defaultUserIcon = nil;
    
    //Register our default preferences
    accountStatusDict = [[[[owner preferenceController] preferencesForGroup:PREF_GROUP_ACCOUNT_STATUS] objectForKey:KEY_ACCOUNT_STATUS] mutableCopy];
    if(!accountStatusDict) accountStatusDict = [[NSMutableDictionary alloc] init];

    //Monitor sleep
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(systemWillSleep:) name:AISystemWillSleep_Notification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(systemDidWake:) name:AISystemDidWake_Notification object:nil];
    
}

//
- (void)systemWillSleep:(NSNotification *)notification
{
    NSEnumerator	*enumerator;
    AIAccount		*account;

    //Remove any existing online account array
    [sleepingOnlineAccounts release]; sleepingOnlineAccounts = [[NSMutableArray alloc] init];

    //Process each account, looking for any that are online
    enumerator = [accountArray objectEnumerator];
    while((account = [enumerator nextObject])){
        if([[account supportedPropertyKeys] containsObject:@"Online"] && [[account propertyForKey:@"Online"] boolValue]){
            //Remember that this account was online
            [sleepingOnlineAccounts addObject:account];
            
            //Disconnect it
            [self setProperty:[NSNumber numberWithBool:NO] forKey:@"Online" account:account];
        }
    }
}

//
- (void)systemDidWake:(NSNotification *)notification
{
    NSEnumerator	*enumerator;
    AIAccount		*account;
    
    //Reconnect all sleeping online accounts
    enumerator = [sleepingOnlineAccounts objectEnumerator];
    while((account = [enumerator nextObject])){
        //Connect it
        [self setProperty:[NSNumber numberWithBool:YES] forKey:@"Online" account:account];
    }

    //Cleanup
    [sleepingOnlineAccounts release]; sleepingOnlineAccounts = nil;
}

// close
- (void)closeController
{
    //Save the current account status dict
    [[owner preferenceController] setPreference:accountStatusDict forKey:KEY_ACCOUNT_STATUS group:PREF_GROUP_ACCOUNT_STATUS];

    //The account list is saved as changes are made, so there is no need to save it on close        

    [self disconnectAllAccounts]; //Disconnect all accounts
    
    //Remove observers (otherwise, every account added will be a duplicate next time around)
    [[owner notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Release storage
    [accountArray release];
    [availableServiceArray release];
    [lastAccountIDToSendContent release];
    [accountStatusDict release];
    [defaultUserIcon release];
}

// dealloc
- (void)dealloc
{
    /*[accountArray release];
    [availableServiceArray release];
    [lastAccountIDToSendContent release];
    [accountStatusDict release];*/

    [super dealloc];
}

- (void)finishIniting
{
    //Load the user accounts
    [self loadAccounts];
    [self accountListChanged];

    //Observe content (for accountForSendingContentToHandle)
    [[owner notificationCenter] addObserver:self selector:@selector(didSendContent:) name:Content_DidSendContent object:nil];
    
    //Autoconnect
    [self autoConnectAccounts];
}

// Create a new account
- (AIAccount *)newAccountAtIndex:(int)index
{
    AIAccount	*outAccount;

    NSParameterAssert(accountArray != nil);
    NSParameterAssert(index >= 0 && index <= [accountArray count]);

    //Create a default account
    outAccount = [self defaultAccount];
    [accountArray insertObject:outAccount atIndex:index];

    [self accountListChanged];
    
    return(outAccount);
}

// Delete an existing account
- (void)deleteAccount:(AIAccount *)inAccount
{
    NSParameterAssert(inAccount != nil);
    NSParameterAssert(accountArray != nil);
    NSParameterAssert([accountArray indexOfObject:inAccount] != NSNotFound);

    [inAccount retain];
    
    //Delete the account
    [accountArray removeObject:inAccount];

    [self accountListChanged];
    
    [inAccount release];
}

// Returns the account array
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
        if([inID compare:[account accountID]] == 0){
            return(account);
        }
    }

    return(nil);
}

//Switches the service of the specified account
- (AIAccount *)switchAccount:(AIAccount *)inAccount toService:(id <AIServiceController>)inService
{
    AIAccount	*newAccount;

    //Change the service type
    [self setProperty:[inService identifier] forKey:ACCOUNT_TYPE account:inAccount];
    
    //Open the account again
    newAccount = [self accountOfType:[inService identifier] withProperties:[inAccount properties]];
    [accountArray replaceObjectAtIndex:[accountArray indexOfObject:inAccount] withObject:newAccount];
    
    [self accountListChanged];

    return(newAccount);
}

// Re-orders an account on the list
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

//Save an account password
- (void)setPassword:(NSString *)inPassword forAccount:(AIAccount *)inAccount
{
    if(inPassword){
        [AIKeychain putPasswordInKeychainForService:[NSString stringWithFormat:@"Adium.%@",[inAccount UIDAndServiceID]] account:[inAccount UIDAndServiceID] password:inPassword];
    }
}

//Fetches a saved account password (returns nil if no password is saved)
- (NSString *)passwordForAccount:(AIAccount *)inAccount
{
    NSString	*password = [AIKeychain getPasswordFromKeychainForService:[NSString stringWithFormat:@"Adium.%@",[inAccount UIDAndServiceID]] account:[inAccount UIDAndServiceID]];

    return(password);
}

//Fetches a saved account password (Prompts the user to enter if no password is saved)
- (void)passwordForAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget selector:(SEL)inSelector
{
    NSString	*password;

    //check the keychain for this password
    password = [AIKeychain getPasswordFromKeychainForService:[NSString stringWithFormat:@"Adium.%@",[inAccount UIDAndServiceID]] account:[inAccount UIDAndServiceID]];
    
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
    [AIKeychain removePasswordFromKeychainForService:[NSString stringWithFormat:@"Adium.%@",[inAccount UIDAndServiceID]] account:[inAccount UIDAndServiceID]];
}

//Return the available services
- (NSArray *)availableServiceArray
{
    return(availableServiceArray);
}

/*- (AIServiceType *)serviceTypeWithID:(NSString *)inServiceID
{
    NSEnumerator		*enumerator;
    id <AIServiceController>	service;

    enumerator = [availableServiceArray objectEnumerator];
    while((service = [enumerator nextObject])){
        AIServiceType	*serviceType = [service handleServiceType];
        
        if([[serviceType identifier] compare:inServiceID] == 0){
            return(serviceType);
        }
    }

    return(nil);
}*/

//Register service code
- (void)registerService:(id <AIServiceController>)inService
{
    [availableServiceArray addObject:inService];
}

//Returns the desired source account for messaging the specified contact.  The account is the first one found online following the chain:
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
        NSString	*accountID = [[owner preferenceController] preferenceForKey:KEY_PREFERRED_SOURCE_ACCOUNT
                                                                       group:PREF_GROUP_PREFERRED_ACCOUNTS
                                                                      object:inObject];

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
    // If this is the first message opened in this session, the first account with the contact on it's contact list is choosen
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

- (int)numberOfAccountsAvailableForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inObject
{
    NSEnumerator	*enumerator;
    AIAccount		*account;
    
    int number = 0;
    
    // Accounts that can see the object
    enumerator = [accountArray objectEnumerator];
    while((account = [enumerator nextObject])){
        if([(AIAccount<AIAccount_Content> *)account availableForSendingContentType:inType toListObject:inObject]){
            number++;
        }            
    }  
    
    return number;
}

- (void)setProperty:(id)inValue forKey:(NSString *)key account:(AIAccount *)inAccount
{
    if(inAccount == nil){ //Set the value globally
        NSEnumerator	*enumerator;
        AIAccount	*account;

        //Notify all accounts that support this key
        enumerator = [accountArray objectEnumerator];
        while((account = [enumerator nextObject])){
            if([[account supportedPropertyKeys] containsObject:key]){
                [account statusForKey:key willChangeTo:inValue];
            }
        }

        //Set the value
        if(inValue){
            [accountStatusDict setObject:inValue forKey:key];
        }else{
            [accountStatusDict removeObjectForKey:key];            
        }

    }else{ //Set the value for a specific account
        //Notify the account
        if([[inAccount supportedPropertyKeys] containsObject:key]){
            [inAccount statusForKey:key willChangeTo:inValue];
        }
        
        //Set the value
        [inAccount setProperty:inValue forKey:key];
    }

    //Save the accounts
    [self saveAccounts];

    //Post a properties changed notification
    [[owner notificationCenter] postNotificationName:Account_PropertiesChanged object:inAccount userInfo:[NSDictionary dictionaryWithObject:key forKey:@"Key"]];
}

- (id)propertyForKey:(NSString *)key account:(AIAccount *)inAccount
{
    id	value = nil;
    
    //Attempt to find an account specific value
    if(inAccount){
        value = [inAccount propertyForKey:key];
    }

    //Find a global value
    if(!value){
        value = [accountStatusDict objectForKey:key];        
    }

    return(value);
}

//User icon methods
- (void)setUserIcon:(NSImage *)inImage forAccount:(AIAccount *)account
{
    if([[account supportedPropertyKeys] containsObject:@"UserIcon"]){
        [account statusForKey:@"UserIcon" willChangeTo:inImage];
    }
}

- (void)setDefaultUserIcon:(NSImage *)inImage
{
    //keep track of the image
    [defaultUserIcon release]; defaultUserIcon = nil;
    defaultUserIcon = [inImage retain];
    
    //cache the image to a file
    if (defaultUserIcon) {
        [defaultUserIconFilename release];
        defaultUserIconFilename = [[self _defaultIconCachePath] retain];
        NSData      *iconData = [defaultUserIcon JPEGRepresentation];
        
        [iconData writeToFile:defaultUserIconFilename atomically:YES];
    } else {
        defaultUserIconFilename = nil;       
    }
    
    NSEnumerator	*enumerator;
    AIAccount           *account;
    
    //Notify all accounts that support DefaultBuddyImage so they can inform their servers
    enumerator = [accountArray objectEnumerator];
    while((account = [enumerator nextObject])){
        //Tell concerned accounts about the NSImage
        if([[account supportedPropertyKeys] containsObject:@"DefaultUserIcon"]){
            [account statusForKey:@"DefaultUserIcon" willChangeTo:defaultUserIcon];
        }
        //Tell concerned accounts about the filename
        if([[account supportedPropertyKeys] containsObject:@"DefaultUserIconFilename"]){
            [account statusForKey:@"DefaultUserIconFilename" willChangeTo:defaultUserIconFilename];
        }
    }
}
- (NSImage *)defaultUserIcon
{
    return defaultUserIcon;   
}
- (NSString *)defaultUserIconFilename
{
    return defaultUserIconFilename;
}

- (NSString *)_defaultIconCachePath
{
    return([[DEFAULT_ICON_CACHE_PATH stringByAppendingPathComponent:@"UserIcon_Default"] stringByExpandingTildeInPath]);
}
// Internal ----------------------------------------------------------------
//Watch outgoing content, remembering the user's choice of source account
- (void)didSendContent:(NSNotification *)notification
{
    AIChat		*chat = [notification object];
    AIListObject	*destObject = [chat listObject];

    if(chat && destObject){
        AIContentObject		*contentObject = [[notification userInfo] objectForKey:@"Object"];
        AIAccount		*sourceAccount = (AIAccount *)[contentObject source];

        [[owner preferenceController] setPreference:[sourceAccount accountID]
                                             forKey:KEY_PREFERRED_SOURCE_ACCOUNT
                                              group:PREF_GROUP_PREFERRED_ACCOUNTS
                                             object:destObject];

        [lastAccountIDToSendContent setObject:[sourceAccount accountID] forKey:[destObject serviceID]];
    }
}

//automatically connect to accounts flagged with an auto connect property
- (void)autoConnectAccounts
{
    NSEnumerator	*enumerator;
    AIAccount		*account;
    
    enumerator = [accountArray objectEnumerator];
    while((account = [enumerator nextObject])){
        if([[account supportedPropertyKeys] containsObject:@"Online"] && [[account propertyForKey:@"AutoConnect"] boolValue]){
            [self setProperty:[NSNumber numberWithBool:YES] forKey:@"Online" account:account];
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
            [self setProperty:[NSNumber numberWithBool:YES] forKey:@"Online" account:account];
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
            [self setProperty:[NSNumber numberWithBool:NO] forKey:@"Online" account:account];
        }
    }
}

//Call after making changes to the account list
- (void)accountListChanged
{
    //Save the changes
    [self saveAccounts];

    //Broadcast an account list changed message
    [[owner notificationCenter] postNotificationName:Account_ListChanged object:nil userInfo:nil];
}

// Loads the saved accounts and returns them (as AIAccounts) in a mutable array
- (void)loadAccounts
{
    NSArray		*savedAccountArray;
    int			loop;
    NSMutableArray	*tempArray = [NSMutableArray array];
    
    //Create an instance of every saved account
    savedAccountArray = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_ACCOUNTS] objectForKey:ACCOUNT_LIST];
    for(loop = 0;loop < [savedAccountArray count];loop++){
        NSDictionary	*serviceDict;
        NSDictionary	*propertyDict;
        NSString	*serviceType;
        AIAccount	*newAccount;

        //Fetch the service
        serviceDict = [savedAccountArray objectAtIndex:loop];

        //Get the service type and properties
        serviceType = [serviceDict objectForKey:ACCOUNT_TYPE];
        propertyDict = [serviceDict objectForKey:ACCOUNT_PROPERTIES];

        //Create the connection and add it to our array
        newAccount = [self accountOfType:serviceType withProperties:propertyDict];
        if(newAccount){
            [tempArray addObject:newAccount];
        }
    }

    if(accountArray) [accountArray release];
    accountArray = [tempArray retain];
}

//Save the account list
- (void)saveAccounts
{
    if(accountArray){
        [self saveAccounts:accountArray];
    }
}

//Saves an array of AIAccounts in dictionary form
- (void)saveAccounts:(NSArray *)inAccounts
{
    NSMutableArray	*accountDictArray = [[NSMutableArray alloc] init];
    NSString		*userDirectory;
    int			loop;

    NSParameterAssert(inAccounts != nil);

    //Get the user preference directory
    userDirectory = [[owner loginController] userDirectory];

    //Create a dictionary for every open connection
    for(loop = 0;loop < [inAccounts count];loop++){
        NSMutableDictionary	*accountDict = [[NSMutableDictionary alloc] init];
        AIAccount		*account = [inAccounts objectAtIndex:loop];

        [accountDict setObject:[[account service] identifier] forKey:ACCOUNT_TYPE];
        [accountDict setObject:[account properties] forKey:ACCOUNT_PROPERTIES];

        [accountDictArray addObject:accountDict];
    
        [accountDict release];
    }

    //save
    [[owner preferenceController] setPreference:accountDictArray forKey:ACCOUNT_LIST group:PREF_GROUP_ACCOUNTS];
    [accountDictArray release];
    
}

// Returns a default account
- (AIAccount *)defaultAccount
{
    AIAccount	*defaultAccount = [self accountOfType:@"AIM (TOC2)" withProperties:[NSDictionary dictionaryWithObjectsAndKeys:nil]];

    NSParameterAssert(defaultAccount != nil);

    return(defaultAccount);
}

// Returns a new account of the specified type and properties
- (AIAccount *)accountOfType:(NSString *)inType withProperties:(NSDictionary *)inProperties
{
    NSEnumerator		*enumerator;
    id <AIServiceController>	service;
    AIAccount			*newAccount = nil;
    
    NSParameterAssert(inType != nil); NSParameterAssert([inType length] != 0);
    NSParameterAssert(inProperties != nil);
    
    //Load the account
    enumerator = [availableServiceArray objectEnumerator];
    while((service = [enumerator nextObject])){
        if([inType compare:[service identifier]] == 0){
            break;
        }
    }    
    newAccount = [service accountWithProperties:inProperties];

    return(newAccount);
}


@end

