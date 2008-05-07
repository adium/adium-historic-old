//
//  TestAdiumAccounts.m
//  Adium
//
//  Created by BJ Homer on 5/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "testAdiumAccounts.h"
#import "AIAdiumProtocol.h"
#import "OCMock/OCMockObject.h"

@implementation testAdiumAccounts

- (void)setUp {
	id mock = [OCMockObject mockForProtocol:@protocol(AIAdium)];
	[AIObject _setSharedAdiumInstance:mock];
	adiumAccounts = [[AdiumAccounts alloc] init];
}

- (void)tearDown {
	[adiumAccounts release];
	adiumAccounts = nil;
}


- (void)testControllerDidLoad {
}


#pragma mark Accounts

- (void)testAccounts {
	STAssertEqualObjects([adiumAccounts accounts], [[NSArray alloc] init], @"accounts should have no items by default");
};

- (void)testAccountsCompatibleWithService {}
- (void)testAccountWithInternalObjectID {}

#pragma mark Editing
- (void)testCreateAccountWithService_UID {}
- (void)testAddAccount {}
- (void)testDeleteAccount { }
- (void)testMoveAccount_toIndex {}
- (void)testAccountDidChangeUID {}


@end
