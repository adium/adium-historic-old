//
//  SHMozillaCommonParser.m
//  Adium
//
//  Created by Stephen Holt on Sat Jun 05 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "SHMozillaCommonParser.h"


@implementation SHMozillaCommonParser

DeclareString(gtSign)
DeclareString(Hclose)
DeclareString(Hopen)
DeclareString(Aopen)
DeclareString(hrefStr)
DeclareString(closeQuote)
DeclareString(closeLink)
DeclareString(Aclose)
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

+ (void)load
{
    InitString(gtSign,@">")
    InitString(Hclose,@"</H")
    InitString(Hopen,@"H3 ")
    InitString(Aopen,@"A ")
    InitString(hrefStr,@"HREF=\"")
    InitString(closeQuote,@"\"")
    InitString(closeLink,@"\">")
    InitString(Aclose,@"</A")
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
}

+ (void)parseBookmarksfromString:(NSString *)inString forOwner:(id)owner andMenu:(NSMenu *)bookmarksMenu
{
    NSMenu      *bookmarksSupermenu = bookmarksMenu;
    NSMenu      *topMenu = bookmarksMenu;
    NSScanner   *linkScanner = [NSScanner scannerWithString:inString];
    NSString    *titleString, *urlString;
    NSString    *untitledString = @"untitled";
    
    unsigned int stringLength = [inString length];
    
    
    NSCharacterSet  *quotesSet = [NSCharacterSet characterSetWithCharactersInString:@"'\""];
    
    while(![linkScanner isAtEnd]){
        if((stringLength - [linkScanner scanLocation]) < 4){
            [linkScanner setScanLocation:[inString length]];
        }else if([[inString substringWithRange:NSMakeRange([linkScanner scanLocation],3)] isEqualToString:Hopen]){
            if((stringLength - [linkScanner scanLocation]) > 3) [linkScanner setScanLocation:[linkScanner scanLocation] + 3];
            [linkScanner scanUpToString:gtSign intoString:nil];
            if((stringLength - [linkScanner scanLocation]) > 1) [linkScanner setScanLocation:[linkScanner scanLocation] + 1];
            [linkScanner scanUpToString:Hclose intoString:&titleString];

            if(titleString){
                // decode html stuff
                titleString = [SHMozillaCommonParser simplyReplaceHTMLCodes:titleString];
            }
            
            bookmarksSupermenu = bookmarksMenu;
            bookmarksMenu = [[[NSMenu alloc] initWithTitle:titleString? titleString : untitledString] autorelease];
        
            NSMenuItem *mozillaSubmenuItem = [[[NSMenuItem alloc] initWithTitle:titleString? titleString : untitledString
                                                                         target:owner
                                                                         action:nil
                                                                  keyEquivalent:@""] autorelease];
            [bookmarksSupermenu addItem:mozillaSubmenuItem];
            [bookmarksSupermenu setSubmenu:bookmarksMenu forItem:mozillaSubmenuItem];
        }else if([[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],2)] isEqualToString:Aopen]){
            [linkScanner scanUpToString:hrefStr intoString:nil];
            if((stringLength - [linkScanner scanLocation]) > 6) [linkScanner setScanLocation:[linkScanner scanLocation] + 6];
            [linkScanner scanUpToCharactersFromSet:quotesSet intoString:&urlString];
                
            [linkScanner scanUpToString:gtSign intoString:nil];
            if((stringLength - [linkScanner scanLocation]) > 1) [linkScanner setScanLocation:[linkScanner scanLocation] + 1];
            [linkScanner scanUpToString:Aclose intoString:&titleString];

            if(titleString){
                // decode html stuff
                titleString = [SHMozillaCommonParser simplyReplaceHTMLCodes:titleString];
            }
            
            SHMarkedHyperlink *markedLink = [[[SHMarkedHyperlink alloc] initWithString:[urlString retain]
                                                                  withValidationStatus:SH_URL_VALID
                                                                          parentString:titleString? titleString : urlString
                                                                              andRange:NSMakeRange(0,titleString? [titleString length] : [urlString length])] autorelease];
                                                                          
            [bookmarksMenu addItemWithTitle:titleString? titleString : urlString
                                            target:owner
                                            action:@selector(injectBookmarkFrom:)
                                     keyEquivalent:@""
                                 representedObject:markedLink];
        
        }else if([[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],4)] isEqualToString:DLclose]){
            if((stringLength - [linkScanner scanLocation]) > 4) [linkScanner setScanLocation:[linkScanner scanLocation] + 4];
            if([bookmarksMenu isNotEqualTo:topMenu]){
                bookmarksMenu = bookmarksSupermenu;
                bookmarksSupermenu = [bookmarksSupermenu supermenu];
            }
        }else{
            [linkScanner scanUpToString:ltSign intoString:nil];
            if((stringLength - [linkScanner scanLocation]) > 1) [linkScanner setScanLocation:[linkScanner scanLocation] + 1];
        }
    }
}
        
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
