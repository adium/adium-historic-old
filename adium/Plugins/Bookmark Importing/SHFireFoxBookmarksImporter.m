//
//  SHFireFoxBookmarksImporter.m
//  Adium
//
//  Created by Stephen Holt on Sun May 30 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "SHFireFoxBookmarksImporter.h"

#define FIREFOX_BOOKMARKS_PATH  @"~/Library/Phoenix/Profiles/default"
#define FIREFOX_BOOKMARKS_FILE_NAME @"bookmarks.html"

#define FIREFOX_ROOT_MENU_TITLE AILocalizedString(@"FireFox",nil)

@interface SHFireFoxBookmarksImporter(PRIVATE)
- (NSString *)bookmarkPath;
- (void)parseBookmarksFile:(NSString *)inString;
@end

@implementation SHFireFoxBookmarksImporter

static NSMenu   *firefoxBookmarksMenu;
static NSMenu   *firefixBookmarksSupermenu;
static NSMenu   *firefoxTopMenu;

#pragma mark protocol methods
+ (id)newInstanceOfImporter
{
    return [[[self alloc] init] autorelease];
}

-(NSMenu *)parseBookmarksForOwner:(id)inObject
{
    owner = inObject;
    NSString        *bookmarkString = [NSString stringWithContentsOfFile:[self bookmarkPath]];
    
    // remove our root menu, if it exists
    if(firefoxBookmarksMenu){
        [firefoxBookmarksMenu removeAllItems];
        [firefoxBookmarksMenu release];
    }
    
    // store the modification date for future reference
    if (lastModDate) [lastModDate release];
    NSDictionary *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:[self bookmarkPath] traverseLink:YES];
    lastModDate = [[fileProps objectForKey:NSFileModificationDate] retain];
    
    firefoxBookmarksMenu = [[[NSMenu alloc] initWithTitle:FIREFOX_ROOT_MENU_TITLE] autorelease];
    firefixBookmarksSupermenu = firefoxBookmarksMenu;
    firefoxTopMenu = firefoxBookmarksMenu;
    [self parseBookmarksFile:bookmarkString];
    
    return firefoxBookmarksMenu;
}

-(BOOL)bookmarksExist
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self bookmarkPath]];
}

-(NSString *)menuTitle
{
    return FIREFOX_ROOT_MENU_TITLE;
}

-(BOOL)bookmarksUpdated
{
    NSDictionary *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:[self bookmarkPath] traverseLink:YES];
    NSDate *modDate = [fileProps objectForKey:NSFileModificationDate];
    
    return ![modDate isEqualToDate:lastModDate];
}

#pragma mark private methods
- (NSString *)bookmarkPath
{
    NSEnumerator *enumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:[FIREFOX_BOOKMARKS_PATH stringByExpandingTildeInPath]] objectEnumerator];
    NSString    *directory;
    
    while(directory = [enumerator nextObject]){
        NSRange found = [directory rangeOfString:@".slt"];
        if(found.location != NSNotFound)
            return [NSString stringWithFormat:@"%@/%@/%@",[FIREFOX_BOOKMARKS_PATH stringByExpandingTildeInPath], directory, FIREFOX_BOOKMARKS_FILE_NAME];
    }
    return FIREFOX_BOOKMARKS_PATH;
}

- (void)parseBookmarksFile:(NSString *)inString
{
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
                
            firefixBookmarksSupermenu = firefoxBookmarksMenu;
            firefoxBookmarksMenu = [[[NSMenu alloc] initWithTitle:titleString] autorelease];
        
            NSMenuItem *mozillaSubmenuItem = [[[NSMenuItem alloc] initWithTitle:titleString
                                                                         target:owner
                                                                         action:nil
                                                                  keyEquivalent:@""] autorelease];
            [firefixBookmarksSupermenu addItem:mozillaSubmenuItem];
            [firefixBookmarksSupermenu setSubmenu:firefoxBookmarksMenu forItem:mozillaSubmenuItem];
        }else if(NSOrderedSame == [[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],2)] compare:@"A "]){
            //[linkScanner setScanLocation:[linkScanner scanLocation] + 3];
            [linkScanner scanUpToString:@"HREF=\"" intoString:nil];
            [linkScanner setScanLocation:[linkScanner scanLocation] + 6];
            [linkScanner scanUpToString:@"\"" intoString:&urlString];
                
            [linkScanner scanUpToString:@"\">" intoString:nil];
            [linkScanner setScanLocation:[linkScanner scanLocation] + 2];
            [linkScanner scanUpToString:@"</A" intoString:&titleString];
                
            SHMarkedHyperlink *markedLink = [[[SHMarkedHyperlink alloc] initWithString:[urlString retain]
                                                                  withValidationStatus:SH_URL_VALID
                                                                          parentString:titleString
                                                                              andRange:NSMakeRange(0,[titleString length])] autorelease];
                                                                          
            [firefoxBookmarksMenu addItemWithTitle:titleString
                                            target:owner
                                            action:@selector(injectBookmarkFrom:)
                                     keyEquivalent:@""
                                 representedObject:markedLink];
        
        }else if(NSOrderedSame == [[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],4)] compare:@"/DL>"]){
            [linkScanner setScanLocation:[linkScanner scanLocation] + 4];
            if([firefoxBookmarksMenu isNotEqualTo:firefoxTopMenu]){
                firefoxBookmarksMenu = firefixBookmarksSupermenu;
                firefixBookmarksSupermenu = [firefixBookmarksSupermenu supermenu];
            }
        }else{
            [linkScanner scanUpToString:@"<" intoString:nil];
            [linkScanner setScanLocation:[linkScanner scanLocation] + 1];
        }
    }
}

@end