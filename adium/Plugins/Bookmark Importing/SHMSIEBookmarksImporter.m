//
//  SHMSIEBookmarksImporter.m
//  Adium
//
//  Created by Stephen Holt on Mon May 31 2004.


#import "SHMSIEBookmarksImporter.h"
#import "SHMozillaCommonParser.h"

#define MSIE_BOOKMARKS_PATH  @"~/Library/Preferences/Explorer/Favorites.html"

#define MSIE_ROOT_MENU_TITLE AILocalizedString(@"Internet Explorer",nil)

@class SHMozillaCommonParser;

@interface SHMSIEBookmarksImporter(PRIVATE)
- (NSArray *)parseBookmarksFile:(NSString *)inString;
-(SHMarkedHyperlink *)hyperlinkForTitle:(NSString *)inString URL:(NSString *)inURLString;
-(NSDictionary *)menuDictWithTitle:(NSString *)inTitle menuItems:(NSArray *)inMenuItems;
@end

@implementation SHMSIEBookmarksImporter

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

DeclareString(untitledString)
DeclareString(bookmarkDictTitle)
DeclareString(bookmarkDictContent)

#pragma mark protocol methods
+ (id)newInstanceOfImporter
{
    return [[[self alloc] init] autorelease];
}

-(id)init
{
    [super init];
    
    InitString(bookmarkDictTitle,SH_BOOKMARK_DICT_TITLE)
    InitString(bookmarkDictContent,SH_BOOKMARK_DICT_CONTENT)
    
    return self;
}

- (NSArray *)availableBookmarks
{
    NSString    *bookmarkPath = [MSIE_BOOKMARKS_PATH stringByExpandingTildeInPath];
    NSString    *bookmarkString = [NSString stringWithContentsOfFile:bookmarkPath];
    
    NSDictionary    *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:bookmarkPath traverseLink:YES];
    [lastModDate autorelease]; lastModDate = [[fileProps objectForKey:NSFileModificationDate] retain];
    
    return [self parseBookmarksFile:bookmarkString];
}

-(BOOL)bookmarksExist
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[MSIE_BOOKMARKS_PATH stringByExpandingTildeInPath]];
}

-(BOOL)bookmarksUpdated
{
    NSDictionary *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:[MSIE_BOOKMARKS_PATH stringByExpandingTildeInPath] traverseLink:YES];
    NSDate *modDate = [fileProps objectForKey:NSFileModificationDate];
    
    return ![modDate isEqualToDate:lastModDate];
}

#pragma mark private methods

- (NSArray *)parseBookmarksFile:(NSString *)inString
{
    NSMutableArray      *bookmarksArray = [NSMutableArray array];
    NSMutableArray      *arrayStack = [NSMutableArray array];
    NSScanner   *linkScanner = [NSScanner scannerWithString:inString];
    NSString    *titleString, *urlString;
    
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
    InitString(untitledString,@"untitled")
    
    NSCharacterSet  *quotesSet = [NSCharacterSet characterSetWithCharactersInString:@"'\""];
    
    while(![linkScanner isAtEnd]){
        if((stringLength - [linkScanner scanLocation]) < 4){
            [linkScanner setScanLocation:[inString length]];
        }else if([[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],3)] isEqualToString:Hopen]){
            if((stringLength - [linkScanner scanLocation]) > 3) [linkScanner setScanLocation:[linkScanner scanLocation] + 3];
            [linkScanner scanUpToString:gtSign intoString:nil];
            if((stringLength - [linkScanner scanLocation]) > 1) [linkScanner setScanLocation:[linkScanner scanLocation] + 1];
            if([linkScanner scanUpToString:Hclose intoString:&titleString]){
                // decode html stuff
                titleString = [SHMozillaCommonParser simplyReplaceHTMLCodes:titleString];
            }else{
                [titleString release];
                titleString = nil;
            }
            
            [arrayStack addObject:bookmarksArray];
            bookmarksArray = [NSMutableArray array];
            [[arrayStack lastObject] addObject:[self menuDictWithTitle:titleString
                                                             menuItems:bookmarksArray]];

        }else if([[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],2)] isEqualToString:Aopen]){
            [linkScanner scanUpToString:hrefStr intoString:nil];
            if((stringLength - [linkScanner scanLocation]) > 6) [linkScanner setScanLocation:[linkScanner scanLocation] + 6];
            
            if([linkScanner scanUpToCharactersFromSet:quotesSet intoString:&urlString]){
                [linkScanner scanUpToString:gtSign intoString:nil];
                if((stringLength - [linkScanner scanLocation]) > 1) [linkScanner setScanLocation:[linkScanner scanLocation] + 1];
            
                if([linkScanner scanUpToString:Aclose intoString:&titleString]){
                    // decode html stuff
                    titleString = [SHMozillaCommonParser simplyReplaceHTMLCodes:titleString];
                }else{
                    [titleString release];
                    titleString = nil;
                }
            
                [bookmarksArray addObject:[self hyperlinkForTitle:titleString URL:urlString]];
            }
        }else if([[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],4)] isEqualToString:DLclose]){
            if((stringLength - [linkScanner scanLocation]) > 4) [linkScanner setScanLocation:[linkScanner scanLocation] + 4];
            if([arrayStack count]){
                bookmarksArray = [arrayStack lastObject];
                [arrayStack removeLastObject];
            }
        }else{
            [linkScanner scanUpToString:ltSign intoString:nil];
            if(![linkScanner isAtEnd])
                [linkScanner setScanLocation:[linkScanner scanLocation] + 1];
        }
    }
    return bookmarksArray;
}

-(SHMarkedHyperlink *)hyperlinkForTitle:(NSString *)inString URL:(NSString *)inURLString
{
    NSString    *title = inString? inString : untitledString;
    return [[[SHMarkedHyperlink alloc] initWithString:inURLString
                                 withValidationStatus:SH_URL_VALID
                                         parentString:title
                                             andRange:NSMakeRange(0,[title length])] autorelease];
}

-(NSDictionary *)menuDictWithTitle:(NSString *)inTitle menuItems:(NSArray *)inMenuItems
{
    NSString    *titleString = inTitle ? inTitle : untitledString;
    return [NSDictionary dictionaryWithObjectsAndKeys:titleString, bookmarkDictTitle, inMenuItems, bookmarkDictContent, nil];
}
@end
