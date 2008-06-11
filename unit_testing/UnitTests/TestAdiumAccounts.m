//
//  TestAdiumAccounts.m
//  Adium
//
//  Created by BJ Homer on 5/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TestAdiumAccounts.h"
#import "AIAdiumProtocol.h"
#import "OCMock/OCMock.h"
#import <Adium/AIService.h>
#import <Adium/AIAccount.h>
#import <AIPreferenceController.h>
#import <AIAccountController.h>



@implementation TestAdiumAccounts

- (void)setUp {
	id aiMock = [OCMockObject niceMockForProtocol:@protocol(AIAdium)];
	[AIObject _setSharedAdiumInstance:aiMock];
	
	googleService = [[OCMockObject mockForClass:[AIService class]] retain];
	[[[googleService stub] andReturn:@"Jabber"] serviceClass];	
	[[[googleService stub] andReturn:@"libpurple-Jabber"] serviceCodeUniqueID];
	[[[googleService stub] andReturn:@"Jabber"] serviceID];
	
	yahooService = [[OCMockObject mockForClass:[AIService class]] retain];
	[[[yahooService stub] andReturn:@"Yahoo"] serviceClass];
	
	aimService = [[OCMockObject mockForClass:[AIService class]] retain];
	[[[aimService stub] andReturn:@"AIM"] serviceClass];
	
	// Must to be a variable for the OCMOCK_VALUE macro to work
	BOOL yes = YES;
	BOOL no = NO;
	
	googleAccount = [[OCMockObject niceMockForClass:[AIAccount class]] retain];
	[[[googleAccount stub] andReturnValue:OCMOCK_VALUE(yes)] isTemporary];
	[[[googleAccount stub] andReturnValue:OCMOCK_VALUE(yes)] enabled];
	[[[googleAccount stub] andReturn:googleService] service];
	
	
	googleAccount2 = [[OCMockObject niceMockForClass:[AIAccount class]] retain];
	[[[googleAccount2 stub] andReturnValue:OCMOCK_VALUE(yes)] isTemporary];
	[[[googleAccount2 stub] andReturnValue:OCMOCK_VALUE(yes)] enabled];
	[[[googleAccount2 stub] andReturn:googleService] service];
	
	aimAccount = [[OCMockObject niceMockForClass:[AIAccount class]] retain];
	[[[aimAccount stub] andReturnValue:OCMOCK_VALUE(yes)] isTemporary];
	[[[aimAccount stub] andReturnValue:OCMOCK_VALUE(yes)] enabled];
	[[[aimAccount stub] andReturn:aimService] service];
	
	permAccount = [[OCMockObject mockForClass:[AIAccount class]] retain];
	[[[permAccount stub] andReturnValue:OCMOCK_VALUE(no)] isTemporary];
	[[[permAccount stub] andReturnValue:OCMOCK_VALUE(yes)] enabled];
	[[[permAccount stub] andReturn:googleService] service];
	[[[permAccount stub] andReturn:@"permUID"] UID];
	[[[permAccount stub] andReturn:@"permObjID"] internalObjectID];
	
	adiumAccounts = [[AdiumAccounts alloc] init];
}

- (void)tearDown {
	[adiumAccounts release];
	
	[googleService release];
	[aimService release];
	[yahooService release];
	
	[googleAccount release];
	[googleAccount2 release];
	[aimAccount release];
	[permAccount release];
}


- (void)testControllerDidLoad {
}


#pragma mark Accounts

- (void)testEmptyAccounts {
	STAssertEqualObjects([adiumAccounts accounts], 
						 [[NSArray alloc] init],
						 @"Accounts should have no items by default");
}


- (void)testAccountsCompatibleWithService {
	
	[adiumAccounts addAccount:googleAccount];
	[adiumAccounts addAccount:googleAccount2];
	[adiumAccounts addAccount:aimAccount];
	
	NSMutableArray *googleCorrectAnswer = [NSMutableArray array];
	[googleCorrectAnswer addObject:googleAccount];
	[googleCorrectAnswer addObject:googleAccount2];
	
	NSArray *googleAnswer = [adiumAccounts accountsCompatibleWithService:googleService];
	
	STAssertTrue([googleCorrectAnswer isEqualToArray:googleAnswer],
						 @"Expected two accounts");

}


