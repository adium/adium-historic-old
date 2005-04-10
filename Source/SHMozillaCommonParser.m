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

#import "AIBookmarksImporter.h"
#import "SHMozillaCommonParser.h"
#import <AIHyperlinks/SHMarkedHyperlink.h>

#define gtSign				@">"
#define Hclose				@"</H"
#define Hopen				@"H3 "
#define Aopen				@"A "
#define hrefStr				@"HREF="
#define closeQuote			@"\""
#define closeLink			@"\">"
#define Aclose				@"</A"
#define DLOpen				@"<DL>"
#define DLclose				@"/DL>"
#define ltSign				@"<"
    
#define bSemicolon			@";"
#define bTagCharStartString	@"&"
#define bAmpersand			@"&"
#define bAmpersandHTML		@"AMP"
#define bGreaterThan		@">"
#define bGreaterThanHTML	@"GT"
#define bLessThan			@"<"
#define bLessThanHTML		@"LT"
#define bQuote				@"\""
#define bQuoteHTML			@"QUOT"
#define bSpace				@" "
#define bSpaceHTML			@"NBSP"
#define bApostrophe			@"'"
#define bApostropheHTML		@"APOS"
#define bMdash				@"-"
#define bMdashHTML			@"MDASH"

@implementation SHMozillaCommonParser

+ (NSArray *)parseBookmarksfromString:(NSString *)inString
{
	NSMutableArray		*bookmarksArray = [[NSMutableArray alloc] init];
	NSMutableArray		*arrayStack = [NSMutableArray array];
	NSScanner			*linkScanner = [NSScanner scannerWithString:inString];
	NSString			*titleString = nil, *urlString = nil;

	unsigned int		stringLength = [inString length];

	NSCharacterSet		*quotesSet = [NSCharacterSet characterSetWithCharactersInString:@"'\""];

    while(![linkScanner isAtEnd]){
		if((stringLength - [linkScanner scanLocation]) < 4){
			[linkScanner setScanLocation:[inString length]];
		}else if([[inString substringWithRange:NSMakeRange([linkScanner scanLocation],3)] caseInsensitiveCompare:Hopen] == NSOrderedSame){
			if((stringLength - [linkScanner scanLocation]) > 3){
				[linkScanner setScanLocation:[linkScanner scanLocation] + 3];
			}

			[linkScanner scanUpToString:gtSign intoString:nil];

			if((stringLength - [linkScanner scanLocation]) > 1){
				[linkScanner setScanLocation:[linkScanner scanLocation] + 1];
			}

			titleString = nil;

			if([linkScanner scanUpToString:Hclose intoString:&titleString]){
				// decode html stuff
				titleString = [SHMozillaCommonParser simplyReplaceHTMLCodes:titleString];
				[linkScanner setScanLocation:[linkScanner scanLocation] + 3];
			}

			[arrayStack addObject:bookmarksArray];
			[bookmarksArray release];
			bookmarksArray = [[NSMutableArray alloc] init];
			[(NSMutableArray *)[arrayStack lastObject] addObject:[AIBookmarksImporter menuDictWithTitle:titleString
																							  menuItems:bookmarksArray]];
		}else if([[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],2)] caseInsensitiveCompare:Aopen] == NSOrderedSame){
			[linkScanner scanUpToString:hrefStr intoString:nil];

			if((stringLength - [linkScanner scanLocation]) > 6){
				[linkScanner setScanLocation:[linkScanner scanLocation] + 6];
			}
            
			if([linkScanner scanUpToCharactersFromSet:quotesSet intoString:&urlString]){
				[linkScanner scanUpToString:gtSign intoString:nil];

				if((stringLength - [linkScanner scanLocation]) > 1){
					[linkScanner setScanLocation:[linkScanner scanLocation] + 1];
				}

				titleString = nil;

				if([linkScanner scanUpToString:Aclose intoString:&titleString]){
					// decode html stuff
					titleString = [SHMozillaCommonParser simplyReplaceHTMLCodes:titleString];
				}

				[bookmarksArray addObject:[AIBookmarksImporter hyperlinkForTitle:titleString URL:urlString]];
			}
		}else if([[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],4)] caseInsensitiveCompare:DLclose] == NSOrderedSame){
			if((stringLength - [linkScanner scanLocation]) > 4){
				[linkScanner setScanLocation:[linkScanner scanLocation] + 4];
			}

			if([arrayStack count]){
				//Set bookmarks array to the last array added to the arrayStack to avoid an extra alloc/init.
				//However, if we somehow get here and bookmarksArray is already that object, we don't want to release
				//and set as that would later lead to a double release.
				NSMutableArray *previousBookmarksArray = [arrayStack lastObject];

				if (bookmarksArray != previousBookmarksArray){
					[bookmarksArray release]; bookmarksArray = [previousBookmarksArray retain];
				}

				[arrayStack removeLastObject];
			}
		}else{
			[linkScanner scanUpToString:ltSign intoString:nil];

			if((stringLength - [linkScanner scanLocation]) > 1){
				[linkScanner setScanLocation:[linkScanner scanLocation] + 1];
			}
		}
	}

	return [bookmarksArray autorelease];
}

#pragma mark HTML replacement        

+ (NSString *)simplyReplaceHTMLCodes:(NSString *)inString
{
	NSString		*tokenString,*blahString,*tagOpen;
	NSScanner		*scanner;
	NSCharacterSet	*tagCharStart,*charEnd;
	NSMutableString	*newString;
	BOOL			validTag;
	
	tagCharStart = [NSCharacterSet characterSetWithCharactersInString:bTagCharStartString];
	charEnd = [NSCharacterSet characterSetWithCharactersInString:bSemicolon];
	scanner = [NSScanner scannerWithString:inString];
	newString = [NSMutableString string];
	[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
	
	while(![scanner isAtEnd]){
		if([scanner scanUpToCharactersFromSet:tagCharStart intoString:&blahString]){
			[newString appendString:blahString];
		}
		
		if([scanner scanCharactersFromSet:tagCharStart intoString:&tagOpen]){
			unsigned int scanLoc = [scanner scanLocation];

			if(validTag = [scanner scanUpToCharactersFromSet:charEnd intoString:&tokenString]){
				if(NSOrderedSame == [tokenString caseInsensitiveCompare:bAmpersandHTML]){
					[newString appendString:bAmpersand];
				}else if(NSOrderedSame == [tokenString caseInsensitiveCompare:bGreaterThanHTML]){
					[newString appendString:bGreaterThan];
				}else if(NSOrderedSame == [tokenString caseInsensitiveCompare:bLessThanHTML]){
					[newString appendString:bLessThan];
				}else if(NSOrderedSame == [tokenString caseInsensitiveCompare:bQuoteHTML]){
					[newString appendString:bQuote];
				}else if(NSOrderedSame == [tokenString caseInsensitiveCompare:bSpaceHTML]){
					[newString appendString:bSpace];
				}else if(NSOrderedSame == [tokenString caseInsensitiveCompare:bApostropheHTML]){
					[newString appendString:bApostrophe];
				}else if(NSOrderedSame == [tokenString caseInsensitiveCompare:bMdashHTML]){
					[newString appendString:bMdash];
				}
				
				if(validTag){
					[scanner scanCharactersFromSet:charEnd intoString:nil];
				}else{
					[newString appendString:bAmpersand];
					[scanner setScanLocation:scanLoc];
				}
			}
		}
	}

	return newString;
}

@end
