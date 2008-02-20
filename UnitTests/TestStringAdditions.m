#import "TestStringAdditions.h"
#import "AIUnitTestUtilities.h"

#import <AIUtilities/AIStringAdditions.h>

@implementation TestStringAdditions

- (void)testRandomStringOfLength
{
	//Test at least two different lengths, and see what happens when we ask for 0.
	NSString *str = [NSString randomStringOfLength:6];
	STAssertEquals([str length], 6U, @"+randomStringOfLength:6 did not return a 6-character string; it returned \"%@\", which is %u characters", str, [str length]);
	str = [NSString randomStringOfLength:12];
	STAssertEquals([str length], 12U, @"+randomStringOfLength:12 did not return a 12-character string; it returned \"%@\", which is %u characters", str, [str length]);
	str = [NSString randomStringOfLength:0];
	STAssertEquals([str length], 0U, @"+randomStringOfLength:0 did not return a 0-character string; it returned \"%@\", which is %u characters", str, [str length]);
}
- (void)testStringWithContentsOfUTF8File
{
	//Our octest file contains a sample file to read in testing this method.
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *pathToFile = [bundle pathForResource:@"UTF8Snowman" ofType:@"txt"];

	char snowmanUTF8[4] = { 0xe2, 0x98, 0x83, 0 };
	NSString *snowman = [NSString stringWithUTF8String:snowmanUTF8];
	NSString *snowmanFromFile = [NSString stringWithContentsOfUTF8File:pathToFile];
	AISimplifiedAssertEqualObjects(snowman, snowmanFromFile, @"+stringWithContentsOfUTF8File: incorrectly read the file");
}
- (void)testEllipsis
{
	STAssertEquals([[NSString ellipsis] length], 1U, @"+ellipsis did not return a 1-character string; it returned \"%@\"", [NSString ellipsis]);
	STAssertEquals((unsigned int)[[NSString ellipsis] characterAtIndex:0U], 0x2026U, @"+ellipsis did not return a horizontal ellipsis (U+2026); it returned \"%@\" instead", [NSString ellipsis]);
}
- (void)testStringByAppendingEllipsis
{
	NSString *before = @"Foo";
	NSString *after  = [before stringByAppendingEllipsis];
	STAssertEquals(([after length] - [before length]), 1U, @"Appending a single character should result in a string that is one character longer. before is \"%@\"; after is \"%@\"", before, after);
	STAssertTrue([after hasSuffix:[NSString ellipsis]], @"String formed by appending [NSString ellipsis] should end with [NSString ellipsis]. before is \"%@\"; after is \"%@\"", before, after);
}
- (void)testCompactedString
{
	AISimplifiedAssertEqualObjects([@"FOO" compactedString], @"foo", @"-compactedString should lowercase an all-uppercase string");
	AISimplifiedAssertEqualObjects([@"Foo" compactedString], @"foo", @"-compactedString should lowercase a mixed-case string");
	AISimplifiedAssertEqualObjects([@"foo" compactedString], @"foo", @"-compactedString should do nothing to an all-lowercase string");
	AISimplifiedAssertEqualObjects([@"foo bar" compactedString], @"foobar", @"-compactedString should remove spaces");
}
- (void)testStringWithEllipsisByTruncatingToLength
{
	NSString *before = @"Foo";
	NSString *after;

	//First, try truncating to a greater length.
	after = [before stringWithEllipsisByTruncatingToLength:[before length] + 1];
	STAssertEqualObjects(before, after, @"Truncating to a length greater than that of the string being truncated should not change the string. before is \"%@\"; after is \"%@\"", before, after);

	//Second, try truncating to the same length.
	after = [before stringWithEllipsisByTruncatingToLength:[before length]];
	STAssertEqualObjects(before, after, @"Truncating to a length equal to that of the string being truncated should not change the string. before is \"%@\"; after is \"%@\"", before, after);

	//Third, try truncating to a shorter length. This one should actually truncate the string and append an ellipsis.
	after = [before stringWithEllipsisByTruncatingToLength:[before length] - 1];
	STAssertEquals(([before length] - [after length]), 1U, @"Appending a single character should result in a string that is one character longer. before is \"%@\"; after is \"%@\"", before, after);
	//The part before the ellipsis in after should be equal to the same portion of before.
	unsigned cutHere = [after length] - 1;
	STAssertEqualObjects([after  substringToIndex:cutHere - 1],
	                     [before substringToIndex:cutHere - 1],
						 @"Truncating a string should not result in any changes before the truncation point before is \"%@\"; after is \"%@\"", before, after);
	STAssertTrue([after hasSuffix:[NSString ellipsis]], @"String formed by appending [NSString ellipsis] should end with [NSString ellipsis]. before is \"%@\"; after is \"%@\"", before, after);
}
- (void)testIdentityMethod
{
	NSString *str = @"Foo";
	STAssertEquals([str string], str, @"A method that returns itself must, by definition, return itself.");
}
- (void)testXMLEscaping
{
	NSString *originalXMLSource = @"<rel-date><number>Four score</number> &amp; <number>seven</number> years ago</rel-date>";
	NSString *escaped = [originalXMLSource stringByEscapingForXMLWithEntities:nil];
	NSString *unescaped = [escaped stringByUnescapingFromXMLWithEntities:nil];
	STAssertEqualObjects(originalXMLSource, unescaped, @"Round trip through scaping + unescaping did not preserve the original string.");
}
- (void)testEscapingForShell
{
	//Whitespace should be replaced by '\' followed by a character (one of [atnfr] for most of them; space simply puts a \ in front of the space).
	STAssertEqualObjects([@"\a" stringByEscapingForShell], @"\\a", @"-stringByEscapingForShell didn't properly escape the alert (bell) character");
	STAssertEqualObjects([@"\t" stringByEscapingForShell], @"\\t", @"-stringByEscapingForShell didn't properly escape the horizontal tab character");
	STAssertEqualObjects([@"\n" stringByEscapingForShell], @"\\n", @"-stringByEscapingForShell didn't properly escape the line-feed character");
	STAssertEqualObjects([@"\v" stringByEscapingForShell], @"\\v", @"-stringByEscapingForShell didn't properly escape the vertical tab character");
	STAssertEqualObjects([@"\f" stringByEscapingForShell], @"\\f", @"-stringByEscapingForShell didn't properly escape the form-feed character");
	STAssertEqualObjects([@"\r" stringByEscapingForShell], @"\\r", @"-stringByEscapingForShell didn't properly escape the carriage-return character");
	STAssertEqualObjects([@" "  stringByEscapingForShell], @"\\ ", @"-stringByEscapingForShell didn't properly escape the space character");

	//Other unsafe characters are simply backslash-escaped.
	STAssertEqualObjects([@"\\" stringByEscapingForShell], @"\\\\", @"-stringByEscapingForShell didn't properly escape the alert (bell) character");
	STAssertEqualObjects([@"'" stringByEscapingForShell], @"\\'", @"-stringByEscapingForShell didn't properly escape the horizontal tab character");
	STAssertEqualObjects([@"\"" stringByEscapingForShell], @"\\\"", @"-stringByEscapingForShell didn't properly escape the line-feed character");
	STAssertEqualObjects([@"`" stringByEscapingForShell], @"\\`", @"-stringByEscapingForShell didn't properly escape the vertical tab character");
	STAssertEqualObjects([@"!" stringByEscapingForShell], @"\\!", @"-stringByEscapingForShell didn't properly escape the form-feed character");
	STAssertEqualObjects([@"$" stringByEscapingForShell], @"\\$", @"-stringByEscapingForShell didn't properly escape the carriage-return character");
	STAssertEqualObjects([@"&"  stringByEscapingForShell], @"\\&", @"-stringByEscapingForShell didn't properly escape the space character");
	STAssertEqualObjects([@"|"  stringByEscapingForShell], @"\\|", @"-stringByEscapingForShell didn't properly escape the space character");
}
- (void)testVolumePath
{
	NSString *homeVolumePath = [NSHomeDirectory() volumePath];
	STAssertTrue([homeVolumePath isEqualToString:@"/"] || [homeVolumePath isEqualToString:[@"/Users" stringByAppendingPathComponent:NSUserName()]], @"Volume path \"%@\" of home directory %@ is neither / nor /Users/%@", homeVolumePath, NSHomeDirectory, NSUserName());

	STAssertEqualObjects([@"/" volumePath], @"/", @"Volume path of / is \"%@\", not /", [@"/" volumePath]);

	//Get the name of the startup volume, so that we can attempt to get the volume path of (what we hope is) a directory on it.
	OSStatus err;

	FSRef ref;
	err = FSPathMakeRef((const UInt8 *)"/", &ref, /*isDirectory*/ NULL);
	STAssertTrue(err == noErr, @"Error while attempting to determine the path of the startup volume: FSPathMakeRef returned %i", err);

	struct HFSUniStr255 volumeNameUnicode;
	err = FSGetCatalogInfo(&ref, /*whichInfo*/ 0, /*catalogInfo*/ NULL, /*outName*/ &volumeNameUnicode, /*fsSpec*/ NULL, /*parentRef*/ NULL);
	STAssertTrue(err == noErr, @"Error while attempting to determine the path of the startup volume: FSGetCatalogInfo returned %i", err);

	NSString *volumeName = [[[NSString alloc] initWithCharactersNoCopy:volumeNameUnicode.unicode length:volumeNameUnicode.length freeWhenDone:NO] autorelease];
	NSLog(@"Volume name from FSGetCatalogInfo is %@", volumeName);
	NSString *inputPath = [[@"/Volumes" stringByAppendingPathComponent:volumeName] stringByAppendingPathComponent:@"Applications"];
	NSString *outputPath = [inputPath volumePath];

	STAssertEqualObjects(outputPath, @"/", @"The volume path of %@ should be /; instead, it was \"%@\"", inputPath, outputPath);
}
- (void)testAllLinesWithSeparator
{
	NSString *str = @"Foo\nbar\nbaz";
	NSArray *linesWithSep = [str allLinesWithSeparator:@"Qux"];
	NSArray *expectedLines = [NSArray arrayWithObjects:@"Foo", @"Qux", @"bar", @"Qux", @"baz", nil];
	AISimplifiedAssertEqualObjects(linesWithSep, expectedLines, @"allLinesWithSeparator: did not properly split and splice the array");

	NSArray *lines = [str allLinesWithSeparator:nil];
	expectedLines = [NSArray arrayWithObjects:@"Foo", @"bar", @"baz", nil];
	AISimplifiedAssertEqualObjects(lines, expectedLines, @"allLinesWithSeparator: did not properly split the array");
}
- (void)testAllLines
{
	NSString *str = @"Foo\nbar\nbaz";
	NSArray *lines = [str allLinesWithSeparator:nil];
	NSArray *expectedLines = [NSArray arrayWithObjects:@"Foo", @"bar", @"baz", nil];
	AISimplifiedAssertEqualObjects(lines, expectedLines, @"allLines did not properly split the array");
}

@end
