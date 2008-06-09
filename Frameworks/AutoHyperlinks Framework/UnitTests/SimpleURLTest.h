//
//  SimpleURLTest.h
//  AIHyperlinks.framework
//

#import <SenTestingKit/SenTestingKit.h>
#import "AutoHyperlinks.h"

#define testHyperlink(x) STAssertTrue([scanner isStringValidURL: x ], nil)

@interface SimpleURLTest : SenTestCase {
	AHHyperlinkScanner	*scanner;
}
- (void)testURLOnly;
- (void)testURI;
- (void)testURIWithPaths;
- (void)testURIWithUserAndPass;
- (void)testIPAddressURI;
- (void)testIPv6URI;
- (void)testUniqueURI;
- (void)testEmailAddress;
- (void)testJID;
- (void)testUserCases;
@end
