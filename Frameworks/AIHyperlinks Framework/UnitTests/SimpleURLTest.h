//
//  SimpleURLTest.h
//  AIHyperlinks.framework
//

#import <SenTestingKit/SenTestingKit.h>
#import "AIHyperlinks.h"

#define testHyperlink(x) STAssertTrue([scanner isStringValidURL: x ], nil)

@interface SimpleURLTest : SenTestCase {
	SHHyperlinkScanner	*scanner;
}
- (void)testURLOnly;
- (void)testURI;
- (void)testURIWithPaths;
- (void)testURIWithUserAndPass;
- (void)testIPAddressURI;
- (void)testIPv6URI;
- (void)testUniqueURI;
- (void)testEmailAddress;
- (void)testUserCases;
@end
