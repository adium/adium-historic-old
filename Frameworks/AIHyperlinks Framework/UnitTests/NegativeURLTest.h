//
//  NegativeURLTest.h
//  AIHyperlinks.framework
//

#import <SenTestingKit/SenTestingKit.h>
#import "AIHyperlinks.h"

#define testHyperlink(x) STAssertFalse([scanner isStringValidURL: x ], @"%@ is a valid URI and should not be", x)

@interface NegativeURLTest : SenTestCase {
	SHHyperlinkScanner	*scanner;
}

- (void)testInvalidURI;

@end
