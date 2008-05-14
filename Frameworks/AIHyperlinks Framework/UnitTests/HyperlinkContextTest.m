//
//  HyperlinkContextTest.m
//  AIHyperlinks.framework
//

#import "HyperlinkContextTest.h"
#import "AutoHyperlinks.h"

@implementation HyperlinkContextTest
- (void)testLaxContext:(NSString *)linkString withURI:(NSString *)URIString {
	AHHyperlinkScanner	*scanner = [[AHHyperlinkScanner alloc] initWithStrictChecking:NO];
	NSString			*testString = [NSString stringWithFormat:linkString, URIString];
	AHMarkedHyperlink	*link = [scanner nextURLFromString:testString];
	
	STAssertNotNil(link, @"-[SHHyperlinkScanner nextURLFromString:] found no URI in \"%@\"", testString);
	STAssertEqualObjects([[link parentString] substringWithRange:[link range]], URIString, @"in context: '%@'", testString);
}

- (void)testEnclosedURI:(NSString *)URIString {
	[self testLaxContext:@"<%@>" withURI:URIString];
	[self testLaxContext:@"(%@)" withURI:URIString];
	[self testLaxContext:@"[%@]" withURI:URIString];
}

- (void)testURIBorder:(NSString *)URIString {
	[self testLaxContext:@":%@" withURI:URIString];
	[self testLaxContext:@"%@:" withURI:URIString];
}

- (void)testSimpleDomain {
	[self testEnclosedURI:@"example.com"];
	[self testURIBorder:@"example.com"];
}

- (void)testEdgeURI {
	[self testEnclosedURI:@"example.com/foo_(bar)"];
	[self testURIBorder:@"example.com/foo_(bar)"];
	[self testEnclosedURI:@"http://example.com/foo_(bar)"];
	[self testURIBorder:@"http://example.com/foo_(bar)"];

	[self testLaxContext:@"<><><><><<<<><><><><%@><><><><><><<<><><><><><>" withURI:@"example.com"];
	[self testLaxContext:@"l<><><><><<<<><><><><%@><><><><><><<<><><><><><>" withURI:@"http://example.com/foo_(bar)"];

}
@end
