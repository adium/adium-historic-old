//
//  SHOmniWebBookmarksImporter.m
//  Adium
//
//  Created by Stephen Holt on Mon May 31 2004.

#import "SHOmniWebBookmarksImporter.h"

#define OW45_BOOKMARKS_PATH  @"~/Library/Application Support/OmniWeb/Bookmarks.html"
#define OW5_BOOKMARKS_PATH  @"~/Library/Application Support/OmniWeb 5/Favorites.html"

#define OW45_ROOT_MENU_TITLE AILocalizedString(@"OmniWeb 4.5",nil)
#define OW5_ROOT_MENU_TITLE AILocalizedString(@"OmniWeb 5",nil)

@interface SHOmniWebBookmarksImporter(PRIVATE)
- (void)parseBookmarksFile:(NSString *)inString;
@end

@implementation SHOmniWebBookmarksImporter

static NSMenu   *omniBookmarksMenu;
static NSMenu   *omniBookmarksSupermenu;
static NSMenu   *omniTopMenu;

#pragma mark protocol methods
+ (id)newInstanceOfImporter
{
    return [[[self alloc] init] autorelease];
}

- (id)init
{
    useOW5 = [[NSFileManager defaultManager] fileExistsAtPath:[OW5_BOOKMARKS_PATH stringByExpandingTildeInPath]];
    [super init];
    return self;
}

-(NSMenu *)parseBookmarksForOwner:(id)inObject
{
    owner = inObject;
    NSString        *bookmarkString = [NSString stringWithContentsOfFile:useOW5? [OW5_BOOKMARKS_PATH stringByExpandingTildeInPath] : [OW45_BOOKMARKS_PATH stringByExpandingTildeInPath]];
    
    // remove our root menu, if it exists
    if(omniBookmarksMenu){
        [omniBookmarksMenu removeAllItems];
        [omniBookmarksMenu release];
    }
    
    // store the modification date for future reference
    if (lastModDate) [lastModDate release];
    NSDictionary *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:useOW5? [OW5_BOOKMARKS_PATH stringByExpandingTildeInPath] : [OW45_BOOKMARKS_PATH stringByExpandingTildeInPath] traverseLink:YES];
    lastModDate = [[fileProps objectForKey:NSFileModificationDate] retain];
    
    omniBookmarksMenu = [[[NSMenu alloc] initWithTitle:useOW5? OW5_ROOT_MENU_TITLE : OW45_ROOT_MENU_TITLE] autorelease];
    omniBookmarksSupermenu = omniBookmarksMenu;
    omniTopMenu = omniBookmarksMenu;
    [self parseBookmarksFile:bookmarkString];
    
    return omniBookmarksMenu;
}

-(BOOL)bookmarksExist
{
    return (useOW5 || [[NSFileManager defaultManager] fileExistsAtPath:[OW45_BOOKMARKS_PATH stringByExpandingTildeInPath]]);
}

-(NSString *)menuTitle
{
    return useOW5? OW5_ROOT_MENU_TITLE : OW45_ROOT_MENU_TITLE;
}

-(BOOL)bookmarksUpdated
{
    NSDictionary *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:useOW5? [OW5_BOOKMARKS_PATH stringByExpandingTildeInPath] : [OW45_BOOKMARKS_PATH stringByExpandingTildeInPath] traverseLink:YES];
    NSDate *modDate = [fileProps objectForKey:NSFileModificationDate];
    
    return ![modDate isEqualToDate:lastModDate];
}

#pragma mark private methods
- (void)parseBookmarksFile:(NSString *)inString
{
    NSScanner   *linkScanner = [NSScanner scannerWithString:inString];
    NSString    *omniTitleString = nil;
    NSString    *urlString = nil;
    
    [linkScanner setCaseSensitive:NO];
    
    while(![linkScanner isAtEnd]){
        if([[inString substringFromIndex:[linkScanner scanLocation]] length] < 4){
            [linkScanner setScanLocation:[inString length]];
        }else if(NSOrderedSame == [[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],2)] compare:@"h3"]){
            [linkScanner setScanLocation:[linkScanner scanLocation] + 2];
            [linkScanner scanUpToString:@"<a" intoString:nil];
            [linkScanner setScanLocation:[linkScanner scanLocation] + 2];
            [linkScanner scanUpToString:@">" intoString:nil];
            [linkScanner setScanLocation:[linkScanner scanLocation] + 1];
            [linkScanner scanUpToString:@"</a" intoString:&omniTitleString];
                
            omniBookmarksSupermenu = omniBookmarksMenu;
            omniBookmarksMenu = [[[NSMenu alloc] initWithTitle:omniTitleString? omniTitleString : @"untitled"] autorelease];
        
            NSMenuItem *mozillaSubmenuItem = [[[NSMenuItem alloc] initWithTitle:omniTitleString? omniTitleString : @"untitled"
                                                                         target:owner
                                                                         action:nil
                                                                  keyEquivalent:@""] autorelease];
            [omniBookmarksSupermenu addItem:mozillaSubmenuItem];
            [omniBookmarksSupermenu setSubmenu:omniBookmarksMenu forItem:mozillaSubmenuItem];
        }else if(NSOrderedSame == [[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],2)] compare:@"a "]){
            //[linkScanner setScanLocation:[linkScanner scanLocation] + 3];
            [linkScanner scanUpToString:@"href=\"" intoString:nil];
            [linkScanner setScanLocation:[linkScanner scanLocation] + 6];
            [linkScanner scanUpToString:@"\"" intoString:&urlString];

            [linkScanner scanUpToString:@">" intoString:nil];
            [linkScanner setScanLocation:[linkScanner scanLocation] + 1];
            [linkScanner scanUpToString:@"</a" intoString:&omniTitleString];

            SHMarkedHyperlink *markedLink = [[[SHMarkedHyperlink alloc] initWithString:[urlString retain]
                                                                  withValidationStatus:SH_URL_VALID
                                                                          parentString:omniTitleString? omniTitleString : urlString
                                                                              andRange:NSMakeRange(0,omniTitleString? [omniTitleString length] : [urlString length])] autorelease];
                                                                          
            [omniBookmarksMenu addItemWithTitle:omniTitleString? omniTitleString : urlString
                                            target:owner
                                            action:@selector(injectBookmarkFrom:)
                                     keyEquivalent:@""
                                 representedObject:markedLink];
        
        }else if(NSOrderedSame == [[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],4)] compare:@"/dl>"]){
            [linkScanner setScanLocation:[linkScanner scanLocation] + 4];
            if([omniBookmarksMenu isNotEqualTo:omniTopMenu]){
                omniBookmarksMenu = omniBookmarksSupermenu;
                omniBookmarksSupermenu = [omniBookmarksSupermenu supermenu];
            }
        }else{
            [linkScanner scanUpToString:@"<" intoString:nil];
            if(![linkScanner isAtEnd])
                [linkScanner setScanLocation:[linkScanner scanLocation] + 1];
        }
    }
}

@end