- (void)testAccountWithInternalObjectID {
	
	[[[googleAccount stub] andReturn:@"123"] internalObjectID];
	[[[googleAccount2 stub] andReturn:@"12345"] internalObjectID];
	
	[adiumAccounts addAccount:googleAccount];
	[adiumAccounts addAccount:googleAccount2];
	
	id answer = [adiumAccounts accountWithInternalObjectID:@"12345"];
	
	STAssertEqualObjects(answer,
						 googleAccount2,
						 @"Expected googleAccount2, got %@", answer);
	
	answer = [adiumAccounts accountWithInternalObjectID:@"123"];
	
	STAssertEqualObjects(answer,
						 googleAccount,
						 @"Expected googleAccount, got %@", answer);
	
	answer = [adiumAccounts accountWithInternalObjectID:@"ABC"];
	
	STAssertNil(answer,
				@"Expected nil, got %@.  No account with ID \"ABC\" was added", answer);
	
}

#pragma mark Editing
- (void)testCreateAccountWithService_UID {
	[[aimService expect] accountWithUID:@"myUID" internalObjectID:OCMOCK_ANY];
	[[aimService expect] accountWithUID:@"otherUID" internalObjectID:OCMOCK_ANY];
	
	[adiumAccounts createAccountWithService:aimService UID:@"myUID"];
	[adiumAccounts createAccountWithService:aimService UID:@"otherUID"];
	
	[aimService verify];
}


- (void)testAddAccounts {
		
	[adiumAccounts addAccount:googleAccount];
	[adiumAccounts addAccount:googleAccount2];
	[adiumAccounts addAccount:aimAccount];
	[adiumAccounts addAccount:aimAccount];
	
	id accounts = [adiumAccounts accounts];
	
	NSMutableArray *correctAccounts = [NSMutableArray arrayWithObjects:googleAccount, 
									                                   googleAccount2, 
									                                   aimAccount, 
									                                   aimAccount, nil];
	
	STAssertEqualObjects(accounts,  correctAccounts,
						 @"Should have added four accounts");
	
	STAssertEquals([accounts count], (unsigned int) 4, 
				   @"Duplicate accounts were not added.");

}


- (void)testDeleteAccount { 

	[adiumAccounts addAccount:googleAccount];
	[adiumAccounts addAccount:googleAccount2];
	[adiumAccounts addAccount:aimAccount];
	[adiumAccounts addAccount:aimAccount];
	
	[adiumAccounts deleteAccount:googleAccount];
	
	NSArray *correct = [NSMutableArray arrayWithObjects:googleAccount2, aimAccount, aimAccount, nil];
	
	STAssertEqualObjects([adiumAccounts accounts], correct,
						 @"Single account was not correctly deleted");
	
	[adiumAccounts deleteAccount:aimAccount];
	
	correct = [NSArray arrayWithObjects:googleAccount2, nil];
	
	STAssertEqualObjects([adiumAccounts accounts], correct,
						 @"Duplicate account should have deleted all instances");
	
	STAssertNoThrow([adiumAccounts deleteAccount:aimAccount],
					@"Should fail silelently when deleting an already-removed account");
}



