//
//  ESAdiumPasswordUpgrader.m
//  AdiumPasswordUpgrader
//
//  Created by Evan Schoenberg on 1/9/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "ESAdiumPasswordUpgrader.h"
#import "AIKeychain.h"
#import "AIKeychainOld.h"
#import "AIDictionaryAdditions.h"

#define LOGIN_LAST_USER				@"Last Login Name"		//Last logged in user
#define LOGIN_PREFERENCES_FILE_NAME @"Login Preferences"	//Login preferences file name
#define PATH_USERS					@"/Users"		//Path of the users folder

#define ADIUM_APPLICATION_SUPPORT_DIRECTORY	[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Adium 2.0"]
#define ADIUM_SUBFOLDER_OF_APP_SUPPORT		@"Adium 2.0"
#define ADIUM_SUBFOLDER_OF_LIBRARY			@"Application Support/Adium 2.0"

#define PREF_GROUP_ACCOUNTS             @"Accounts"
#define ACCOUNT_LIST					@"Accounts"   		//Array of accounts
#define ACCOUNT_TYPE					@"Type"				//Account type
#define ACCOUNT_SERVICE					@"Service"			//Account service
#define ACCOUNT_UID						@"UID"				//Account UID
#define ACCOUNT_OBJECT_ID				@"ObjectID"   		//Account object ID

@interface ESAdiumPasswordUpgrader (PRIVATE)
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName;
- (NSString *)userDirectory;
@end

@implementation ESAdiumPasswordUpgrader

- (void) upgradePasswordForAccountWithUID:(NSString *)accountUID
								serviceID:(NSString *)serviceID
							accountNumber:(int)accountNumber
{
	NSString	*accountName = 	[NSString stringWithFormat:@"%@.%i",serviceID,accountNumber];
	NSString	*passKey = [NSString stringWithFormat:@"Adium.%@",accountName];
	
	//Retrieve from old
    NSString	*password = [AIKeychainOld getPasswordFromKeychainForService:passKey
																	 account:accountName];
	//Store in new
	if(password){
		[AIKeychain putPasswordInKeychainForService:passKey
											account:accountName
										   password:password];
	}
}

- (IBAction)upgrade:(id)sender
{	
	[self performSelector:@selector(doUpgrade)
			   withObject:nil
			   afterDelay:0];
}

- (void)doUpgrade
{
	[text setStringValue:@"Upgrading passwords, please wait...."];
	[text display];

	[progressBar setUsesThreadedAnimation:YES];

	NSArray			*accountList;
	NSEnumerator	*enumerator;
	NSDictionary	*accountDict;
	
	accountList = [self preferenceForKey:ACCOUNT_LIST group:PREF_GROUP_ACCOUNTS];
	
	double progress = 0;

	[progressBar setMaxValue:[accountList count]];

    //Upgrade every saved account
	enumerator = [accountList objectEnumerator];
	while(accountDict = [enumerator nextObject]){
		NSString		*serviceID = [accountDict objectForKey:ACCOUNT_TYPE];
		NSString		*accountUID;
		int				accountNumber;
		
		//TEMPORARY UPGRADE CODE  0.63 -> 0.70 (Account format changed)
		//####################################
		if([serviceID isEqualToString:@"AIM-LIBGAIM"]){
			NSString 	*uid = [accountDict objectForKey:ACCOUNT_UID];
			if(uid && [uid length]){
				const char	firstCharacter = [uid characterAtIndex:0];
				
				if([uid hasSuffix:@"@mac.com"]){
					serviceID = @"libgaim-oscar-Mac";
				}else if(firstCharacter >= '0' && firstCharacter <= '9'){
					serviceID = @"libgaim-oscar-ICQ";
				}else{
					serviceID = @"libgaim-oscar-AIM";
				}
			}
		}else if([serviceID isEqualToString:@"GaduGadu-LIBGAIM"]){
			serviceID = @"libgaim-Gadu-Gadu";
		}else if([serviceID isEqualToString:@"Jabber-LIBGAIM"]){
			serviceID = @"libgaim-Jabber";
		}else if([serviceID isEqualToString:@"MSN-LIBGAIM"]){
			serviceID = @"libgaim-MSN";
		}else if([serviceID isEqualToString:@"Napster-LIBGAIM"]){
			serviceID = @"libgaim-Napster";
		}else if([serviceID isEqualToString:@"Novell-LIBGAIM"]){
			serviceID = @"libgaim-GroupWise";
		}else if([serviceID isEqualToString:@"Sametime-LIBGAIM"]){
			serviceID = @"libgaim-Sametime";
		}else if([serviceID isEqualToString:@"Yahoo-LIBGAIM"]){
			serviceID = @"libgaim-Yahoo!";
		}else if([serviceID isEqualToString:@"Yahoo-Japan-LIBGAIM"]){
			serviceID = @"libgaim-Yahoo!-Japan";
		}
		//####################################
		
		accountUID = [accountDict objectForKey:ACCOUNT_UID];
		accountNumber = [[accountDict objectForKey:ACCOUNT_OBJECT_ID] intValue];

		
		/* Ghetto.  But okay, 'cause it's deposable code.  We want the serviceID, no the uniqueServiceID.
		 * Fortunately, that just means taking out the libgaim-. */
		NSMutableString		*properServiceID = [serviceID mutableCopy];
		[properServiceID replaceOccurrencesOfString:@"libgaim-"
										 withString:@""
											options:(NSAnchoredSearch | NSLiteralSearch)
											  range:NSMakeRange(0, [properServiceID length])];
		[properServiceID replaceOccurrencesOfString:@"oscar-"
										 withString:@""
											options:(NSAnchoredSearch | NSLiteralSearch)
											  range:NSMakeRange(0, [properServiceID length])];
		
		[self upgradePasswordForAccountWithUID:accountUID
									 serviceID:properServiceID
								 accountNumber:accountNumber];
		 
		[progressBar setDoubleValue:++progress];
		[progressBar display];
	}

	[NSApp performSelector:@selector(terminate:)
				withObject:nil
				afterDelay:5.0];
}


- (NSMutableDictionary *)loadPreferenceGroup:(NSString *)groupName
{
    NSMutableDictionary	*prefDict = nil;
    
	NSString 	*path = [self userDirectory];
	
	prefDict = [NSMutableDictionary dictionaryAtPath:path withName:groupName create:YES];
    
    return(prefDict);
}

//Return a preference key
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName
{
    return([[self loadPreferenceGroup:groupName] objectForKey:inKey]);
}

//Returns the location of Adium's preference folder (within the system's 'application support' directory)
- (NSString *)applicationSupportDirectory
{
    return([ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByExpandingTildeInPath]);
}

static NSString	*userDirectory = nil;
- (NSString *)userDirectory
{
	if(!userDirectory){
		NSDictionary	*loginDict;
		
		//Open the login preferences
		loginDict = [NSDictionary dictionaryAtPath:[self applicationSupportDirectory] withName:LOGIN_PREFERENCES_FILE_NAME create:YES];
		
		//Auto-login as the saved user
		NSString	*userName = [loginDict objectForKey:LOGIN_LAST_USER];
		
		userDirectory = [[[self applicationSupportDirectory] stringByAppendingPathComponent:PATH_USERS] stringByAppendingPathComponent:userName];
	}

	return userDirectory;
}

@end
