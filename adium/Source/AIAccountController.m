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

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "AIAccountController.h"
#import "AILoginController.h"
#import "AIPreferenceController.h"
#import "AIPasswordPromptController.h"


//Paths and Filenames
//#define DIRECTORY_INTERNAL_SERVICES		@"/Contents/Plugins"	//Path to the internal services
//Preference keys
#define ACCOUNT_LIST				@"Account List"	//Array of accounts
#define ACCOUNT_TYPE				@"Type"			//Account type
#define ACCOUNT_PROPERTIES			@"Properties"		//Account properties
//Other
//#define EXTENSION_ADIUM_SERVICE			@"AdiumService"		//File extension on a service

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
@end

@implementation AIAccountController

// init
- (void)initController
{
    //init
    accountNotificationCenter = nil;
    availableServiceArray = [[NSMutableArray alloc] init];
    accountArray = [[NSMutableArray alloc] init];
    
    //Observe
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adiumLaunchComplete:) name:Adium_LaunchComplete object:nil];
}

// dealloc
- (void)dealloc
{
    [accountArray release];
    [accountNotificationCenter release];
    [availableServiceArray release];

    [super dealloc];
}

- (void)adiumLaunchComplete:(NSNotification *)notification
{
    //Load the user accounts
    [self loadAccounts];
    [self accountListChanged];

    //Observe the newly loaded account list
    [[self accountNotificationCenter] addObserver:self selector:@selector(accountPropertiesChanged:) name:Account_PropertiesChanged object:nil];
    
    //Autoconnect
    [self autoConnectAccounts];
}

// Returns the account notification center
- (NSNotificationCenter *)accountNotificationCenter
{
    if(accountNotificationCenter == nil){
        accountNotificationCenter = [[NSNotificationCenter alloc] init];
    }
    
    return(accountNotificationCenter);
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

    //Delete the account
    [accountArray removeObject:inAccount];

    [self accountListChanged];
}

// Returns the account array
- (NSArray *)accountArray
{
    NSParameterAssert(accountArray != nil);

    return(accountArray);
}

//Switches the service of the specified account
- (AIAccount *)switchAccount:(AIAccount *)inAccount toService:(id <AIServiceController>)inService
{
    AIAccount	*newAccount;

    //Change the service type
    [[inAccount properties] setObject:[inService identifier] forKey:ACCOUNT_TYPE];
    
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

//fetch a saved password
- (void)passwordForAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget selector:(SEL)inSelector
{
    NSString	*password;

    //check the keychain for this password
    password = [AIKeychain getPasswordFromKeychainForService:[NSString stringWithFormat:@"Adium.%@",[inAccount accountID]] account:[inAccount accountID]];
    
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
    [AIKeychain removePasswordFromKeychainForService:[NSString stringWithFormat:@"Adium.%@",[inAccount accountID]] account:[inAccount accountID]];
}

//Return the available services
- (NSArray *)availableServiceArray
{
    return(availableServiceArray);
}

//Register service code
- (void)registerService:(id <AIServiceController>)inService
{
    [availableServiceArray addObject:inService];
}
            



// Internal ----------------------------------------------------------------
//automatically connect to accounts flagged with an auto connect property
- (void)autoConnectAccounts
{
    NSEnumerator	*enumerator;
    AIAccount		*account;
    
    enumerator = [accountArray objectEnumerator];
    while((account = [enumerator nextObject])){
        NSDictionary	*properties = [account properties];
        
        if([account conformsToProtocol:@protocol(AIAccount_Status)] && [[properties objectForKey:@"AutoConnect"] boolValue]){
            [(AIAccount<AIAccount_Status> *)account connect];
        }
    }
}

- (void)accountPropertiesChanged:(NSNotification *)notification
{
    //Save the changes
    [self saveAccounts];
}

//Call after making changes to the account list
- (void)accountListChanged
{
    //Save the changes
    [self saveAccounts];

    //Broadcast an account list changed message
    [[self accountNotificationCenter] postNotificationName:Account_ListChanged object:nil userInfo:nil];
}

// Loads the saved accounts and returns them (as AIAccounts) in a mutable array
- (void)loadAccounts
{
    NSArray		*savedAccountArray;
    int			loop;

    if(accountArray) [accountArray release];
    accountArray = [[NSMutableArray alloc] init];
    
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
            [accountArray addObject:newAccount];
        }
    }
}

//Save the account list
- (void)saveAccounts
{
    [self saveAccounts:accountArray];
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
    newAccount = [service accountWithProperties:inProperties owner:owner];

    return(newAccount);
}

//Builds an array of available service types and descriptions
/*- (NSMutableArray *)loadServices
{
    NSString		*servicePath;
    NSMutableArray	*serviceArray;
    NSArray		*directoryContents;
    NSString		*fileName;
    NSEnumerator	*enumerator;
    
    //Create the arrays
    serviceArray = [[NSMutableArray alloc] init];

    //Fetch the list of available services
    servicePath = [[[[NSBundle mainBundle] bundlePath]
        stringByAppendingPathComponent:DIRECTORY_INTERNAL_SERVICES]
        stringByExpandingTildeInPath];

    directoryContents = [[NSFileManager defaultManager] directoryContentsAtPath:servicePath];

    //Get type and description info from each bundle
    enumerator = [directoryContents objectEnumerator];
    while((fileName = [enumerator nextObject])){
        if([[fileName pathExtension] compare:EXTENSION_ADIUM_SERVICE] == 0){
            NSString		*bundlePath = [servicePath stringByAppendingPathComponent:fileName];
            NSBundle		*serviceBundle = [NSBundle bundleWithPath:bundlePath];
            AIService		*service = [[serviceBundle principalClass] serviceWithOwner:owner];
            
            [serviceArray addObject:service];
        }
    }
    
    return([serviceArray autorelease]);
}*/


@end

