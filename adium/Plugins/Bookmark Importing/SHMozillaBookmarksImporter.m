//
//  SHMozillaBookmarksImporter.m
//  Adium
//
//  Created by Stephen Holt on Tue May 25 2004.

#import "SHMozillaBookmarksImporter.h"

#define MOZILLA_BOOKMARKS_PATH  @"~/Library/Mozilla/Profiles/default"
#define MOZILLA_BOOKMARKS_FILE_NAME @"bookmarks.html"

#define MOZILLA_ROOT_MENU_TITLE AILocalizedString(@"Mozilla",nil)

@interface SHMozillaBookmarksImporter(PRIVATE)
- (NSString *)bookmarkPath;
- (void)parseBookmarksFile:(NSString *)inString;
@end

@implementation SHMozillaBookmarksImporter

static NSMenu   *mozillaBookmarksMenu;
static NSMenu   *mozillaBookmarksSupermenu;
static NSMenu   *mozillaTopMenu;

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
    if(mozillaBookmarksMenu){
        [mozillaBookmarksMenu removeAllItems];
        [mozillaBookmarksMenu release];
    }
    
    // store the modification date for future reference
    if (lastModDate) [lastModDate release];
    NSDictionary *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:[self bookmarkPath] traverseLink:YES];
    lastModDate = [[fileProps objectForKey:NSFileModificationDate] retain];
    
    mozillaBookmarksMenu = [[[NSMenu alloc] initWithTitle:MOZILLA_ROOT_MENU_TITLE] autorelease];
    mozillaBookmarksSupermenu = mozillaBookmarksMenu;
    mozillaTopMenu = mozillaBookmarksMenu;
    [self parseBookmarksFile:bookmarkString];
    
    return mozillaBookmarksMenu;
}

-(BOOL)bookmarksExist
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self bookmarkPath]];
}

-(NSString *)menuTitle
{
    return MOZILLA_ROOT_MENU_TITLE;
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
    NSEnumerator *enumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:[MOZILLA_BOOKMARKS_PATH stringByExpandingTildeInPath]] objectEnumerator];
    NSString    *directory;
    
    while(directory = [enumerator nextObject]){
        NSRange found = [directory rangeOfString:@".slt"];
        if(found.location != NSNotFound)
            return [NSString stringWithFormat:@"%@/%@/%@",[MOZILLA_BOOKMARKS_PATH stringByExpandingTildeInPath], directory, MOZILLA_BOOKMARKS_FILE_NAME];
    }
    return MOZILLA_BOOKMARKS_PATH;
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
        
        NSLog(titleString);
        
        mozillaBookmarksSupermenu = mozillaBookmarksMenu;
        mozillaBookmarksMenu = [[[NSMenu alloc] initWithTitle:titleString] autorelease];
        
        NSMenuItem *mozillaSubmenuItem = [[[NSMenuItem alloc] initWithTitle:titleString
                                                                     target:owner
                                                                     action:nil
                                                              keyEquivalent:@""] autorelease];
        [mozillaBookmarksSupermenu addItem:mozillaSubmenuItem];
        [mozillaBookmarksSupermenu setSubmenu:mozillaBookmarksMenu forItem:mozillaSubmenuItem];
        
//        [self parseBookmarksFile:[inString substringFromIndex:[linkScanner scanLocation]]];
    }else if(NSOrderedSame == [[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],2)] compare:@"A "]){
//        NSLog([[linkScanner string] substringFromIndex:[linkScanner scanLocation]]);
//        NSLog(@"scan location: %u/%u",[linkScanner scanLocation],[inString length]);
        //[linkScanner setScanLocation:[linkScanner scanLocation] + 3];
//        NSLog(@"scan location: %u/%u",[linkScanner scanLocation],[inString length]);
        [linkScanner scanUpToString:@"HREF=\"" intoString:nil];
//        NSLog(@"scan location: %u/%u",[linkScanner scanLocation],[inString length]);
        [linkScanner setScanLocation:[linkScanner scanLocation] + 6];
//        NSLog(@"scan location: %u/%u",[linkScanner scanLocation],[inString length]);
        [linkScanner scanUpToString:@"\"" intoString:&urlString];
        
        NSLog(urlString);
        
        [linkScanner scanUpToString:@"\">" intoString:nil];
//        NSLog(@"scan location: %u/%u",[linkScanner scanLocation],[inString length]);
        [linkScanner setScanLocation:[linkScanner scanLocation] + 2];
//        NSLog(@"scan location: %u/%u",[linkScanner scanLocation],[inString length]);
        [linkScanner scanUpToString:@"</A" intoString:&titleString];
//        NSLog(@"scan location: %u/%u",[linkScanner scanLocation],[inString length]);
        
        NSLog(titleString);
        
        SHMarkedHyperlink *markedLink = [[[SHMarkedHyperlink alloc] initWithString:[urlString retain]
                                                              withValidationStatus:SH_URL_VALID
                                                                      parentString:titleString
                                                                          andRange:NSMakeRange(0,[titleString length])] autorelease];
                                                                          
        [mozillaBookmarksMenu addItemWithTitle:titleString
                                        target:owner
                                        action:@selector(injectBookmarkFrom:)
                                 keyEquivalent:@""
                             representedObject:markedLink];
        
//        [self parseBookmarksFile:[inString substringFromIndex:[linkScanner scanLocation]]];
    }else if(NSOrderedSame == [[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],4)] compare:@"/DL>"]){
        [linkScanner setScanLocation:[linkScanner scanLocation] + 4];
        if([mozillaBookmarksMenu isNotEqualTo:mozillaTopMenu]){
            mozillaBookmarksMenu = mozillaBookmarksSupermenu;
            mozillaBookmarksSupermenu = [mozillaBookmarksSupermenu supermenu];
        }
    }else{
        [linkScanner scanUpToString:@"<" intoString:nil];
        [linkScanner setScanLocation:[linkScanner scanLocation] + 1];
        NSLog([[linkScanner string] substringFromIndex:[linkScanner scanLocation]]);
//        if(![linkScanner isAtEnd])
//            [self parseBookmarksFile:[inString substringFromIndex:[linkScanner scanLocation]]];
    }
    }
}

@end
