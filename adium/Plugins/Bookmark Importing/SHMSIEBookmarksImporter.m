//
//  SHMSIEBookmarksImporter.m
//  Adium
//
//  Created by Stephen Holt on Mon May 31 2004.


#import "SHMSIEBookmarksImporter.h"

#define MSIE_BOOKMARKS_PATH  @"~/Library/Preferences/Explorer/Favorites.html"

#define MSIE_ROOT_MENU_TITLE AILocalizedString(@"Internet Explorer",nil)

@interface SHMSIEBookmarksImporter(PRIVATE)
- (void)parseBookmarksFile:(NSString *)inString;
@end

@implementation SHMSIEBookmarksImporter

static NSMenu   *msieBookmarksMenu = nil;
static NSMenu   *msieBookmarksSupermenu = nil;
static NSMenu   *msieTopMenu = nil;

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

#pragma mark protocol methods
+ (id)newInstanceOfImporter
{
    return [[[self alloc] init] autorelease];
}

-(NSMenu *)parseBookmarksForOwner:(id)inObject
{
    owner = inObject;
    NSString        *bookmarkString = [NSString stringWithContentsOfFile:[MSIE_BOOKMARKS_PATH stringByExpandingTildeInPath]];
    
    // remove our root menu, if it exists
    if(msieBookmarksMenu){
        [msieBookmarksMenu removeAllItems];
        [msieBookmarksMenu release];
    }
    
    // store the modification date for future reference
    if (lastModDate) [lastModDate release];
    NSDictionary *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:[MSIE_BOOKMARKS_PATH stringByExpandingTildeInPath] traverseLink:YES];
    lastModDate = [[fileProps objectForKey:NSFileModificationDate] retain];
    
    msieBookmarksMenu = [[[NSMenu alloc] initWithTitle:MSIE_ROOT_MENU_TITLE] autorelease];
    msieBookmarksSupermenu = msieBookmarksMenu;
    msieTopMenu = msieBookmarksMenu;
    [self parseBookmarksFile:bookmarkString];
    
    return msieBookmarksMenu;
}

-(BOOL)bookmarksExist
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[MSIE_BOOKMARKS_PATH stringByExpandingTildeInPath]];
}

-(NSString *)menuTitle
{
    return MSIE_ROOT_MENU_TITLE;
}

-(BOOL)bookmarksUpdated
{
    NSDictionary *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:[MSIE_BOOKMARKS_PATH stringByExpandingTildeInPath] traverseLink:YES];
    NSDate *modDate = [fileProps objectForKey:NSFileModificationDate];
    
    return ![modDate isEqualToDate:lastModDate];
}

#pragma mark private methods

- (void)parseBookmarksFile:(NSString *)inString
{
    NSScanner   *linkScanner = [NSScanner scannerWithString:inString];
    NSString    *titleString, *urlString;
    NSString    *untitledString = @"untitled";
    
    unsigned int        stringLength = [inString length];
    
    InitString(gtSign,@">")
    InitString(Hclose,@"</H")
    InitString(Hopen,@"H3 ")
    InitString(Aopen,@"A ")
    InitString(hrefStr,@"HREF=")
    InitString(closeQuote,@"\"")
    InitString(closeLink,@"\">")
    InitString(Aclose,@"</A")
    InitString(DLclose,@"/DL>")
    InitString(ltSign,@"<")
    
    NSCharacterSet  *quotesSet = [NSCharacterSet characterSetWithCharactersInString:@"'\""];
    
    while(![linkScanner isAtEnd]){
        if((stringLength - [linkScanner scanLocation]) < 4){
            [linkScanner setScanLocation:[inString length]];
        }else if(NSOrderedSame == [[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],3)] compare:Hopen]){
            if((stringLength - [linkScanner scanLocation]) > 3) [linkScanner setScanLocation:[linkScanner scanLocation] + 3];
            [linkScanner scanUpToString:gtSign intoString:nil];
            if((stringLength - [linkScanner scanLocation]) > 1) [linkScanner setScanLocation:[linkScanner scanLocation] + 1];
            [linkScanner scanUpToString:Hclose intoString:&titleString];

            if(titleString){
                // decode html stuff
                titleString = [[AIHTMLDecoder decodeHTML:titleString] string];
            }
            
            msieBookmarksSupermenu = msieBookmarksMenu;
            msieBookmarksMenu = [[[NSMenu alloc] initWithTitle:titleString? titleString : untitledString] autorelease];
        
            NSMenuItem *mozillaSubmenuItem = [[[NSMenuItem alloc] initWithTitle:titleString? titleString : untitledString
                                                                         target:owner
                                                                         action:nil
                                                                  keyEquivalent:@""] autorelease];
            [msieBookmarksSupermenu addItem:mozillaSubmenuItem];
            [msieBookmarksSupermenu setSubmenu:msieBookmarksMenu forItem:mozillaSubmenuItem];
        }else if(NSOrderedSame == [[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],2)] compare:Aopen]){
            [linkScanner scanUpToString:hrefStr intoString:nil];
            if((stringLength - [linkScanner scanLocation]) > 6) [linkScanner setScanLocation:[linkScanner scanLocation] + 6];
            [linkScanner scanUpToCharactersFromSet:quotesSet intoString:&urlString];
            [linkScanner scanUpToString:gtSign intoString:nil];
            if((stringLength - [linkScanner scanLocation]) > 1) [linkScanner setScanLocation:[linkScanner scanLocation] + 1];
            [linkScanner scanUpToString:Aclose intoString:&titleString];

            if(titleString){
                // decode html stuff
                titleString = [[AIHTMLDecoder decodeHTML:titleString] string];
            }
            
            SHMarkedHyperlink *markedLink = [[[SHMarkedHyperlink alloc] initWithString:[urlString retain]
                                                                  withValidationStatus:SH_URL_VALID
                                                                          parentString:titleString? titleString : urlString
                                                                              andRange:NSMakeRange(0,titleString? [titleString length] : [urlString length])] autorelease];
                                                                          
            [msieBookmarksMenu addItemWithTitle:titleString? titleString : urlString
                                            target:owner
                                            action:@selector(injectBookmarkFrom:)
                                     keyEquivalent:@""
                                 representedObject:markedLink];
        
        }else if(NSOrderedSame == [[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],4)] compare:DLclose]){
            if((stringLength - [linkScanner scanLocation]) > 4) [linkScanner setScanLocation:[linkScanner scanLocation] + 4];
            if([msieBookmarksMenu isNotEqualTo:msieTopMenu]){
                msieBookmarksMenu = msieBookmarksSupermenu;
                msieBookmarksSupermenu = [msieBookmarksSupermenu supermenu];
            }
        }else{
            [linkScanner scanUpToString:ltSign intoString:nil];
            if(![linkScanner isAtEnd])
                [linkScanner setScanLocation:[linkScanner scanLocation] + 1];
        }
    }
}

@end
