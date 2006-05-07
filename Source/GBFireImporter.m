/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "GBFireImporter.h"
#import "AIUtilities/AIFileManagerAdditions.h"
#import "AIAccountController.h"
#import "AIAccount.h"
#import "AIStatus.h"
#import "AIHTMLDecoder.h"
#import "AIStatusController.h"
#import "AIContactController.h"
#import "AIListGroup.h"
#import "AIListContact.h"
#import "AIMetaContact.h"

#define FIRECONFIGURATION2		@"FireConfiguration2.plist"
#define FIRECONFIGURATION		@"FireConfiguration.plist"
#define ACCOUNTS2				@"Accounts2.plist"
#define ACCOUNTS				@"Accounts.plist"

@interface GBFireImporter (private)
- (BOOL)importFireConfiguration;
- (BOOL)import2:(NSString *)fireDir;
- (BOOL)import1:(NSString *)fireDir;
@end

@implementation GBFireImporter

+ (BOOL)importFireConfiguration
{
	GBFireImporter *importer = [[GBFireImporter alloc] init];
	BOOL ret = [importer importFireConfiguration];
	
	[importer release];
	return ret;
}

- (BOOL)importFireConfiguration
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *fireDir = [[[NSFileManager defaultManager] userApplicationSupportFolder] stringByAppendingPathComponent:@"Fire"];
	BOOL version2Succeeded = NO;
	BOOL version1Succeeded = NO;
	BOOL ret = YES;
	
	version2Succeeded = [self import2:fireDir];
	
	if(!version2Succeeded)
		//try version 1
		version1Succeeded = [self import1:fireDir];
	
	if(!version2Succeeded && !version1Succeeded)
		//throw some error
		ret = NO;
	
	[pool release];
	return ret;
}

- (void)_importAccounts2:(NSArray *)accountsDict
			translations:(NSMutableDictionary *)accountUIDtoAccount
{
	NSEnumerator *serviceEnum = [[[adium accountController] services] objectEnumerator];
	AIService *service = nil;
	NSMutableDictionary *serviceDict = [NSMutableDictionary dictionary];
	while ((service = [serviceEnum nextObject]) != nil)
	{
		[serviceDict setObject:service forKey:[service serviceID]];
	}
	[serviceDict setObject:[serviceDict objectForKey:@"Bonjour"] forKey:@"Rendezvous"];
	[serviceDict setObject:[serviceDict objectForKey:@"GTalk"] forKey:@"GoogleTalk"];
	[serviceDict setObject:[serviceDict objectForKey:@"Yahoo!"] forKey:@"Yahoo"];
	
	NSEnumerator *accountEnum = [accountsDict objectEnumerator];
	NSDictionary *account = nil;
	while((account = [accountEnum nextObject]) != nil)
	{
		NSString *serviceName = [account objectForKey:@"ServiceName"];
		NSString *accountName = [account objectForKey:@"Username"];
		if(![serviceName length] || ![accountName length])
			continue;
		AIService *service = [serviceDict objectForKey:serviceName];
		if(service == nil)
			//Like irc service
			continue;
		AIAccount *newAcct = [[adium accountController] createAccountWithService:service
																			 UID:accountName];
		if(newAcct == nil)
			continue;
		
		[newAcct setPreference:[account objectForKey:@"AutoLogin"]
						forKey:@"Online"
						 group:GROUP_ACCOUNT_STATUS];
		
		NSDictionary *properties = [account objectForKey:@"Properties"];
		NSString *connectHost = [properties objectForKey:@"server"];
		if([connectHost length])
			[newAcct setPreference:connectHost
							forKey:KEY_CONNECT_HOST
							 group:GROUP_ACCOUNT_STATUS];	
		
		int port = [[properties objectForKey:@"port"] intValue];
		if(port)
			[newAcct setPreference:[NSNumber numberWithInt:port]
							forKey:KEY_CONNECT_PORT
							 group:GROUP_ACCOUNT_STATUS];
		
		[accountUIDtoAccount setObject:newAcct forKey:[account objectForKey:@"UniqueID"]];
		[[adium accountController] addAccount:newAcct];
	}	
}

