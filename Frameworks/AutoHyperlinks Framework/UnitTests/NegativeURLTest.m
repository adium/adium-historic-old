//
//  NegativeURLTest.m
//  AIHyperlinks.framework
//

#import "NegativeURLTest.h"

@implementation NegativeURLTest
- (void)setUp {
	scanner = [[AHHyperlinkScanner alloc] initWithStrictChecking:NO];
}

- (void)tearDown {
	[scanner release];
}

- (void)testInvalidURI {
	testHyperlink(@"adium");
	testHyperlink(@"http://");
	testHyperlink(@"example.co");
	testHyperlink(@"http://[::]");
	testHyperlink(@"http://[::1:]");
	testHyperlink(@"http://[1]");
	testHyperlink(@"http://[]");
	testHyperlink(@"http://example.not.a.tld");
	testHyperlink(@"http://example.not.a.tld:8080");
}
@end
