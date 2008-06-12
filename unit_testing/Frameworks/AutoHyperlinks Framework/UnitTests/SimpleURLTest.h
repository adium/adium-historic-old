//
//  SimpleURLTest.h
//  AIHyperlinks.framework
//

#import <SenTestingKit/SenTestingKit.h>
#import "AutoHyperlinks.h"

#define testHyperlink(x) STAssertTrue([scanner isStringValidURL: x ],\
					@"\"%@\" Should be a valid URI.", x )

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
- (void)testUserCases;
@end
