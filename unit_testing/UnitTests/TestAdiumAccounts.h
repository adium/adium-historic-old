#import <SenTestingKit/SenTestingKit.h>
#import <AdiumAccounts.h>


@interface testAdiumAccounts : SenTestCase {
	AdiumAccounts* adiumAccounts;
}

- (void)testControllerDidLoad;

//Accounts
- (void)testAccounts;
- (void)testAccountsCompatibleWithService;
- (void)testAccountWithInternalObjectID;

//Editing
- (void)testCreateAccountWithService_UID;
- (void)testAddAccount;
- (void)testDeleteAccount;
- (void)testMoveAccount_toIndex;
- (void)testAccountDidChangeUID;

@end
