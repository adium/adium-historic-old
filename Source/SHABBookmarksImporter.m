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
#import <AddressBook/AddressBook.h>

@implementation SHABBookmarksImporter

+ (NSString *)browserName
{
	return @"Address Book";
}

+ (NSString *)browserSignature
{
	return @"adrb";
}

+ (NSString *)browserBundleIdentifier
{
	return @"com.apple.AddressBook";
}

+ (BOOL)browserIsAvailable
{
	return ([self browserPath] != nil);
}

// +bookmarksPath intentionally not implemented
- (BOOL)bookmarksHaveChanged
{
	return YES;
}

#pragma mark -

+ (void)load
{
	AIBOOKMARKSIMPORTER_REGISTERWITHCONTROLLER();
}

- (NSArray *)availableBookmarks
{
	NSString		*nameString, *urlString;
	NSArray			*abPeople = [[ABAddressBook sharedAddressBook] people];
	NSEnumerator	*enumerator = [abPeople objectEnumerator];
	ABPerson		*person;
	NSMutableArray	*hyperlinks = [NSMutableArray array];

	while((person = [enumerator nextObject])){
		urlString = [person valueForProperty:kABHomePageProperty];
		if(urlString){
			id firstName = [person valueForProperty:kABFirstNameProperty];
			id lastName = [person valueForProperty:kABLastNameProperty];
			if(firstName || lastName){
				nameString = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
			}else{
				nameString = [NSString stringWithString:[person valueForProperty:kABOrganizationProperty]];
			}
			NSImage *image = nil;
			NSData *imageData = [person imageData];
			if(imageData) {
				image = [[[NSImage alloc] initWithData:imageData] autorelease];
				[image setScalesWhenResized:YES];
				[image setSize:NSMakeSize(16.0, 16.0)];
			}

			SHMarkedHyperlink	*menuLink = [[self class] hyperlinkForTitle:nameString URL:urlString];
			if(menuLink) {
				NSDictionary		*menuDict = [[self class] menuDictWithTitle:nameString
																		content:menuLink
																		  image:image];
				[hyperlinks addObject:menuDict];
			}
		}
	}

	return hyperlinks;
}

@end
