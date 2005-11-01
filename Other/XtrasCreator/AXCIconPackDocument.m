//
//  AXCIconPackDocument.m
//  XtrasCreator
//
//  Created by Mac-arena the Bored Zo on 2005-10-30.
//  Copyright 2005 Adium Team. All rights reserved.
//

#import "AXCIconPackDocument.h"
#import "NSMutableArrayAdditions.h"
#import "AXCIconPackEntry.h"

//columns of the icon keys outline view.
#define KEY_COLUMN_NAME @"key"
#define RESOURCE_COLUMN_NAME @"file"

@implementation AXCIconPackDocument

- (id) init
{
	if ((self = [super init])) {
		categoryNames = [[self categoryNames] copy];

		NSMutableDictionary *temp = [[NSMutableDictionary alloc] initWithCapacity:[categoryNames count]];
		NSEnumerator *categoryNamesEnum = [categoryNames objectEnumerator];
		NSString *categoryName;
		while ((categoryName = [categoryNamesEnum nextObject]))
			[temp setObject:[[[self entriesForNewDocumentInCategory:categoryName] mutableCopy] autorelease] forKey:categoryName];

		categoryStorage = [temp copy];
		[temp release];
	}
	return self;
}

- (void) dealloc
{
	[categoryNames release];
	[categoryStorage release];

	[iconPlistView release];
	[tabViewItems release];

	[super dealloc];
}

#pragma mark Document nature

- (BOOL) writeToFile:(NSString *)fileName ofType:(NSString *)docType
{
#warning XXX pickle Info.plist here
	return NO;
}

- (BOOL) readFromFile:(NSString *)path ofType:(NSString *)type
{
#warning XXX unpickle Info.plist here
	return NO;
}

#pragma mark Bindings

//use this, NOT -categoryNames, for bindings.
- (NSArray *) categoryNamesArray
{
	return categoryNames;
}

#pragma mark Outline view data source conformance

- (id) outlineView:(NSOutlineView *)outlineView child:(int)idx ofItem:(id)item
{
	if (!item) //return a category name
		return [categoryNames objectAtIndex:idx];
	else //return category storage
		return [[categoryStorage objectForKey:item] objectAtIndex:idx];
}
- (BOOL) outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return ([categoryStorage objectForKey:item] != nil);
}
- (int) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (!item)
		return [categoryNames count];

	NSDictionary *storage = [categoryStorage objectForKey:item];
	if (storage)
		return [storage count];
	else
		return 0;
}

- (id) outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)col byItem:(id)item
{
	BOOL isKeyColumn = [KEY_COLUMN_NAME isEqualToString:[col identifier]];
	unsigned categoryIndex = [categoryNames indexOfObjectIdenticalTo:item];

	if (categoryIndex != NSNotFound)
		return isKeyColumn ? item : [NSNumber numberWithInt:-1];
	else
		return isKeyColumn ? (NSObject *)[item key] : (NSObject *)[NSNumber numberWithUnsignedInt:[resources indexOfObject:[item path]]];
}
- (void) outlineView:(NSOutlineView *)outlineView setObjectValue:(id)newValue forTableColumn:(NSTableColumn *)col byItem:(id)item
{
	int index = [(NSNumber *)newValue intValue];
	if (index > -1)
		[(AXCIconPackEntry *)item setPath:[resources objectAtIndex:index]];
	else
		[(AXCIconPackEntry *)item setPath:nil];
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index
{
	NSArray *plist = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];

	if ([item isKindOfClass:[AXCIconPackEntry class]] //it's an icon pack entry
		&& ([plist count] == 1) //the user is only dragging one file
		&& (index == NSOutlineViewDropOnItemIndex) //we're dropping onto the entry
	) {
		return NSDragOperationLink;
	} else
		return NSDragOperationNone;
}
- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index
{
	[(AXCIconPackEntry *)item setPath:[[[info draggingPasteboard] propertyListForType:NSFilenamesPboardType] objectAtIndex:0]];
	return YES;
}

#pragma mark NSOutlineView delegate conformance

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	if ([cell isKindOfClass:[NSPopUpButtonCell class]]) {
		if ([categoryNames containsObject:item]) {
			[cell setMenu:emptyMenu];
			[cell setArrowPosition:NSPopUpNoArrow]; //hide arrow for categories
		} else {
			[cell setMenu:menuWithResourceFiles];
			[cell setArrowPosition:NSPopUpArrowAtBottom]; //show arrow for item pairs

			//we have to do this because of an NSMenu bug.
			//http://www.corbinstreehouse.com/blog/archives/2005/07/dynamically_pop.html
			[[cell menu] setDelegate:self];

			//this is lame but necessary too.
			if (![item path])
				[cell selectItemAtIndex:-1];
		}
	}
}

#pragma mark NSMenu delegate conformance

- (int) numberOfItemsInMenu:(NSMenu *)menu
{
	return [resources count];
}
- (BOOL) menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(int)index shouldCancel:(BOOL)shouldCancel
{
	NSString *path = [resources objectAtIndex:index];
	[item setTitle:[displayNames  objectForKey:path]];
	[item setImage:[imagePreviews objectForKey:path]];
	return !shouldCancel;
}

#pragma mark Implementation of Xtra-document methods

- (NSArray *) tabViewItems
{
	if (!tabViewItems) {
		if (!iconPlistView)
			[NSBundle loadNibNamed:@"IconPack_IconPlistView" owner:self];

		NSTabViewItem *tvi = [[NSTabViewItem alloc] initWithIdentifier:@"IconPlist"];
		[tvi setView:topLevelView];
		[tvi setLabel:@"Icon keys"]; //XXX LOCALIZEME

		tabViewItems = [[NSArray alloc] initWithObjects:&tvi count:1];
		[tvi release];
	}

	return tabViewItems;
}

#pragma mark Implementation of icon-pack abstract methods

- (NSArray *) categoryNames
{
	return [NSArray array];
}

- (NSArray *) entriesInCategory:(NSString *)categoryName
{
	return [categoryStorage objectForKey:categoryName];
}

- (NSArray *) entriesForNewDocumentInCategory:(NSString *)categoryName
{
	return [NSArray array];
}

@end
