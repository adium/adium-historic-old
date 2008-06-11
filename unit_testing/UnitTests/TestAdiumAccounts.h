#import <SenTestingKit/SenTestingKit.h>
#import <AdiumAccounts.h>


@interface TestAdiumAccounts : SenTestCase {
	AdiumAccounts* adiumAccounts;
	
	id googleService;
	id yahooService;
	id aimService;
	
	id googleAccount;
	id googleAccount2;
	id aimAccount;
	id permAccount;
}

- (void)testControllerDidLoad;

//Accounts
- (void)testEmptyAccounts;
- (void)testAccountsCompatibleWithService;
- (void)testAccountWithInternalObjectID;

//Editing
- (void)testCreateAccountWithService_UID;
- (void)testAddAccounts;
- (void)testDeleteAccount;
- (void)testMoveAccount_toIndex;
- (void)testSaveAccounts;
- (void)testLoadAccounts;
- (void)testLoadAccountsWhenEmpty;

@end
