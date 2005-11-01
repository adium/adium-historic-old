//
//  AXCStartingPointsController.m
//  XtrasCreator
//
//  Created by Mac-arena the Bored Zo on 2005-10-31.
//  Copyright 2005 Adium Team. All rights reserved.
//

#import "AXCStartingPointsController.h"

#import "AXCDocumentController.h"
#import "NSMutableArrayAdditions.h"

@implementation AXCStartingPointsController

- (void) awakeFromNib {
	if (!startingPointsWindow) {
		[NSBundle loadNibNamed:@"StartingPoints" owner:self];
		if(![startingPointsWindow setFrameUsingName:[startingPointsWindow frameAutosaveName]])
			[startingPointsWindow center];
		[startingPointsWindow makeKeyAndOrderFront:nil];

		[startingPointsTableView setDoubleAction:@selector(makeNewDocumentOfSelectedType:)];
		[startingPointsTableView setTarget:self];
	}
}

- (void) dealloc {
	[documentTypes release];
	[usableDocTypes release];
	[startingPointsWindow release];

	[super dealloc];
}

#pragma mark -

- (NSArray *) documentTypes {
	if (!documentTypes) {
		NSDictionary *typeDicts = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDocumentTypes"];
		unsigned numTypes = [typeDicts count];
		NSMutableArray *temp = [[NSMutableArray alloc] initWithCapacity:numTypes];
		usableDocTypes = [[NSMutableSet alloc] initWithCapacity:numTypes];

		NSEnumerator *typeDictsEnum = [typeDicts objectEnumerator];
		NSDictionary *typeDict;
		while ((typeDict = [typeDictsEnum nextObject])) {
			NSString *name = [typeDict objectForKey:@"CFBundleTypeName"];
			unsigned newIdx = [temp indexForInsortingObject:name usingSelector:@selector(caseInsensitiveCompare:)];
			[temp insertObject:name atIndex:newIdx];

			if (NSClassFromString([typeDict objectForKey:@"NSDocumentClass"]))
				[usableDocTypes addObject:name];
		}

		[temp sortUsingSelector:@selector(caseInsensitiveCompare:)];

		documentTypes = [temp copy];
		[temp release];
	}

	return documentTypes;
}

- (void) setStartingPointsVisible:(BOOL)flag {
	if (flag)
		[startingPointsWindow makeKeyAndOrderFront:nil];
	else
		[startingPointsWindow orderOut:nil];
}
- (BOOL) isStartingPointsVisible {
	return [startingPointsWindow isVisible];
}

#pragma mark -
#pragma mark Actions

- (IBAction) makeNewDocumentOfSelectedType:(id)sender {
	int selection = [sender selectedRow];
	if (selection >= 0)
		[[AXCDocumentController sharedDocumentController] openUntitledDocumentOfType:[documentTypes objectAtIndex:selection] display:YES];
}
- (IBAction) makeNewDocumentWithTypeBeingTitleOfMenuItem:(NSMenuItem *)sender {
	[[AXCDocumentController sharedDocumentController] openUntitledDocumentOfType:[sender title] display:YES];
}

- (IBAction) displayStartingPoints:(id)sender {
	[self setStartingPointsVisible:YES];
}

#pragma mark -
#pragma mark NSTableView delegate conformance

- (void) tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)col row:(int)row {
	//if this is a valid type (has a class we can instantiate), enable it. else, disable it.
	[cell setEnabled:[usableDocTypes containsObject:[documentTypes objectAtIndex:row]]];
}

#pragma mark -
#pragma mark NSMenu delegate conformance

- (int) numberOfItemsInMenu:(NSMenu *)menu {
	return [[self documentTypes] count];
}
- (BOOL) menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(int)index shouldCancel:(BOOL)shouldCancel {
	[item setTitle:[[self documentTypes] objectAtIndex:index]];

	[item setAction:@selector(makeNewDocumentWithTypeBeingTitleOfMenuItem:)];
	[item setTarget:self];

	return !shouldCancel;
}

@end
