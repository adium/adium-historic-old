//
//  SHMozillaCommonParser.m
//  Adium
//
//  Created by Stephen Holt on Sat Jun 05 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "SHBookmarksImporterPlugin.h"
#import "SHMozillaCommonParser.h"

@interface SHMozillaCommonParser(PRIVATE)
+(SHMarkedHyperlink *)hyperlinkForTitle:(NSString *)inString URL:(NSString *)inURLString;
+(NSDictionary *)menuDictWithTitle:(NSString *)inTitle menuItems:(NSArray *)inMenuItems;
@end

@implementation SHMozillaCommonParser

DeclareString(gtSign)
DeclareString(Hclose)
DeclareString(Hopen)
DeclareString(Aopen)
DeclareString(hrefStr)
DeclareString(closeQuote)
DeclareString(closeLink)
DeclareString(Aclose)
DeclareString(DLOpen)
DeclareString(DLclose)
DeclareString(ltSign)

DeclareString(bSemicolon)
DeclareString(bTagCharStartString)
DeclareString(bAmpersand)
DeclareString(bAmpersandHTML)
DeclareString(bGreaterThan)
DeclareString(bGreaterThanHTML)
DeclareString(bLessThan)
DeclareString(bLessThanHTML)
DeclareString(bQuote)
DeclareString(bQuoteHTML)
DeclareString(bSpace)
DeclareString(bSpaceHTML)
DeclareString(bApostrophe)
DeclareString(bApostropheHTML)
DeclareString(bMdash)
DeclareString(bMdashHTML)

//DeclareString(untitledString)
DeclareString(bookmarkDictTitle)
DeclareString(bookmarkDictContent)

+ (void)load
{
    InitString(gtSign,@">")
    InitString(Hclose,@"</H")
    InitString(Hopen,@"H3 ")
    InitString(Aopen,@"A ")
    InitString(hrefStr,@"HREF=")
    InitString(closeQuote,@"\"")
    InitString(closeLink,@"\">")
    InitString(Aclose,@"</A")
    InitString(DLOpen,@"<DL>")
    InitString(DLclose,@"/DL>")
    InitString(ltSign,@"<")
    
    InitString(bSemicolon,@";")
    InitString(bTagCharStartString,@"&")
    InitString(bAmpersand,@"&")
    InitString(bAmpersandHTML,@"AMP")
    InitString(bGreaterThan,@">")
    InitString(bGreaterThanHTML,@"GT")
    InitString(bLessThan,@"<")
    InitString(bLessThanHTML,@"LT")
    InitString(bQuote,@"\"")
    InitString(bQuoteHTML,@"QUOT")
    InitString(bSpace,@" ")
    InitString(bSpaceHTML,@"NBSP")
    InitString(bApostrophe,@"'")
    InitString(bApostropheHTML,@"APOS")
    InitString(bMdash,@"-");
    InitString(bMdashHTML,@"MDASH");
    
//    InitString(untitledString,@"untitled")
    InitString(bookmarkDictTitle,SH_BOOKMARK_DICT_TITLE)
    InitString(bookmarkDictContent,SH_BOOKMARK_DICT_CONTENT)
}

+ (NSArray *)parseBookmarksfromString:(NSString *)inString
{
    NSMutableArray      *bookmarksArray = [[NSMutableArray alloc] init];
    NSMutableArray      *arrayStack = [NSMutableArray array];
    NSScanner			*linkScanner = [NSScanner scannerWithString:inString];
    NSString			*titleString = nil, *urlString = nil;
    
    unsigned int		stringLength = [inString length];
    
    
    NSCharacterSet		*quotesSet = [NSCharacterSet characterSetWithCharactersInString:@"'\""];
    
    while(![linkScanner isAtEnd]){
        if((stringLength - [linkScanner scanLocation]) < 4){
            [linkScanner setScanLocation:[inString length]];
			
        }else if([[inString substringWithRange:NSMakeRange([linkScanner scanLocation],3)] isEqualToString:Hopen]){
            if((stringLength - [linkScanner scanLocation]) > 3) [linkScanner setScanLocation:[linkScanner scanLocation] + 3];
            [linkScanner scanUpToString:gtSign intoString:nil];
            if((stringLength - [linkScanner scanLocation]) > 1) [linkScanner setScanLocation:[linkScanner scanLocation] + 1];
            
			titleString = nil;
			
            if([linkScanner scanUpToString:Hclose intoString:&titleString]){
                // decode html stuff
                titleString = [SHMozillaCommonParser simplyReplaceHTMLCodes:titleString];
                [linkScanner setScanLocation:[linkScanner scanLocation] + 3];
            }
            [arrayStack addObject:bookmarksArray];
            [bookmarksArray release]; bookmarksArray = [[NSMutableArray alloc] init];
            [(NSMutableArray *)[arrayStack lastObject] addObject:[self menuDictWithTitle:titleString
																			   menuItems:bookmarksArray]];

        }else if([[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],2)] isEqualToString:Aopen]){
            [linkScanner scanUpToString:hrefStr intoString:nil];
            if((stringLength - [linkScanner scanLocation]) > 6) [linkScanner setScanLocation:[linkScanner scanLocation] + 6];
            
            if([linkScanner scanUpToCharactersFromSet:quotesSet intoString:&urlString]){
                [linkScanner scanUpToString:gtSign intoString:nil];
                if((stringLength - [linkScanner scanLocation]) > 1) [linkScanner setScanLocation:[linkScanner scanLocation] + 1];
                
				titleString = nil;
				
                if([linkScanner scanUpToString:Aclose intoString:&titleString]){
                    // decode html stuff
                    titleString = [SHMozillaCommonParser simplyReplaceHTMLCodes:titleString];
                }
            
                [bookmarksArray addObject:[self hyperlinkForTitle:titleString URL:urlString]];
            }
        }else if([[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],4)] isEqualToString:DLclose]){
            if((stringLength - [linkScanner scanLocation]) > 4) [linkScanner setScanLocation:[linkScanner scanLocation] + 4];
            
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
            if((stringLength - [linkScanner scanLocation]) > 1) [linkScanner setScanLocation:[linkScanner scanLocation] + 1];
        }
    }
	
    return [bookmarksArray autorelease];
}

+(SHMarkedHyperlink *)hyperlinkForTitle:(NSString *)inString URL:(NSString *)inURLString
{
    NSString    *title = inString? inString : @"untitled";
    return [[[SHMarkedHyperlink alloc] initWithString:inURLString
                                 withValidationStatus:SH_URL_VALID
                                         parentString:title
                                             andRange:NSMakeRange(0,[title length])] autorelease];
}

+(NSDictionary *)menuDictWithTitle:(NSString *)inTitle menuItems:(NSArray *)inMenuItems
{
    NSString    *titleString = inTitle? inTitle : @"untitled";
    return [NSDictionary dictionaryWithObjectsAndKeys:titleString, bookmarkDictTitle, inMenuItems, bookmarkDictContent, nil];
}

#pragma mark HTML replacement        
+ (NSString *)simplyReplaceHTMLCodes:(NSString *)inString
{
    NSString        *tokenString,*blahString,*tagOpen;
    NSScanner       *scanner;
    NSCharacterSet  *tagCharStart,*charEnd;
    NSMutableString *newString;
    BOOL             validTag;
    
    tagCharStart = [NSCharacterSet characterSetWithCharactersInString:bTagCharStartString];
    charEnd = [NSCharacterSet characterSetWithCharactersInString:bSemicolon];
    scanner = [NSScanner scannerWithString:inString];
    newString = [[NSMutableString alloc] init];
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
    return [newString autorelease];
}

@end
