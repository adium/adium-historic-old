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
#import <AddressBook/ABPeoplePickerView.h>
#import "AIBookmarksImporterController.h"

/*!
 * @class SHABBookmarksImporter
 * @brief Address Book bookmarks importer
 */
@implementation SHABBookmarksImporter

- (void)dealloc {
	[peoplePicker release];
	[super dealloc];
}

#pragma mark -

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

- (NSView *)customView
{
	if(!peoplePicker) {
		peoplePicker = [[ABPeoplePickerView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 256.0, 256.0)];
		[peoplePicker setAutosaveName:[[NSBundle bundleForClass:[self class]] bundleIdentifier]];
		[peoplePicker setAllowsGroupSelection:YES];
		[peoplePicker setAllowsMultipleSelection:NO];
		[peoplePicker setValueSelectionBehavior:ABMultipleValueSelection];
		[peoplePicker setNameDoubleAction:@selector(_insertBookmarkFromPeoplePickerViewSelection:)];
		[peoplePicker setTarget:self];
	}
	return peoplePicker;
}

#pragma mark -

- (NSDictionary *)bookmarkForPerson:(ABPerson *)person
{
	NSDictionary *dict = nil;

	NSString *urlString = [person valueForProperty:kABHomePageProperty];
	if(urlString) {
		id firstName = [person valueForProperty:kABFirstNameProperty];
		id  lastName = [person valueForProperty:kABLastNameProperty];
		NSString *nameString = nil;
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
		NSImage *image = nil;
		NSData *imageData = [person imageData];
		if(imageData) {
			image = [[[NSImage alloc] initWithData:imageData] autorelease];
			[image setScalesWhenResized:YES];
			[image setSize:NSMakeSize(16.0, 16.0)];
		}

		dict = [[self class] dictionaryForBookmarksItemWithTitle:nameString
		                                                 content:[NSURL URLWithString:urlString]
		                                                   image:image];
	}

	return dict;
}

- (IBAction)_insertBookmarkFromPeoplePickerViewSelection:(id)sender
{
	if(!sender) sender = peoplePicker;
	[[AIBookmarksImporterController sharedController] insertLink:[self bookmarkForPerson:[[sender selectedRecords] lastObject]]];
}

@end