- (void)_importAways2:(NSArray *)awayList
{
	NSEnumerator *awayEnum = [awayList objectEnumerator];
	NSDictionary *away = nil;
	while((away = [awayEnum nextObject]) != nil)
	{
		NSString *title = [away objectForKey:@"Title"];
		BOOL isDefault = [[away objectForKey:@"isIdleMessage"] boolValue];
		BOOL goIdle = [[away objectForKey:@"idleMessage"] boolValue];
		NSString *attrMessage = [away objectForKey:@"message"];
		int fireType = [[away objectForKey:@"messageType"] intValue];
		AIStatusType adiumType = 0;
		
		switch(fireType)
		{
			case 0:
			case 1:
				adiumType = AIAvailableStatusType;
				break;
			case 4:
				adiumType = AIInvisibleStatusType;
			case 3:
			case 2:
			default:
				adiumType = AIAwayStatusType;
		}
		
		AIStatus *newStatus = [AIStatus statusOfType:adiumType];
		[newStatus setTitle:title];
		[newStatus setStatusMessage:[AIHTMLDecoder decodeHTML:attrMessage]];
		[newStatus setAutoReplyIsStatusMessage:YES];
		[newStatus setShouldForceInitialIdleTime:goIdle];
		[[adium statusController] addStatusState:newStatus];
	}	
}

NSComparisonResult groupSort(id left, id right, void *context)
{
	NSNumber *leftNum = [left objectForKey:@"position"];
	NSNumber *rightNum = [right objectForKey:@"position"];
	NSComparisonResult ret = NSOrderedSame;
	
	if(leftNum == nil)
	{
		if(rightNum != nil)
			ret = NSOrderedAscending;
	}
	else if (rightNum == nil)
		ret = NSOrderedDescending;
	else
		ret = [leftNum compare:rightNum];
	
	return ret;
}

- (void)_importGroups2:(NSDictionary *)groupList
{
	AIContactController *contactController = [adium contactController];

	//First itterate through the groups and create an array we can sort
	NSEnumerator *groupEnum = [groupList keyEnumerator];
	NSString *groupName = nil;
	NSMutableArray *groupArray = [NSMutableArray array];
	while((groupName = [groupEnum nextObject]) != nil)
	{
		NSMutableDictionary *groupDict = [[groupList objectForKey:groupName] mutableCopy];
		[groupDict setObject:groupName forKey:@"Name"];
		[groupArray addObject:groupDict];
		[groupDict release];
	}
	[groupArray sortUsingFunction:groupSort context:NULL];
	groupEnum = [groupArray objectEnumerator];
	NSDictionary *group = nil;
	while((group = [groupEnum nextObject]) != nil)
	{
		AIListGroup *newGroup = [contactController groupWithUID:[group objectForKey:@"Name"]];
		NSNumber *expanded = [group objectForKey:@"groupexpanded"];
		if(expanded != nil)
			[newGroup setExpanded:[expanded boolValue]];
	}	
}

- (void)_importBuddies2:(NSArray *)buddyArray
	accountTranslations:(NSMutableDictionary *)accountUIDtoAccount
	buddiesTranslations:(NSMutableDictionary *)buddiesToContact
	  aliasTranslations:(NSMutableDictionary *)aliasToContacts
{
	AIContactController *contactController = [adium contactController];

	NSEnumerator *buddyEnum = [buddyArray objectEnumerator];
	NSDictionary *buddy = nil;
	while((buddy = [buddyEnum nextObject]) != nil)
	{
		NSNumber *inList = [buddy objectForKey:@"BuddyInList"];
		if(inList == nil || [inList boolValue] == NO)
			continue;
		
		NSNumber *accountNumber = [buddy objectForKey:@"account"];
		AIAccount *account = [accountUIDtoAccount objectForKey:accountNumber];
		if(account == nil)
			continue;
		
		NSString *buddyName = [buddy objectForKey:@"buddyname"];
		if([buddyName length] == 0)
			continue;
		
		AIListContact *newContact = [contactController contactWithService:[account service] account:account UID:buddyName];
		if(newContact == nil)
			continue;
		
		NSMutableDictionary *accountBuddyList = [buddiesToContact objectForKey:accountNumber];
		if(accountBuddyList == nil)
		{
			accountBuddyList = [NSMutableDictionary dictionary];
			[buddiesToContact setObject:accountBuddyList forKey:accountNumber];
		}
		[accountBuddyList setObject:newContact forKey:buddyName];
		
		NSString *alias = [buddy objectForKey:@"displayname"];
		if([alias length] != 0)
		{
			[newContact setDisplayName:alias];
			NSMutableArray *contactArray = [aliasToContacts objectForKey:alias];
			if(contactArray == nil)
			{
				contactArray = [NSMutableArray array];
				[aliasToContacts setObject:contactArray forKey:alias];
			}
			[contactArray addObject:newContact];
		}
		
		BOOL blocked = [[buddy objectForKey:@"BuddyBlocked"] boolValue];
		if(blocked)
			[newContact setIsBlocked:YES updateList:YES];
		
		//Adium can only support a single group per buddy (boo!!!) so use the first
		NSString *groupName = [[buddy objectForKey:@"Groups"] objectAtIndex:0];
		if([groupName length] != 0)
			[newContact setRemoteGroupName:groupName];
	}	
}

