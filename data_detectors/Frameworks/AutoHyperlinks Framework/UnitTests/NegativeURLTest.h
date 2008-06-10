//
//  NegativeURLTest.h
//  AIHyperlinks.framework
//

#import <SenTestingKit/SenTestingKit.h>
#import "AutoHyperlinks.h"

#define testHyperlink(x) STAssertFalse([scanner isStringValidURL: x ], @"%@ is a valid URI and should not be", x)

@interface NegativeURLTest : SenTestCase {
	AHHyperlinkScanner	*scanner;
}

- (void)testInvalidURI;

@end
