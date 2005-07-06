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

#import "AIBookmarksImporterController.h"

/*!
 * @class SHABBookmarksImporter
 * @brief Address Book bookmarks importer
 */
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

- (void)dealloc
{
	[addressBookFrameworkBundle release];
	[addressBookAppBundle       release];

	[super dealloc];
}

#pragma mark -

//extract an image from either the Address Book framework or the Address Book application.
- (NSImage *)imageFromAddressBook:(NSString *)name
{
	if(!addressBookFrameworkBundle) {
		addressBookFrameworkBundle = [[NSBundle bundleWithPath:@"/System/Library/Frameworks/AddressBook.framework"] retain];
	}
	NSImage *image = [[NSImage alloc] initByReferencingFile:[addressBookFrameworkBundle pathForImageResource:name]];
	if(!image) {
		if(!addressBookAppBundle) {
			addressBookAppBundle = [[NSBundle bundleWithPath:[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.apple.AddressBook"]] retain];
		}
		image = [[NSImage alloc] initByReferencingFile:[addressBookAppBundle pathForImageResource:name]];
	}
	return [image autorelease];
}

- (NSImage *)personIcon
{
	NSImage   *image = [self imageFromAddressBook:@"vCard.icns"]; //prefer IconFamily to TIFF
	if(!image) image = [self imageFromAddressBook:@"vCard"];
	if(!image) image = [self imageFromAddressBook:@"SingleCard"]; //this one comes from the framework
	return image;
}
- (NSImage *)groupIcon
{
	return [self imageFromAddressBook:@"MultipleCards32"];
}

#pragma mark -

- (NSArray *)URLsForPerson:(ABPerson *)person
{
	ABMultiValue *multiValue = [person valueForProperty:@"URLs"]; //we use the string literal here for Panther compatibility.
	if(multiValue) {
		unsigned numValues = [multiValue count];
		NSMutableArray *URLs = [NSMutableArray arrayWithCapacity:numValues];
		for(unsigned i = 0; i < numValues; ++i) {
			[URLs addObject:[NSURL URLWithString:[multiValue valueAtIndex:i]]];
		}
		return URLs;
	} else {
		NSString *URLString = [person valueForProperty:kABHomePageProperty];
		if(URLString) return [NSArray arrayWithObject:[NSURL URLWithString:URLString]];
	}
	return [NSArray array];
}

- (NSDictionary *)bookmarkForPerson:(ABPerson *)person
{
	NSDictionary *bookmark = nil;

	NSArray *URLs = [self URLsForPerson:person];
	unsigned numURLs = [URLs count];
	if(numURLs) {
		//get their name as one string, for the title of the bookmark.
		NSString *nameString = nil;
		id firstName = [person valueForProperty:kABFirstNameProperty];
		id  lastName = [person valueForProperty:kABLastNameProperty];
		if(firstName && lastName) {
			//we have both; join them with a space.
			nameString = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
		} else if(firstName || lastName) {
			//we only have one.
			nameString = [[(firstName ? firstName : lastName) retain] autorelease];
		} else {
			//we have neither; use the organisation name and hope it's a company's card.
			nameString = [NSString stringWithString:[person valueForProperty:kABOrganizationProperty]];
		}

		/*get the person's user icon, or the generic vCard icon if none.
		 *this is used as the favicon of the bookmark.
		 */
		NSImage *image = nil;
		NSData *imageData = [person imageData];
		if(imageData) {
			image = [[[NSImage alloc] initWithData:imageData] autorelease];
		} else {
			image = [self personIcon];
		}

		if(numURLs == 1) {
			bookmark = [[self class] dictionaryForBookmarksItemWithTitle:nameString
																 content:[URLs lastObject]
																   image:image];
		} else {
			//multiple URLs - create one bookmark for each one.
			NSMutableArray *subBookmarks = [NSMutableArray arrayWithCapacity:numURLs];

			NSEnumerator *URLsEnum = [URLs objectEnumerator];
			NSURL *URL;
			while((URL = [URLsEnum nextObject])) {
				NSDictionary *thisSubBookmark = [[self class] dictionaryForBookmarksItemWithTitle:nameString
																						  content:URL
																							image:image
																				 appendURIToTitle:YES];
				[subBookmarks addObject:thisSubBookmark];
			}

			bookmark = [[self class] dictionaryForBookmarksItemWithTitle:nameString
																 content:subBookmarks
																   image:image];
		}
	}
	return bookmark;
}

- (NSArray *)availableBookmarks
{
	ABAddressBook	*addressBook = [ABAddressBook sharedAddressBook];

	//first, build a flat list of all People.
	NSArray			*people = [addressBook people];
	NSEnumerator	*peopleEnum = [people objectEnumerator];
	ABPerson		*person;

	unsigned			 numPeople = [people count];
	NSMutableArray		*result = [NSMutableArray arrayWithCapacity:numPeople];

	while((person = [peopleEnum nextObject])) {
		NSDictionary *bookmark = [self bookmarkForPerson:person];
		if(bookmark) [result addObject:bookmark];
	}

	NSArray *groups = [addressBook groups];
	if([groups count]) {
		//create the 'All' group from the flat list. it should have the Address Book icon.
		NSAttributedString *nameOfAllGroup = [[AIBookmarksImporterController sharedController] attributedStringByItalicizingString:NSLocalizedString(@"All", @"Address Book importer")];
		NSDictionary *bookmark = [[self class] dictionaryForBookmarksItemWithTitle:(NSString *)nameOfAllGroup
																		   content:result
																			 image:[[self class] browserIcon]];

		/*we used the old result array as the content for the 'All' group,
		 *	so create a new one with enough capacity for all the AB groups plus our 'All' group,
		 *	and insert the 'All' group into it as its first item.
		 */
		result = [NSMutableArray arrayWithCapacity:([groups count] + (bookmark != nil))];
		if(bookmark) [result addObject:bookmark];

		//now create the bookmark groups from the AB groups.
		NSEnumerator *groupsEnum = [groups objectEnumerator];
		ABGroup *group;
		while((group = [groupsEnum nextObject])) {
			people = [group members];

			NSMutableArray *bookmarks = [NSMutableArray arrayWithCapacity:[people count]];

			//create the bookmark dictionaries for each person...
			peopleEnum = [people objectEnumerator];
			while((person = [peopleEnum nextObject])) {
				bookmark = [self bookmarkForPerson:person];
				if(bookmark) [bookmarks addObject:bookmark];
			}

			//...and the group itself.
			bookmark = [[self class] dictionaryForBookmarksItemWithTitle:[group valueForProperty:kABGroupNameProperty]
																 content:bookmarks
																   image:[self groupIcon]];
			if(bookmark) [result addObject:bookmark];
		}
	}

	return result;
}

@end
