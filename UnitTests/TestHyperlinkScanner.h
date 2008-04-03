//
//  TestHyperlinkScanner.h
//  Adium
//
//  Created by Peter Hosey on 2008-04-03.
//  Copyright 2008 Peter Hosey. All rights reserved.
//

@interface TestHyperlinkScanner : SenTestCase
{}

#pragma mark Test cases for http://trac.adiumx.com/ticket/7267

- (void)testGreaterThanBeforeFullStop;
- (void)testGreaterThanBeforeExclamationMark;
- (void)testGreaterThanBeforeQuestionMark;
- (void)testGreaterThanBeforeLessThan;
- (void)testGreaterThanBeforeGreaterThan;
- (void)testGreaterThanBeforeOpenParenthesis;
- (void)testGreaterThanBeforeCloseParenthesis;

@end
