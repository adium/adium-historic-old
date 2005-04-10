/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "SHOmniWebBookmarksImporter.h"
#import "SHMozillaCommonParser.h"
#import <AIHyperlinks/SHMarkedHyperlink.h>
#import <AIUtilities/AIFileManagerAdditions.h>

#define OW45_BOOKMARKS_PATH		@"~/Library/Application Support/OmniWeb/Bookmarks.html"
#define OW5_BOOKMARKS_PATH		@"~/Library/Application Support/OmniWeb 5/Favorites.html"

// Parser constants
#define HEADER3		@"h3"
#define A_OPEN		@"a "
#define A_CLOSE		@"</a"
#define HREF_STRING	@"href="
#define DL_CLOSE	@"/dl>"
#define CLOSE_TAG	@">"
#define OPEN_TAG	@"<"

@interface SHOmniWebBookmarksImporter (PRIVATE)
- (NSArray *)parseBookmarksString:(NSString *)inString;
@end

@implementation SHOmniWebBookmarksImporter

#pragma mark protocol methods

- (BOOL)browserIsAvailable
{
	NSFileManager *mgr = [NSFileManager defaultManager];
	BOOL exists, isDir = NO;
	exists = ([mgr fileExistsAtPath:[OW5_BOOKMARKS_PATH stringByExpandingTildeInPath] isDirectory:&isDir] && !isDir);
	if(!exists) {
		exists = ([mgr fileExistsAtPath:[OW45_BOOKMARKS_PATH stringByExpandingTildeInPath] isDirectory:&isDir] && !isDir);
	}
	return exists;
}

+ (NSString *)browserName
{
	return @"Firefox";
}
+ (NSString *)browserSignature
{
	return @"MOZB";
}
+ (NSString *)browserBundleIdentifier
{
	return @"org.mozilla.firefox";
}

#pragma mark -

+ (void)load
{
	AIBOOKMARKSIMPORTER_REGISTERWITHCONTROLLER();
}

#pragma mark -

+ (NSString *)bookmarksPathForOmniWeb5
{
	return [[NSFileManager defaultManager] pathIfNotDirectory:[OW5_BOOKMARKS_PATH stringByExpandingTildeInPath]];
}
+ (NSString *)bookmarksPathForOmniWeb4Point5
{
	return [[NSFileManager defaultManager] pathIfNotDirectory:[OW45_BOOKMARKS_PATH stringByExpandingTildeInPath]];
}
+ (NSString *)bookmarksPath
{
	NSString *path = [self bookmarksPathForOmniWeb5];
	if(!path) path = [self bookmarksPathForOmniWeb4Point5];
	return path;
}

- (NSArray *)availableBookmarks
{
    NSString    *bookmarkPath = [[self class] bookmarksPath];
#warning this uses the ephemeral C string encoding. it should use an explicit encoding.
	/*further note: my historical OmniWeb 5 Favorites file has UTF-8 in its Content-Type header.
	 *I don't know what 4.5 uses, though, and we shouldn't assume the value of Content-Type anyway.
	 *the right way would be to proceed in a strict 8-bit encoding like ISO 8859-1,
	 *	read the Content-Type, and then reread the file as whatever encoding is found.
	 *the hard part of that is mapping an HTTP encoding name to an NSStringEncoding.
	 *--boredzo
	 */
    NSString    *bookmarkString = [NSString stringWithContentsOfFile:bookmarkPath];

    NSDictionary    *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:bookmarkPath traverseLink:YES];
    [lastModDate release]; lastModDate = [[fileProps objectForKey:NSFileModificationDate] retain];

    return([self parseBookmarksString:bookmarkString]);
}


#pragma mark Private methods

- (NSArray *)parseBookmarksString:(NSString *)inString
{
	NSMutableArray	*bookmarksArray = [NSMutableArray array];
	NSMutableArray	*arrayStack = [NSMutableArray array];
	NSScanner		*linkScanner = [NSScanner scannerWithString:inString];
	NSString		*omniTitleString = nil;
	NSString		*urlString = nil;
	
	unsigned int	stringLength = [inString length];

	NSCharacterSet	*quotesSet = [NSCharacterSet characterSetWithCharactersInString:@"'\""];

	[linkScanner setCaseSensitive:NO];

	while(![linkScanner isAtEnd]){
		if((stringLength - [linkScanner scanLocation]) < 4){
			[linkScanner setScanLocation:[inString length]];
		}else if([[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],2)] isEqualToString:HEADER3]){
			if((stringLength - [linkScanner scanLocation]) > 2){
				[linkScanner setScanLocation:[linkScanner scanLocation] + 2];
			}

			[linkScanner scanUpToString:A_OPEN intoString:nil];

			if((stringLength - [linkScanner scanLocation]) > 2){
				[linkScanner setScanLocation:[linkScanner scanLocation] + 2];
			}

			[linkScanner scanUpToString:CLOSE_TAG intoString:nil];

			if((stringLength - [linkScanner scanLocation]) > 1){
				[linkScanner setScanLocation:[linkScanner scanLocation] + 1];
			}
            
			if([linkScanner scanUpToString:A_CLOSE intoString:&omniTitleString]){
				// decode html stuff
				omniTitleString = [SHMozillaCommonParser simplyReplaceHTMLCodes:omniTitleString];
			}else{
				// invalid; reset to nil
				omniTitleString = nil;
			}
            
			[arrayStack addObject:bookmarksArray];
			bookmarksArray = [NSMutableArray array];
			[(NSMutableArray *)[arrayStack lastObject] addObject:[[self class] menuDictWithTitle:omniTitleString
																					   menuItems:bookmarksArray]];
		}else if([[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],2)] isEqualToString:A_OPEN]){
			[linkScanner scanUpToString:HREF_STRING intoString:nil];

			if((stringLength - [linkScanner scanLocation]) > 6){
				[linkScanner setScanLocation:[linkScanner scanLocation] + 6];
			}

			if([linkScanner scanUpToCharactersFromSet:quotesSet intoString:&urlString]){
				[linkScanner scanUpToString:CLOSE_TAG intoString:nil];

				if((stringLength - [linkScanner scanLocation]) > 1){
					[linkScanner setScanLocation:[linkScanner scanLocation] + 1];
				}

				if([linkScanner scanUpToString:A_CLOSE intoString:&omniTitleString]){
					// decode html stuff
					omniTitleString = [SHMozillaCommonParser simplyReplaceHTMLCodes:omniTitleString];
				}else{
					// invalid; reset to nil
					omniTitleString = nil;
				}

				[bookmarksArray addObject:[[self class] hyperlinkForTitle:omniTitleString URL:urlString]];
			}
		}else if([[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],4)] isEqualToString:DL_CLOSE]){
			if((stringLength - [linkScanner scanLocation]) > 4){
				[linkScanner setScanLocation:[linkScanner scanLocation] + 4];
			}

			if([arrayStack count]){
				bookmarksArray = [arrayStack lastObject];
				[arrayStack removeLastObject];
			}
		}else{
			[linkScanner scanUpToString:OPEN_TAG intoString:nil];

			if(![linkScanner isAtEnd]){
				[linkScanner setScanLocation:[linkScanner scanLocation] + 1];
			}
		}
	}

	return bookmarksArray;
}

@end
