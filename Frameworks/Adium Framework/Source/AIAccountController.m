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

// $Id$

#import "AIAccountController.h"
#import "AIContactController.h"
#import "AIContentController.h"
#import "AILoginController.h"
#import "AIPreferenceController.h"
#import "AIStatusController.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIObjectAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIService.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIStatusIcons.h>
#import "AdiumServices.h"
#import "AdiumPasswords.h"
#import "AdiumAccounts.h"
#import "AdiumPreferredAccounts.h"

#define ACCOUNT_DEFAULT_PREFS			@"AccountPrefs"

@implementation AIAccountController

//init
- (id)init
{
	if ((self = [super init])) {
		adiumServices = [[AdiumServices alloc] init];
		adiumPasswords = [[AdiumPasswords alloc] init];
		adiumAccounts = [[AdiumAccounts alloc] init];
		adiumPreferredAccounts = [[AdiumPreferredAccounts alloc] init];
	}
	
	return self;
}

//Finish initialization once other controllers have set themselves up
- (void)controllerDidLoad
{   
	//Default account preferences
	[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:ACCOUNT_DEFAULT_PREFS forClass:[self class]]
										  forGroup:PREF_GROUP_ACCOUNTS];
	
	//Finish prepping the accounts
	[adiumAccounts controllerDidLoad];
}

//close
- (void)controllerWillClose
{
    //Disconnect all accounts
    [self disconnectAllAccounts];
}

- (void)dealloc
{
	[adiumServices release];
	[adiumPasswords release];
	[adiumAccounts release];
	[adiumPreferredAccounts release];

	[super dealloc];
}

//Services
#pragma mark Services
- (void)registerService:(AIService *)inService {
	[adiumServices registerService:inService];
}
- (NSArray *)services {
	return [adiumServices services];
}
- (NSSet *)activeServicesIncludingCompatibleServices:(BOOL)includeCompatible {
	return [adiumServices activeServicesIncludingCompatibleServices:includeCompatible];
}
- (AIService *)serviceWithUniqueID:(NSString *)uniqueID {
	return [adiumServices serviceWithUniqueID:uniqueID];
}
- (AIService *)firstServiceWithServiceID:(NSString *)serviceID {
	return [adiumServices firstServiceWithServiceID:serviceID];
}

//Passwords
#pragma mark Passwords
- (void)setPassword:(NSString *)inPassword forAccount:(AIAccount *)inAccount {
	[adiumPasswords setPassword:inPassword forAccount:inAccount];
}
- (void)forgetPasswordForAccount:(AIAccount *)inAccount {
	[adiumPasswords forgetPasswordForAccount:inAccount];
}
- (NSString *)passwordForAccount:(AIAccount *)inAccount {
	return [adiumPasswords passwordForAccount:inAccount];
}
- (void)passwordForAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext {
	[adiumPasswords passwordForAccount:inAccount notifyingTarget:inTarget selector:inSelector context:inContext];
}
- (void)setPassword:(NSString *)inPassword forProxyServer:(NSString *)server userName:(NSString *)userName {
	[adiumPasswords setPassword:inPassword forProxyServer:server userName:userName];
}
- (NSString *)passwordForProxyServer:(NSString *)server userName:(NSString *)userName {
	return [adiumPasswords passwordForProxyServer:server userName:userName];
}
- (void)passwordForProxyServer:(NSString *)server userName:(NSString *)userName notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext {
	[adiumPasswords passwordForProxyServer:server userName:userName notifyingTarget:inTarget selector:inSelector context:inContext];
}

//Accounts
#pragma mark Accounts
- (NSArray *)accounts {
	return [adiumAccounts accounts];
}
- (NSArray *)accountsCompatibleWithService:(AIService *)service {
	return [adiumAccounts accountsCompatibleWithService:service];
}
- (AIAccount *)accountWithInternalObjectID:(NSString *)objectID {
	return [adiumAccounts accountWithInternalObjectID:objectID];
}
- (AIAccount *)createAccountWithService:(AIService *)service UID:(NSString *)inUID {
	return [adiumAccounts createAccountWithService:service UID:inUID];
}
- (void)addAccount:(AIAccount *)inAccount {
	[adiumAccounts addAccount:inAccount];
}
- (void)deleteAccount:(AIAccount *)inAccount {
	[adiumAccounts deleteAccount:inAccount];
}
- (int)moveAccount:(AIAccount *)account toIndex:(int)destIndex {
	return [adiumAccounts moveAccount:account toIndex:destIndex];
}
- (void)accountDidChangeUID:(AIAccount *)inAccount {
	[adiumAccounts accountDidChangeUID:inAccount];
}

//Preferred Accounts
#pragma mark Preferred Accounts
- (AIAccount *)preferredAccountForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact {
	return [adiumPreferredAccounts preferredAccountForSendingContentType:inType toContact:inContact];
}
- (AIAccount *)preferredAccountForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact includeOffline:(BOOL)includeOffline {
	return [adiumPreferredAccounts preferredAccountForSendingContentType:inType toContact:inContact includeOffline:includeOffline];
}
- (AIAccount *)firstAccountAvailableForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact includeOffline:(BOOL)includeOffline {
	return [adiumPreferredAccounts firstAccountAvailableForSendingContentType:inType toContact:inContact includeOffline:includeOffline];
}

- (void)disconnectAllAccounts
{
    NSEnumerator		*enumerator;
    AIAccount			*account;

    enumerator = [[self accounts] objectEnumerator];
    while ((account = [enumerator nextObject])) {
        if ([account online]) 
			[account disconnect];
    }
}

//XXX - Re-evaluate this method and its presence in the core
- (BOOL)oneOrMoreConnectedAccounts
{
	NSEnumerator		*enumerator;
    AIAccount			*account;

    enumerator = [[self accounts] objectEnumerator];
    while ((account = [enumerator nextObject])) {
        if ([account online]) {
			return YES;
        }
    }
	
	return NO;
}

//XXX - Re-evaluate this method and its presence in the core
- (BOOL)oneOrMoreConnectedOrConnectingAccounts
{
	NSEnumerator		*enumerator;
    AIAccount			*account;
	
    enumerator = [[self accounts] objectEnumerator];
    while ((account = [enumerator nextObject])) {
        if ([account online] || [account integerStatusObjectForKey:@"Connecting"]) {
			return YES;
        }
    }	

	return NO;	
}

@end

@implementation AIAccountController (AIAccountControllerObjectSpecifier)
- (NSScriptObjectSpecifier *) objectSpecifier {
	id classDescription = [NSClassDescription classDescriptionForClass:[NSApplication class]];
	NSScriptObjectSpecifier *container = [[NSApplication sharedApplication] objectSpecifier];
	return [[[NSPropertySpecifier alloc] initWithContainerClassDescription:classDescription containerSpecifier:container key:@"accountController"] autorelease];
}
@end
