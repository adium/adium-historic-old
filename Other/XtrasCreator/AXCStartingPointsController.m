//
//  AXCStartingPointsController.m
//  XtrasCreator
//
//  Created by Mac-arena the Bored Zo on 2005-10-31.
//  Copyright 2005 Adium Team. All rights reserved.
//

#import "AXCStartingPointsController.h"
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

		documentTypes = [temp copy];
		[temp release];
	}

	return documentTypes;
}

#pragma mark -
#pragma mark Actions

- (IBAction) makeNewDocumentOfSelectedType:(id)sender {
	int selection = [sender selectedRow];
	if (selection >= 0)
		[[NSDocumentController sharedDocumentController] openUntitledDocumentOfType:[documentTypes objectAtIndex:selection] display:YES];
}

#pragma mark -
#pragma mark NSTableView delegate conformance

- (void) tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)col row:(int)row {
	//if this is a valid type (has a class we can instantiate), enable it. else, disable it.
	[cell setEnabled:[usableDocTypes containsObject:[documentTypes objectAtIndex:row]]];
}

@end
