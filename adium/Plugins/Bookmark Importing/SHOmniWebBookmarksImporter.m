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

static NSMenu   *omniBookmarksMenu = nil;
static NSMenu   *omniBookmarksSupermenu = nil;
static NSMenu   *omniTopMenu = nil;

DeclareString(gtSign)
DeclareString(Hopen)
DeclareString(Aopen)
DeclareString(hrefStr)
DeclareString(closeQuote)
DeclareString(Aclose)
DeclareString(DLclose)
DeclareString(ltSign)

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
    NSString    *untitledString = @"untitled";
    
    unsigned int stringLength = [inString length];
    
    NSCharacterSet  *quotesSet = [NSCharacterSet characterSetWithCharactersInString:@"'\""];
    
    [linkScanner setCaseSensitive:NO];
    
    InitString(gtSign,@">")
    InitString(Hopen,@"h3")
    InitString(Aopen,@"a ")
    InitString(hrefStr,@"href=")
    InitString(closeQuote,@"\"")
    InitString(Aclose,@"</a")
    InitString(DLclose,@"/dl>")
    InitString(ltSign,@"<")
    
    while(![linkScanner isAtEnd]){
        if((stringLength - [linkScanner scanLocation]) < 4){
            [linkScanner setScanLocation:[inString length]];
        }else if(NSOrderedSame == [[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],2)] compare:Hopen]){
            if((stringLength - [linkScanner scanLocation]) > 2) [linkScanner setScanLocation:[linkScanner scanLocation] + 2];
            [linkScanner scanUpToString:Aopen intoString:nil];
            if((stringLength - [linkScanner scanLocation]) > 2) [linkScanner setScanLocation:[linkScanner scanLocation] + 2];
            [linkScanner scanUpToString:gtSign intoString:nil];
            if((stringLength - [linkScanner scanLocation]) > 1) [linkScanner setScanLocation:[linkScanner scanLocation] + 1];
            [linkScanner scanUpToString:Aclose intoString:&omniTitleString];

            if(omniTitleString){
                // decode html stuff
                omniTitleString = [[AIHTMLDecoder decodeHTML:omniTitleString] string];
            }
            
            omniBookmarksSupermenu = omniBookmarksMenu;
            omniBookmarksMenu = [[[NSMenu alloc] initWithTitle:omniTitleString? omniTitleString : untitledString] autorelease];
        
            NSMenuItem *mozillaSubmenuItem = [[[NSMenuItem alloc] initWithTitle:omniTitleString? omniTitleString : untitledString
                                                                         target:owner
                                                                         action:nil
                                                                  keyEquivalent:@""] autorelease];
            [omniBookmarksSupermenu addItem:mozillaSubmenuItem];
            [omniBookmarksSupermenu setSubmenu:omniBookmarksMenu forItem:mozillaSubmenuItem];
        }else if(NSOrderedSame == [[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],2)] compare:Aopen]){
            [linkScanner scanUpToString:hrefStr intoString:nil];
            if((stringLength - [linkScanner scanLocation]) > 6) [linkScanner setScanLocation:[linkScanner scanLocation] + 6];
            [linkScanner scanUpToCharactersFromSet:quotesSet intoString:&urlString];

            [linkScanner scanUpToString:gtSign intoString:nil];
            if((stringLength - [linkScanner scanLocation]) > 1) [linkScanner setScanLocation:[linkScanner scanLocation] + 1];
            [linkScanner scanUpToString:Aclose intoString:&omniTitleString];
            
            if(omniTitleString){
                // decode html stuff
                omniTitleString = [[AIHTMLDecoder decodeHTML:omniTitleString] string];
            }

            SHMarkedHyperlink *markedLink = [[[SHMarkedHyperlink alloc] initWithString:[urlString retain]
                                                                  withValidationStatus:SH_URL_VALID
                                                                          parentString:omniTitleString? omniTitleString : urlString
                                                                              andRange:NSMakeRange(0,omniTitleString? [omniTitleString length] : [urlString length])] autorelease];
                                                                          
            [omniBookmarksMenu addItemWithTitle:omniTitleString? omniTitleString : urlString
                                            target:owner
                                            action:@selector(injectBookmarkFrom:)
                                     keyEquivalent:@""
                                 representedObject:markedLink];
        
        }else if(NSOrderedSame == [[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],4)] compare:DLclose]){
            if((stringLength - [linkScanner scanLocation]) > 4) [linkScanner setScanLocation:[linkScanner scanLocation] + 4];
            if([omniBookmarksMenu isNotEqualTo:omniTopMenu]){
                omniBookmarksMenu = omniBookmarksSupermenu;
                omniBookmarksSupermenu = [omniBookmarksSupermenu supermenu];
            }
        }else{
            [linkScanner scanUpToString:ltSign intoString:nil];
            if(![linkScanner isAtEnd])
                [linkScanner setScanLocation:[linkScanner scanLocation] + 1];
        }
    }
}

@end
