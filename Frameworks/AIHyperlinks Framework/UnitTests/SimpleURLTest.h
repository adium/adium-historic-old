//
//  SimpleURLTest.h
//  AIHyperlinks.framework
//
//  Created by Stephen Holt on 5/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>


@interface SimpleURLTest : SenTestCase {
}
- (void)testURLOnly;
- (void)testURI;
- (void)testURIWithPaths;
- (void)testURIWithUserAndPass;
- (void)testIPAddressURI;
//- (void)testIPv6URI;
- (void)testEmailAddress;
@end
