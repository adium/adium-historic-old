//
//  TestHyperlinkScanner.m
//  Adium
//
//  Created by Peter Hosey on 2008-04-03.
//  Copyright 2008 Peter Hosey. All rights reserved.
//

#import "TestHyperlinkScanner.h"

#import <AIHyperlinks/AIHyperlinks.h>

@implementation TestHyperlinkScanner

- (void)testGreaterThanBeforeString:(NSString *)suffix {
	SHHyperlinkScanner *scanner = [[SHHyperlinkScanner alloc] initWithStrictChecking:YES];
	SHMarkedHyperlink *link = [scanner nextURLFromString:[@"<http://adiumx.com/>" stringByAppendingString:suffix]];
	STAssertEqualObjects([link URL], [NSURL URLWithString:@"http://adiumx.com/"], @"-[SHHyperlinkScanner nextURLFromString:] must not include any characters that appear after the URL");
	[scanner release];
}

#pragma mark Test cases for http://trac.adiumx.com/ticket/7267

- (void)testGreaterThanBeforeFullStop {
	[self testGreaterThanBeforeString:@"."];
}
- (void)testGreaterThanBeforeExclamationMark {
	[self testGreaterThanBeforeString:@"!"];
}
- (void)testGreaterThanBeforeQuestionMark {
	[self testGreaterThanBeforeString:@"?"];
}
- (void)testGreaterThanBeforeLessThan {
	[self testGreaterThanBeforeString:@"<"];
}
- (void)testGreaterThanBeforeGreaterThan {
	[self testGreaterThanBeforeString:@">"];
}
- (void)testGreaterThanBeforeOpenParenthesis {
	[self testGreaterThanBeforeString:@"("];
}
- (void)testGreaterThanBeforeCloseParenthesis {
	[self testGreaterThanBeforeString:@")"];
}

@end
