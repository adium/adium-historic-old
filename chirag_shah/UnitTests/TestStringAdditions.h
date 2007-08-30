#import <Foundation/Foundation.h>
#import <SenTestingKit/SenTestingKit.h>

@interface TestStringAdditions: SenTestCase
{}

- (void)testRandomStringOfLength;
- (void)testStringWithContentsOfUTF8File;
- (void)testEllipsis;
- (void)testStringByAppendingEllipsis;
- (void)testCompactedString;
- (void)testStringWithEllipsisByTruncatingToLength;
- (void)testIdentityMethod;
- (void)testXMLEscaping;
- (void)testEscapingForShell;
- (void)testVolumePath;
- (void)testAllLinesWithSeparator;
- (void)testAllLines;

@end