- (void)_importPersons2:(NSArray *)personArray
	buddiesTranslations:(NSDictionary *)buddiesToContact
{
	AIContactController *contactController = [adium contactController];

	NSEnumerator *personEnum = [personArray objectEnumerator];
	NSDictionary *person = nil;
	while((person = [personEnum nextObject]) != nil)
	{
		NSString *personName = [person objectForKey:@"Name"];
		if([personName length] == 0)
			continue;
		
		if([personName hasPrefix:@"Screenname:"])
			continue;
		
		NSArray *buddyArray = [person objectForKey:@"Buddies"];
		if([buddyArray count] == 0)
			//Empty meta-contact; don't bother
			continue;

		NSEnumerator *buddyEnum = [buddyArray objectEnumerator];
		NSDictionary *buddyInfo = nil;
		NSMutableArray *buddies = [NSMutableArray array];
		while ((buddyInfo = [buddyEnum nextObject]) != nil)
		{
			NSNumber *buddyAccount = [buddyInfo objectForKey:@"BuddyAccount"];
			NSString *buddySN = [buddyInfo objectForKey:@"BuddyName"];
			
			if(buddyAccount == nil || buddySN == nil)
				continue;
			
			AIListContact *contact = [[buddiesToContact objectForKey:buddyAccount] objectForKey:buddySN];
			if(contact == nil)
				//Contact lookup failed
				continue;
			
			[buddies addObject:contact];
		}
		[contactController groupListContacts:buddies];
	}
}

- (void)createMetaContacts:(NSMutableDictionary *)aliasToContacts
{
	AIContactController *contactController = [adium contactController];

	NSEnumerator *metaContantEnum = [aliasToContacts objectEnumerator];
	NSArray *contacts = nil;
	while ((contacts = [metaContantEnum nextObject]) != nil)
		[contactController groupListContacts:contacts];
}

- (BOOL)import2:(NSString *)fireDir
{
	NSString *configPath = [fireDir stringByAppendingPathComponent:FIRECONFIGURATION2];
	NSString *accountPath = [fireDir stringByAppendingPathComponent:ACCOUNTS2];
	NSDictionary *configDict = [NSDictionary dictionaryWithContentsOfFile:configPath];
	NSDictionary *accountDict = [NSDictionary dictionaryWithContentsOfFile:accountPath];
	
	if(configDict == nil || accountDict == nil)
		//no dictionary or no account, can't import
		return NO;
	
	NSMutableDictionary *accountUIDtoAccount = [NSMutableDictionary dictionary];
	
	//Start with accounts
	[self _importAccounts2:[accountDict objectForKey:@"Accounts"]
			  translations:accountUIDtoAccount];
	
	//Away Messages
	[self _importAways2:[configDict objectForKey:@"awayMessages"]];

	//Now for the groups
	[self _importGroups2:[configDict objectForKey:@"groups"]];
	
	//Buddies
	NSMutableDictionary *buddiesToContact = [NSMutableDictionary dictionary];
	NSMutableDictionary *aliasToContacts = [NSMutableDictionary dictionary];
	[self _importBuddies2:[configDict objectForKey:@"buddies"]
	  accountTranslations:accountUIDtoAccount
	  buddiesTranslations:buddiesToContact
		aliasTranslations:aliasToContacts];

	//Persons
	NSArray *personArray = [configDict objectForKey:@"persons"];
	if([personArray count] > 0)
		[self _importPersons2:personArray
		  buddiesTranslations:buddiesToContact];
	else
		[self createMetaContacts:aliasToContacts];
	
	return YES;
}

