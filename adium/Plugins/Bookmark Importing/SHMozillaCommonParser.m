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

+ (void)parseBookmarksfromString:(NSString *)inString forOwner:(id)owner andMenu:(NSMenu *)bookmarksMenu
{
    NSMenu      *bookmarksSupermenu = bookmarksMenu;
    NSMenu      *topMenu = bookmarksMenu;
    NSScanner   *linkScanner = [NSScanner scannerWithString:inString];
    NSString    *titleString, *urlString;
    NSString    *untitledString = @"untitled";
    
    unsigned int stringLength = [inString length];
    
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
    
    while(![linkScanner isAtEnd]){
        if((stringLength - [linkScanner scanLocation]) < 4){
            [linkScanner setScanLocation:[inString length]];
        }else if(NSOrderedSame == [[inString substringWithRange:NSMakeRange([linkScanner scanLocation],3)] compare:Hopen]){
            if((stringLength - [linkScanner scanLocation]) > 3) [linkScanner setScanLocation:[linkScanner scanLocation] + 3];
            [linkScanner scanUpToString:gtSign intoString:nil];
            if((stringLength - [linkScanner scanLocation]) > 1) [linkScanner setScanLocation:[linkScanner scanLocation] + 1];
            [linkScanner scanUpToString:Hclose intoString:&titleString];

            if(titleString){
                // decode html stuff
                titleString = [[AIHTMLDecoder decodeHTML:titleString] string];
            }
            
            bookmarksSupermenu = bookmarksMenu;
            bookmarksMenu = [[[NSMenu alloc] initWithTitle:titleString? titleString : untitledString] autorelease];
        
            NSMenuItem *mozillaSubmenuItem = [[[NSMenuItem alloc] initWithTitle:titleString? titleString : untitledString
                                                                         target:owner
                                                                         action:nil
                                                                  keyEquivalent:@""] autorelease];
            [bookmarksSupermenu addItem:mozillaSubmenuItem];
            [bookmarksSupermenu setSubmenu:bookmarksMenu forItem:mozillaSubmenuItem];
        }else if(NSOrderedSame == [[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],2)] compare:Aopen]){
            [linkScanner scanUpToString:hrefStr intoString:nil];
            if((stringLength - [linkScanner scanLocation]) > 6) [linkScanner setScanLocation:[linkScanner scanLocation] + 6];
            [linkScanner scanUpToString:closeQuote intoString:&urlString];
                
            [linkScanner scanUpToString:closeLink intoString:nil];
            if((stringLength - [linkScanner scanLocation]) > 2) [linkScanner setScanLocation:[linkScanner scanLocation] + 2];
            [linkScanner scanUpToString:Aclose intoString:&titleString];

            if(titleString){
                // decode html stuff
                titleString = [[AIHTMLDecoder decodeHTML:titleString] string];
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
        
        }else if(NSOrderedSame == [[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],4)] compare:DLclose]){
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

@end
