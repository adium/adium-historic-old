//
//  SHMozillaCommonParser.m
//  Adium
//
//  Created by Stephen Holt on Sat Jun 05 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "SHMozillaCommonParser.h"


@implementation SHMozillaCommonParser

+ (void)parseBookmarksfromString:(NSString *)inString forOwner:(id)owner andMenu:(NSMenu *)bookmarksMenu
{
    NSMenu      *bookmarksSupermenu = bookmarksMenu;
    NSMenu      *topMenu = bookmarksMenu;
    NSScanner   *linkScanner = [NSScanner scannerWithString:inString];
    NSString    *titleString, *urlString;
    
    while(![linkScanner isAtEnd]){
        if([[inString substringFromIndex:[linkScanner scanLocation]] length] < 4){
            [linkScanner setScanLocation:[inString length]];
        }else if(NSOrderedSame == [[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],3)] compare:@"H3 "]){
            [linkScanner setScanLocation:[linkScanner scanLocation] + 3];
            [linkScanner scanUpToString:@">" intoString:nil];
            [linkScanner setScanLocation:[linkScanner scanLocation] + 1];
            [linkScanner scanUpToString:@"</H" intoString:&titleString];

            if(titleString){
                // decode html stuff
                titleString = [[AIHTMLDecoder decodeHTML:titleString] string];
            }
            
            bookmarksSupermenu = bookmarksMenu;
            bookmarksMenu = [[[NSMenu alloc] initWithTitle:titleString? titleString : @"untitled"] autorelease];
        
            NSMenuItem *mozillaSubmenuItem = [[[NSMenuItem alloc] initWithTitle:titleString? titleString : @"untitled"
                                                                         target:owner
                                                                         action:nil
                                                                  keyEquivalent:@""] autorelease];
            [bookmarksSupermenu addItem:mozillaSubmenuItem];
            [bookmarksSupermenu setSubmenu:bookmarksMenu forItem:mozillaSubmenuItem];
        }else if(NSOrderedSame == [[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],2)] compare:@"A "]){
            //[linkScanner setScanLocation:[linkScanner scanLocation] + 3];
            [linkScanner scanUpToString:@"HREF=\"" intoString:nil];
            [linkScanner setScanLocation:[linkScanner scanLocation] + 6];
            [linkScanner scanUpToString:@"\"" intoString:&urlString];
                
            [linkScanner scanUpToString:@"\">" intoString:nil];
            [linkScanner setScanLocation:[linkScanner scanLocation] + 2];
            [linkScanner scanUpToString:@"</A" intoString:&titleString];

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
        
        }else if(NSOrderedSame == [[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],4)] compare:@"/DL>"]){
            [linkScanner setScanLocation:[linkScanner scanLocation] + 4];
            if([bookmarksMenu isNotEqualTo:topMenu]){
                bookmarksMenu = bookmarksSupermenu;
                bookmarksSupermenu = [bookmarksSupermenu supermenu];
            }
        }else{
            [linkScanner scanUpToString:@"<" intoString:nil];
            [linkScanner setScanLocation:[linkScanner scanLocation] + 1];
        }
    }
    NSLog([bookmarksMenu description]);
}

@end
