//
//  SHABBookmarksImporter.m
//  Adium
//
//  Created by Stephen Holt on Mon May 31 2004.

#import "SHABBookmarksImporter.h"

#define AB_ROOT_MENU_TITLE AILocalizedString(@"Address Book",nil)

@interface SHABBookmarksImporter(PRIVATE)
- (void)getUrlsFromAB;
@end

@implementation SHABBookmarksImporter

static NSMenu   *abBookmarksMenu;
static NSMenu   *abBookmarksSupermenu;
static NSMenu   *abTopMenu;

+ (id)newInstanceOfImporter
{
    return [[[self alloc] init] autorelease];
}

+(NSString *)importerTitle
{
    return AB_ROOT_MENU_TITLE;
}

-(NSMenu *)parseBookmarksForOwner:(id)inObject
{
    owner = inObject;
    //NSDictionary    *bookmarkDict = [NSDictionary dictionaryWithContentsOfFile:[SAFARI_BOOKMARKS_PATH stringByExpandingTildeInPath]];
    
    if(abBookmarksMenu){
        [abBookmarksMenu removeAllItems];
        [abBookmarksMenu release];
    }
    
//    if (lastModDate) [lastModDate release];
//    NSDictionary *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:[SAFARI_BOOKMARKS_PATH stringByExpandingTildeInPath] traverseLink:YES];
//    lastModDate = [[fileProps objectForKey:NSFileModificationDate] retain];
    
    abBookmarksMenu = [[[NSMenu alloc] initWithTitle:AB_ROOT_MENU_TITLE] autorelease];
    abBookmarksSupermenu = abBookmarksMenu;
    abTopMenu = abBookmarksMenu;
    [self getUrlsFromAB];
        
    return abBookmarksMenu;
}

-(BOOL)bookmarksExist
{
    return YES;
}

-(NSString *)menuTitle
{
    return AB_ROOT_MENU_TITLE;
}

-(BOOL)bookmarksUpdated
{
    return YES;
}

- (void)getUrlsFromAB
{
    NSString        *nameString, *urlString;
    ABAddressBook   *addressBook = [ABAddressBook sharedAddressBook];
    NSArray         *abPeople = [addressBook people];
    NSEnumerator    *enumerator = [abPeople objectEnumerator];
    
    ABPerson    *person;
    
    while(person = [enumerator nextObject]){
        if(urlString = [person valueForProperty:kABHomePageProperty]){
            if([person valueForProperty:kABFirstNameProperty] || [person valueForProperty:kABLastNameProperty]){
                nameString = [NSString stringWithFormat:@"%@ %@", [person valueForProperty:kABFirstNameProperty], [person valueForProperty:kABLastNameProperty]];
            }else{
                nameString = [NSString stringWithString:[person valueForProperty:kABOrganizationProperty]];
            }
            
            SHMarkedHyperlink *markedLink = [[[SHMarkedHyperlink alloc] initWithString:urlString
                                                                  withValidationStatus:SH_URL_VALID
                                                                          parentString:nameString
                                                                              andRange:NSMakeRange(0,[nameString length])] autorelease];
            [abBookmarksMenu addItemWithTitle:nameString
                                       target:owner
                                       action:@selector(injectBookmarkFrom:)
                                keyEquivalent:@""
                            representedObject:markedLink];
        }
    }
}
@end
