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



@implementation TestAdiumAccounts

- (void)setUp {
	
	
	id aiMock = [OCMockObject niceMockForProtocol:@protocol(AIAdium)];
	[AIObject _setSharedAdiumInstance:aiMock];
	
	googleService = [OCMockObject mockForClass:[AIService class]];
	[[[googleService stub] andReturn:@"Google"] serviceClass];	
	
	yahooService = [OCMockObject mockForClass:[AIService class]];
	[[[yahooService stub] andReturn:@"Yahoo"] serviceClass];
	
	aimService = [OCMockObject mockForClass:[AIService class]];
	[[[aimService stub] andReturn:@"AIM"] serviceClass];
	
	// Must to be a variable for the OCMOCK_VALUE macro to work
	BOOL yes = YES;
	
	googleAccount = [OCMockObject niceMockForClass:[AIAccount class]];
	[[[googleAccount stub] andReturnValue:OCMOCK_VALUE(yes)] isTemporary];
	[[[googleAccount stub] andReturnValue:OCMOCK_VALUE(yes)] enabled];
	[[[googleAccount stub] andReturn:googleService] service];
	
	googleAccount2 = [OCMockObject niceMockForClass:[AIAccount class]];
	[[[googleAccount2 stub] andReturnValue:OCMOCK_VALUE(yes)] isTemporary];
	[[[googleAccount2 stub] andReturnValue:OCMOCK_VALUE(yes)] enabled];
	[[[googleAccount2 stub] andReturn:googleService] service];
	
	aimAccount = [OCMockObject niceMockForClass:[AIAccount class]];
	[[[aimAccount stub] andReturnValue:OCMOCK_VALUE(yes)] isTemporary];
	[[[aimAccount stub] andReturnValue:OCMOCK_VALUE(yes)] enabled];
	[[[aimAccount stub] andReturn:aimService] service];
	
	adiumAccounts = [[AdiumAccounts alloc] init];
}

- (void)tearDown {
	[adiumAccounts release];
	adiumAccounts = nil;
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
	
	NSMutableArray* googleCorrectAnswer = [NSMutableArray array];
	[googleCorrectAnswer addObject:googleAccount];
	[googleCorrectAnswer addObject:googleAccount2];
	
	NSArray* googleAnswer = [adiumAccounts accountsCompatibleWithService:googleService];
	
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
- (void)testCreateAccountWithService_UID {}


- (void)testAddAccounts {
		
	[adiumAccounts addAccount:googleAccount];
	[adiumAccounts addAccount:googleAccount2];
	[adiumAccounts addAccount:aimAccount];
	
	id accounts = [adiumAccounts accounts];
	
	NSMutableArray* correctAccounts = [NSMutableArray array];
	[correctAccounts addObject:googleAccount];
	[correctAccounts addObject:googleAccount2];
	[correctAccounts addObject:aimAccount];
	
	STAssertEqualObjects(accounts,
						 correctAccounts,
						 @"Should have added three accounts");
}


- (void)testDeleteAccount { }
- (void)testMoveAccount_toIndex {}
- (void)testAccountDidChangeUID {}


@end
