//
//  SHOmniWebBookmarksImporter.m
//  Adium
//
//  Created by Stephen Holt on Mon May 31 2004.

#import "SHOmniWebBookmarksImporter.h"
#import "SHMozillaCommonParser.h"

#define OW45_BOOKMARKS_PATH     @"~/Library/Application Support/OmniWeb/Bookmarks.html"
#define OW5_BOOKMARKS_PATH      @"~/Library/Application Support/OmniWeb 5/Favorites.html"

#define OW45_ROOT_MENU_TITLE    AILocalizedString(@"OmniWeb 4.5",nil)
#define OW5_ROOT_MENU_TITLE     AILocalizedString(@"OmniWeb 5",nil)
#define OW_TITLE                AILocalizedString(@"OmniWeb",nil);

@class SHMozillaCommonParser;

@interface SHOmniWebBookmarksImporter(PRIVATE)
- (NSArray *)parseBookmarksFile:(NSString *)inString;
-(SHMarkedHyperlink *)hyperlinkForTitle:(NSString *)inString URL:(NSString *)inURLString;
-(NSDictionary *)menuDictWithTitle:(NSString *)inTitle menuItems:(NSArray *)inMenuItems;
@end

@implementation SHOmniWebBookmarksImporter

DeclareString(gtSign)
DeclareString(Hopen)
DeclareString(Aopen)
DeclareString(hrefStr)
DeclareString(closeQuote)
DeclareString(Aclose)
DeclareString(DLclose)
DeclareString(ltSign)
//DeclareString(untitledString)
DeclareString(bookmarkDictTitle)
DeclareString(bookmarkDictContent)

#pragma mark protocol methods
+ (id)newInstanceOfImporter
{
    return [[[self alloc] init] autorelease];
}


- (id)init
{
    useOW5 = [[NSFileManager defaultManager] fileExistsAtPath:[OW5_BOOKMARKS_PATH stringByExpandingTildeInPath]];
    [super init];
    
    InitString(bookmarkDictTitle,SH_BOOKMARK_DICT_TITLE)
    InitString(bookmarkDictContent,SH_BOOKMARK_DICT_CONTENT)
    
    return self;
}

- (NSArray *)availableBookmarks
{
    NSString    *bookmarkPath = useOW5? [OW5_BOOKMARKS_PATH stringByExpandingTildeInPath] : [OW45_BOOKMARKS_PATH stringByExpandingTildeInPath];
    NSString    *bookmarkString = [NSString stringWithContentsOfFile:bookmarkPath];
    
    NSDictionary    *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:bookmarkPath traverseLink:YES];
    [lastModDate autorelease]; lastModDate = [[fileProps objectForKey:NSFileModificationDate] retain];
    
    return [self parseBookmarksFile:bookmarkString];
}


-(BOOL)bookmarksExist
{
    return (useOW5 || [[NSFileManager defaultManager] fileExistsAtPath:[OW45_BOOKMARKS_PATH stringByExpandingTildeInPath]]);
}


-(BOOL)bookmarksUpdated
{
    NSDictionary *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:useOW5? [OW5_BOOKMARKS_PATH stringByExpandingTildeInPath] : [OW45_BOOKMARKS_PATH stringByExpandingTildeInPath] traverseLink:YES];
    NSDate *modDate = [fileProps objectForKey:NSFileModificationDate];
    
    return ![modDate isEqualToDate:lastModDate];
}

#pragma mark private methods
- (NSArray *)parseBookmarksFile:(NSString *)inString
{
    NSMutableArray      *bookmarksArray = [NSMutableArray array];
    NSMutableArray      *arrayStack = [NSMutableArray array];
    NSScanner   *linkScanner = [NSScanner scannerWithString:inString];
    NSString    *omniTitleString = nil;
    NSString    *urlString = nil;
    
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
    //InitString(untitledString,@"untitled")
    
    while(![linkScanner isAtEnd]){
        if((stringLength - [linkScanner scanLocation]) < 4){
            [linkScanner setScanLocation:[inString length]];
        }else if([[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],2)] isEqualToString:Hopen]){
            if((stringLength - [linkScanner scanLocation]) > 2) [linkScanner setScanLocation:[linkScanner scanLocation] + 2];
            [linkScanner scanUpToString:Aopen intoString:nil];
            if((stringLength - [linkScanner scanLocation]) > 2) [linkScanner setScanLocation:[linkScanner scanLocation] + 2];
            [linkScanner scanUpToString:gtSign intoString:nil];
            if((stringLength - [linkScanner scanLocation]) > 1) [linkScanner setScanLocation:[linkScanner scanLocation] + 1];
            
            if([linkScanner scanUpToString:Aclose intoString:&omniTitleString]){
                // decode html stuff
                omniTitleString = [SHMozillaCommonParser simplyReplaceHTMLCodes:omniTitleString];
            }else{
                [omniTitleString release];
                omniTitleString = nil;
            }
            
            [arrayStack addObject:bookmarksArray];
            bookmarksArray = [NSMutableArray array];
            [(NSMutableArray *)[arrayStack lastObject] addObject:[self menuDictWithTitle:omniTitleString
                                                             menuItems:bookmarksArray]];
                                                             
        }else if([[[linkScanner string] substringWithRange:NSMakeRange([linkScanner scanLocation],2)] isEqualToString:Aopen]){
            [linkScanner scanUpToString:hrefStr intoString:nil];
            if((stringLength - [linkScanner scanLocation]) > 6) [linkScanner setScanLocation:[linkScanner scanLocation] + 6];
            if([linkScanner scanUpToCharactersFromSet:quotesSet intoString:&urlString]){
                [linkScanner scanUpToString:gtSign intoString:nil];
                if((stringLength - [linkScanner scanLocation]) > 1) [linkScanner setScanLocation:[linkScanner scanLocation] + 1];
            
                if([linkScanner scanUpToString:Aclose intoString:&omniTitleString]){
                    // decode html stuff
                    omniTitleString = [SHMozillaCommonParser simplyReplaceHTMLCodes:omniTitleString];
                }else{
                    [omniTitleString release];
                    omniTitleString = nil;
                }

                [bookmarksArray addObject:[self hyperlinkForTitle:omniTitleString URL:urlString]];

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
    NSString    *title = inString? inString : @"untitled";
    return [[[SHMarkedHyperlink alloc] initWithString:inURLString
                                 withValidationStatus:SH_URL_VALID
                                         parentString:title
                                             andRange:NSMakeRange(0,[title length])] autorelease];
}

-(NSDictionary *)menuDictWithTitle:(NSString *)inTitle menuItems:(NSArray *)inMenuItems
{
    NSString    *titleString = inTitle? inTitle : @"untitled";
    return [NSDictionary dictionaryWithObjectsAndKeys:titleString, bookmarkDictTitle, inMenuItems, bookmarkDictTitle, nil];
}

@end