- (void)testMoveAccount_toIndex {
	[[[aimAccount stub] andReturn:@"aimAccount"] description];
	
	[adiumAccounts addAccount:googleAccount];
	[adiumAccounts addAccount:aimAccount];
	
	NSArray *correct = [NSArray arrayWithObjects:googleAccount, aimAccount, nil];
	STAssertTrue([[adiumAccounts accounts] isEqualToArray:correct],
				 @"Accounts should be held in the same order they were added");
	
	[adiumAccounts moveAccount:googleAccount toIndex:1];
	correct = [NSArray arrayWithObjects:aimAccount, googleAccount, nil];
	STAssertTrue([[adiumAccounts accounts] isEqualToArray:correct],
				 @"Accounts were not rearranged");
	
	[adiumAccounts moveAccount:aimAccount toIndex:0];
	STAssertTrue([[adiumAccounts accounts] isEqualToArray:correct],
				 @"Accounts were rearranged when index was equal to current position");

	STAssertThrows([adiumAccounts moveAccount:aimAccount toIndex:2],
				   @"Did not throw an exception on index one too high");
	
	
	STAssertThrows([adiumAccounts moveAccount:aimAccount toIndex:-5],
				   @"Did not throw an exception on negative index");
	

	


}


- (void)testGenerateUniqueObjectID {}

- (void)testSaveAccounts {
	// Special setup for shared Preference Controller expectations
	id aiPrefControllerMock = [OCMockObject mockForProtocol:@protocol(AIPreferenceController)];
	id dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"permObjID", @"ObjectID",
					                                           @"Jabber", @"Service", 
					                                           @"libpurple-Jabber", @"Type", 
					                                           @"permUID", @"UID", nil];
	id correctArray = [NSArray arrayWithObjects:dictionary, nil];
	[[aiPrefControllerMock expect] setPreference:correctArray forKey:@"Accounts" group:@"Accounts"];
	[[aiPrefControllerMock expect] setPreference:correctArray forKey:@"Accounts" group:@"Accounts"];
	
	// Special setup for shared Notification Center expectations
	id aiNotifyCenterMock = [OCMockObject mockForClass:[NSNotificationCenter class]];
	[[aiNotifyCenterMock expect] postNotificationName:@"Account_ListChanged" object:nil userInfo:nil];
	[[aiNotifyCenterMock expect] postNotificationName:@"Account_ListChanged" object:nil userInfo:nil];
	
	// Tell shared adium instance to return our special controllers
	id aiMock = [OCMockObject mockForProtocol:@protocol(AIAdium)];
	[[[aiMock stub] andReturn:aiPrefControllerMock] preferenceController];
	[[[aiMock stub] andReturn:aiNotifyCenterMock] notificationCenter];
	[AIObject _setSharedAdiumInstance:aiMock];
	[adiumAccounts release];
	adiumAccounts = [[AdiumAccounts alloc] init];
	

	// addAccount: calls _saveAccount
	[adiumAccounts addAccount:permAccount];
	
	// Right now, accountDidChangeUID: just saves the new UID.  Might as well test it while we're here.
	// If that method changes to have more interesting functionality, this should be moved into its own test.
	[adiumAccounts accountDidChangeUID:permAccount];

	[aiPrefControllerMock verify];
	[aiNotifyCenterMock verify];
}

