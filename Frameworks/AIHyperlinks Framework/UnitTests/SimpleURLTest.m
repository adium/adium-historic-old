//
//  SimpleURLTest.m
//  AIHyperlinks.framework
//
//  Created by Stephen Holt on 5/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SimpleURLTest.h"
#import "AIHyperlinks.h"

@implementation SimpleURLTest

- (void)testHyperlink:(NSString *)linkString {
	SHHyperlinkScanner	*scanner = [[SHHyperlinkScanner alloc] initWithStrictChecking:NO];
	
	STAssertTrue([scanner isStringValidURL:linkString], @"%@ is not a valid URL", linkString);
}
-(void) testSimpleDomain{
	[self testHyperlink:@"example.com"];
}

@end
