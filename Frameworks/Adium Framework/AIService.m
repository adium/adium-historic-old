//
//  AIService.m
//  Adium
//
//  Created by Adam Iser on 8/24/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "AIService.h"


@implementation AIService

//Init this service
- (id)init
{
	[super init];
	
	//Register this service with Adium
    [[adium accountController] registerService:self];
	
	return(self);
}


//Account Creation -----------------------------------------------------------------------------------------------------
//Create a new account for this service
//Accounts are identified by a unique number (We can't use service or UID, since both those values may change)
- (id)accountWithUID:(NSString *)inUID accountNumber:(int)inAccountNumber
{
	return([[[[self accountClass] alloc] initWithUID:inUID accountNumber:inAccountNumber service:self] autorelease]);
}

//Account class associated with this service
- (Class)accountClass
{
	return(nil);
}

//Return an account view controller for this service.  The view controller has controls for all additional information
//the service needs in the account preferences.
- (AIAccountViewController *)accountView
{
	return(nil);
}

//Return a chat join view controller for this service.  This might be better placed in the account code.
- (DCJoinChatViewController *)joinChatView
{
	
}


//Service Description --------------------------------------------------------------------------------------------------
#pragma mark Service Description
//Unique identifier for this class
//The serviceCodeUniqueID identifies this class.  No two classes should have the same uniqueID.  This value is used
//to determine which protocol code to use for the user's accounts.
//Examples: "libgaim-aim", "aim-toc2", "imservices-aim-.mac"
- (NSString *)serviceCodeUniqueID{
    return(@"");
}

//Identifier of the service we are supporting
//Examples: "aim", "msn", "jabber", "icq", ".mac"
- (NSString *)serviceID{
    return(@"");
}

//Service class
//Some separate services can communicate with eachother.  These services, while they have separate serviceID's,
//are all part of a common service class.  For instance, AIM, ICQ, and .Mac are all part of the "AIM" service class.
//For many services, the serviceClass will be identical to the serviceID.
//Service classes may change, do not use them for any permenant storage (logs, preferences, etc)
//Examples: "aim-compatible", "jabber", "msn", "icq"
- (NSString *)serviceClass{
	return(@"");
}

//Human readable, short description of this service
//This value is used in tooltips and the message window.
//Examples: "Jabber", "MSN", "AIM", ".Mac"
- (NSString *)shortDescription{
    return(@"");
}

//Human readable, long description of this service
//If there are multiple classes available for the same service, this description should briefly show the difference
//between the implementations.  This value is used in the account preferences service menu.
//Examples: "Jabber", "MSN", "AIM (Oscar)", "AIM (TOC)", ".Mac"
- (NSString *)longDescription{
    return(@"");
}

//Characters allowed in user names on this service.  The user will not be allowed to type any characters not in this
//set as a contact or account name.
- (NSCharacterSet *)allowedCharacters
{
    return(nil);
}

//Ignored characters for user names on this service.  Ignored characters are stripped from account and contact names
//before they are used, but the user is free to type them and they may be used by the service code.  For instance, 
//spaces are allowed in AIM usernames, but "ad am" is treated as equal to "adam" because space is an ignored character.
- (NSCharacterSet *)ignoredCharacters
{
    return(nil);
}

//Max allowed length of user names of this service.  Account and contact names longer than this will not be allowed.
- (int)allowedLength
{
    return(0);
}

//Case sensitivity of account and contact names.  Determines if usernames such as "Adam" and "adam" are unique.
- (BOOL)caseSensitive
{
    return(NO);
}

//Importance grouping of this service.  Used to make service listings and menus more organized.
- (AIServiceImportance)serviceImportance
{
	return(AIServiceUnsupported);
}


//Utilities ------------------------------------------------------------------------------------------------------------
#pragma mark Utilities
//UID's are ONLY filtered when creating contacts, and when renaming contacts .
//When changing ownership of a handle, a filter is not necessary, since all the accounts should have the same service types and requirements.
//When account code retrieves handles from the contact list, filtering is NOT done.  It is up to the account to ensure it passes UID's in the proper format for it's service type.
//Filter UID's only when the user has entered or mucked with them in some way... UID's TO and FROM account code SHOULD ALWAYS BE VALID.
//Filters a UID.  All invalid characters and ignored characters are removed.
- (NSString *)filterUID:(NSString *)inUID removeIgnoredCharacters:(BOOL)removeIgnored
{
	NSString	*workingString = ([self caseSensitive] ? inUID : [inUID lowercaseString]);
	NSCharacterSet	*allowedCharacters = [self allowedCharacters];
	NSCharacterSet	*ignoredCharacters = [self ignoredCharacters];
	
	//Prepare a little buffer for our filtered UID
	int		destLength = 0;
	unichar *dest = malloc([workingString length] * sizeof(unichar));
	
	//Filter the UID
	int pos;
	for(pos = 0; pos < [workingString length]; pos++){
		unichar c = [workingString characterAtIndex:pos];
		
        if([allowedCharacters characterIsMember:c] && (!removeIgnored || ![ignoredCharacters characterIsMember:c])){
            dest[destLength] = (removeIgnored ? [workingString characterAtIndex:pos] : [inUID characterAtIndex:pos]);
			destLength++;
		}
	}
	
	//Turn it back into a string and return
    NSString *filteredString = [NSString stringWithCharacters:dest length:destLength];
	free(dest);
	
	return(filteredString);
}

//Attributes
- (BOOL)canCreateGroupChats
{
	return NO;
}

@end