- (void)_importAccounts1:(NSDictionary *)accountsDict
			translations:(NSMutableDictionary *)accountUIDtoAccount
{
	NSEnumerator *serviceEnum = [[[adium accountController] services] objectEnumerator];
	AIService *service = nil;
	NSMutableDictionary *serviceDict = [NSMutableDictionary dictionary];
	while ((service = [serviceEnum nextObject]) != nil)
	{
		[serviceDict setObject:service forKey:[service serviceID]];
	}
	[serviceDict setObject:[serviceDict objectForKey:@"Bonjour"] forKey:@"Rendezvous"];
	[serviceDict setObject:[serviceDict objectForKey:@"GTalk"] forKey:@"GoogleTalk"];
	[serviceDict setObject:[serviceDict objectForKey:@"Yahoo!"] forKey:@"Yahoo"];
	
	NSEnumerator *serviceNameEnum = [accountsDict keyEnumerator];
	NSString *serviceName = nil;
	while ((serviceName = [serviceNameEnum nextObject]) != nil)
	{
		if(![serviceName length])
			continue;
		
		service = [serviceDict objectForKey:serviceName];
		if(service == nil)
			//Like irc service
			continue;

		NSEnumerator *accountEnum = [[accountsDict objectForKey:serviceName] objectEnumerator];
		NSDictionary *account = nil;
		AIService *service = [serviceDict objectForKey:serviceName];
		
		while((account = [accountEnum nextObject]) != nil)
		{
			NSString *accountName = [account objectForKey:@"userName"];
			if(![accountName length])
				continue;
			AIAccount *newAcct = [[adium accountController] createAccountWithService:service
																				 UID:accountName];
			if(newAcct == nil)
				continue;
			
			[newAcct setPreference:[account objectForKey:@"autoLogin"]
							forKey:@"Online"
							 group:GROUP_ACCOUNT_STATUS];
			
			NSString *connectHost = [account objectForKey:@"server"];
			if([connectHost length])
				[newAcct setPreference:connectHost
								forKey:KEY_CONNECT_HOST
								 group:GROUP_ACCOUNT_STATUS];	
			
			int port = [[account objectForKey:@"port"] intValue];
			if(port)
				[newAcct setPreference:[NSNumber numberWithInt:port]
								forKey:KEY_CONNECT_PORT
								 group:GROUP_ACCOUNT_STATUS];
			
			[accountUIDtoAccount setObject:newAcct forKey:[NSString stringWithFormat:@"%@-%@@%@", serviceName, accountName, connectHost]];
			[[adium accountController] addAccount:newAcct];
		}
	}
}

- (void)_importAways1:(NSArray *)awayList
{
	NSEnumerator *awayEnum = [awayList objectEnumerator];
	NSDictionary *away = nil;
	while((away = [awayEnum nextObject]) != nil)
	{
		NSString *title = [away objectForKey:@"Title"];
		BOOL isDefault = [[away objectForKey:@"isIdleMessage"] boolValue];
		BOOL goIdle = [[away objectForKey:@"idleMessage"] boolValue];
		NSString *message = [away objectForKey:@"message"];
		int fireType = [[away objectForKey:@"messageType"] intValue];
		AIStatusType adiumType = 0;
		
		switch(fireType)
		{
			case 0:
			case 1:
				adiumType = AIAvailableStatusType;
				break;
			case 4:
				adiumType = AIInvisibleStatusType;
			case 3:
			case 2:
			default:
				adiumType = AIAwayStatusType;
		}
		
		AIStatus *newStatus = [AIStatus statusOfType:adiumType];
		[newStatus setTitle:title];
		[newStatus setStatusMessage:[[[NSAttributedString alloc] initWithString:message] autorelease]];
		[newStatus setAutoReplyIsStatusMessage:YES];
		[newStatus setShouldForceInitialIdleTime:goIdle];
		[[adium statusController] addStatusState:newStatus];
	}	
}

