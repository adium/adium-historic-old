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
	testHyperlink(@"b.sc");
	testHyperlink(@"m.in");
	testHyperlink(@"test.not.a.tld");
	testHyperlink(@"http://[::]");
	testHyperlink(@"http://[::1:]");
	testHyperlink(@"http://[1]");
	testHyperlink(@"http://[]");
	testHyperlink(@"http://example.com/ is not a link");
	testHyperlink(@"jdoe@jabber.org/Adium");
}
@end