- (void)testLoadAccounts {
	// Preference Controller...
	id aiPrefControllerMock = [OCMockObject mockForProtocol:@protocol(AIPreferenceController)];
	
	NSDictionary *aimDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"aimAccountID", @"ObjectID",
					                                                         @"AIM", @"Service", 
					                                                         @"libpurple-oscar-AIM", @"Type", 
					                                                         @"aimAccountUID", @"UID", nil];
	
	NSDictionary *googleDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"googleAccountID", @"ObjectID",
									                                            @"Jabber", @"Service", 
									                                            @"libpurple-Jabber", @"Type", 
									                                            @"googleAccountUID", @"UID", nil];
	
	NSArray *accountArray = [NSArray arrayWithObjects:aimDictionary, googleDictionary, nil];
	[[[aiPrefControllerMock stub] andReturn:accountArray] preferenceForKey:@"Accounts" group:PREF_GROUP_ACCOUNTS];
	
	
	// Account Controller...
	id aiAccountControllerMock = [OCMockObject mockForProtocol:@protocol(AIAccountController)];
	
	[[[aimService stub] andReturn:aimAccount] accountWithUID:@"aimAccountUID" internalObjectID:@"aimAccountID"];
	[[[googleService stub] andReturn:googleAccount] accountWithUID:@"googleAccountUID" internalObjectID:@"googleAccountID"];
	
	[[[aiAccountControllerMock stub] andReturn:aimService] serviceWithUniqueID:@"libpurple-oscar-AIM"];
	[[[aiAccountControllerMock stub] andReturn:googleService] serviceWithUniqueID:@"libpurple-Jabber"];
	
	// Special setup for shared Notification Center expectations
	id aiNotifyCenterMock = [OCMockObject mockForClass:[NSNotificationCenter class]];
	[[aiNotifyCenterMock expect] postNotificationName:@"Account_ListChanged" object:nil userInfo:nil];
	
	
	id aiMock = [OCMockObject mockForProtocol:@protocol(AIAdium)];
	[[[aiMock stub] andReturn:aiPrefControllerMock] preferenceController];
	[[[aiMock stub] andReturn:aiAccountControllerMock] accountController];
	[[[aiMock stub] andReturn:aiNotifyCenterMock] notificationCenter];
	[AIObject _setSharedAdiumInstance:aiMock];
	[adiumAccounts release];
	adiumAccounts = [[AdiumAccounts alloc] init];
	
	[adiumAccounts performSelector:@selector(_loadAccounts)];
	
	NSArray *correctArray = [NSArray arrayWithObjects:aimAccount, googleAccount, nil];
	
	STAssertTrue([[adiumAccounts accounts] isEqualToArray:correctArray], 
				 @"Accounts were not loaded correctly");
	
	[aiNotifyCenterMock verify];
}


- (void)testLoadAccountsWhenEmpty {
	
	STAssertTrue([[adiumAccounts accounts] isEqualToArray:[NSArray array]], 
				 @"Accounts should initially be empty");
	
	// Preference Controller...
	id aiPrefControllerMock = [OCMockObject mockForProtocol:@protocol(AIPreferenceController)];
	NSArray *accountArray = [NSArray array];
	[[[aiPrefControllerMock stub] andReturn:accountArray] preferenceForKey:@"Accounts" group:PREF_GROUP_ACCOUNTS];
	
	
	// Account Controller...
	id aiAccountControllerMock = [OCMockObject mockForProtocol:@protocol(AIAccountController)];
	[[[aiAccountControllerMock stub] andReturn:aimService] serviceWithUniqueID:@"libpurple-oscar-AIM"];
	[[[aiAccountControllerMock stub] andReturn:googleService] serviceWithUniqueID:@"libpurple-Jabber"];
	
	
	// We're going to do a negative assertion. We watch for calls to Account_ListChanged and fail on them.
	id aiNotifyCenterMock = [OCMockObject mockForClass:[NSNotificationCenter class]];
	[[aiNotifyCenterMock expect] postNotificationName:Account_ListChanged object:nil userInfo:nil];
	
	id aiMock = [OCMockObject mockForProtocol:@protocol(AIAdium)];
	[[[aiMock stub] andReturn:aiPrefControllerMock] preferenceController];
	[[[aiMock stub] andReturn:aiAccountControllerMock] accountController];
	[[[aiMock stub] andReturn:aiNotifyCenterMock] notificationCenter];
	[AIObject _setSharedAdiumInstance:aiMock];
	[adiumAccounts release];
	adiumAccounts = [[AdiumAccounts alloc] init];
	
	// Let's do it!
	[adiumAccounts performSelector:@selector(_loadAccounts)];
	
	NSArray *correctArray = [NSArray array];
	
	STAssertTrue([[adiumAccounts accounts] isEqualToArray:correctArray], 
				 @"Accounts were loaded when none should have been loaded");
	
	// No notification should have been received, since the list did not change
	STAssertThrows([aiNotifyCenterMock verify],
				   @"Notification Center received \"postNotificationName:Account_ListChanged\".  \
				   No notification should have been received, since the account list did not change");
}

@end