- (void)_importBuddies1:(NSArray *)buddyArray
	accountTranslations:(NSMutableDictionary *)accountUIDtoAccount
	  aliasTranslations:(NSMutableDictionary *)aliasToContacts
				toGroup:(NSString *)groupName
{
	AIContactController *contactController = [adium contactController];
	
	NSEnumerator *buddyEnum = [buddyArray objectEnumerator];
	NSDictionary *buddy = nil;
	while((buddy = [buddyEnum nextObject]) != nil)
	{
		NSString *buddyName = [buddy objectForKey:@"buddyname"];
		if([buddyName length] == 0)
			continue;
		
		NSDictionary *permissionsDict = [buddy objectForKey:@"BuddyPermissions"];
		NSMutableArray *accounts = [NSMutableArray array];
		if(permissionsDict != nil)
		{
			NSEnumerator *permissionsEnum = [permissionsDict keyEnumerator];
			NSString *accountKey = nil;
			while ((accountKey = [permissionsEnum nextObject]) != nil)
			{
				AIAccount *acct = [accountUIDtoAccount objectForKey:accountKey];
				if(acct != nil && [[[permissionsDict objectForKey:accountKey] objectForKey:@"BuddyinList"] boolValue])
					[accounts addObject:acct];
			}
		}
		else
		{
			NSEnumerator *acctEnum = [accountUIDtoAccount objectEnumerator];
			AIAccount *acct = nil;
			while ((acct = [acctEnum nextObject]) != nil)
			{
				if([[acct serviceClass] isEqualToString:[buddy objectForKey:@"service"]])
					[accounts addObject:acct];
			}
		}
		
		NSEnumerator *accountEnum = [accounts objectEnumerator];
		AIAccount *account = nil;
		while ((account = [accountEnum nextObject]) != nil)
		{
			AIListContact *newContact = [contactController contactWithService:[account service] account:account UID:buddyName];
			if(newContact == nil)
				continue;
			
			NSString *alias = [buddy objectForKey:@"displayname"];
			if([alias length] != 0)
			{
				[newContact setDisplayName:alias];
				NSMutableArray *contactArray = [aliasToContacts objectForKey:alias];
				if(contactArray == nil)
				{
					contactArray = [NSMutableArray array];
					[aliasToContacts setObject:contactArray forKey:alias];
				}
				[contactArray addObject:newContact];
			}
			
			if([groupName length] != 0)
				[newContact setRemoteGroupName:groupName];
		}
	}	
}

- (void)_importGroups1:(NSDictionary *)groupList
   accountTranslations:(NSMutableDictionary *)accountUIDtoAccount
	 aliasTranslations:(NSMutableDictionary *)aliasToContacts
{
	AIContactController *contactController = [adium contactController];
	
	//First itterate through the groups and create an array we can sort
	NSEnumerator *groupEnum = [groupList keyEnumerator];
	NSString *groupName = nil;
	NSMutableArray *groupArray = [NSMutableArray array];
	while((groupName = [groupEnum nextObject]) != nil)
	{
		NSMutableDictionary *groupDict = [[groupList objectForKey:groupName] mutableCopy];
		[groupDict setObject:groupName forKey:@"Name"];
		[groupArray addObject:groupDict];
		[groupDict release];
	}
	[groupArray sortUsingFunction:groupSort context:NULL];
	groupEnum = [groupArray objectEnumerator];
	NSDictionary *group = nil;
	while((group = [groupEnum nextObject]) != nil)
	{
		NSString *groupName = [group objectForKey:@"Name"];
		AIListGroup *newGroup = [contactController groupWithUID:groupName];
		NSNumber *expanded = [group objectForKey:@"groupexpanded"];
		if(expanded != nil)
			[newGroup setExpanded:[expanded boolValue]];
		[self _importBuddies1:[group objectForKey:@"buddies"]
							  accountTranslations:accountUIDtoAccount
								aliasTranslations:aliasToContacts
										  toGroup:groupName];
	}
}

- (BOOL)import1:(NSString *)fireDir
{
	NSString *configPath = [fireDir stringByAppendingPathComponent:FIRECONFIGURATION];
	NSString *accountPath = [fireDir stringByAppendingPathComponent:ACCOUNTS];
	NSDictionary *configDict = [NSDictionary dictionaryWithContentsOfFile:configPath];
	NSDictionary *accountDict = [NSDictionary dictionaryWithContentsOfFile:accountPath];
	
	if(configDict == nil || accountDict == nil)
		//no dictionary or no account, can't import
		return NO;
	
	NSMutableDictionary *accountUIDtoAccount = [NSMutableDictionary dictionary];
	
	//Start with accounts
	[self _importAccounts1:accountDict
			  translations:accountUIDtoAccount];
	
	//Away Messages
	[self _importAways1:[configDict objectForKey:@"awayMessages"]];
	
	//Now for the groups
	NSMutableDictionary *aliasToContacts = [NSMutableDictionary dictionary];
	[self _importGroups1:[configDict objectForKey:@"groups"]
	 accountTranslations:accountUIDtoAccount
	   aliasTranslations:aliasToContacts];
	
	//Persons
	[self createMetaContacts:aliasToContacts];
	
	return YES;
}

@end
