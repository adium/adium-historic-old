/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "SHABBookmarksImporter.h"

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
    
    abBookmarksMenu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:AB_ROOT_MENU_TITLE] autorelease];
    abBookmarksSupermenu = abBookmarksMenu;
    abTopMenu = abBookmarksMenu;
    [self getUrlsFromAB];
        
    return abBookmarksMenu;
}

-(BOOL)bookmarksExist
{
    return YES;
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
