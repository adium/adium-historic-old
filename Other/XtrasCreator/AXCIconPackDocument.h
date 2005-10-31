//
//  AXCIconPackDocument.h
//  XtrasCreator
//
//  Created by Mac-arena the Bored Zo on 2005-10-30.
//  Copyright 2005 Adium Team. All rights reserved.
//

//used for Service and Status Icon packs.

#import "AXCAbstractXtraDocument.h"

@interface AXCIconPackDocument : AXCAbstractXtraDocument {
	NSArray *categoryNames;
	NSDictionary *categoryStorage; //keys: category names; values: NSArrays of icon keys

	NSArray *tabViewItems;
	IBOutlet NSView *topLevelView; //evil
	IBOutlet NSOutlineView *iconPlistView;
}

#pragma mark For subclasses

- (NSArray *) categoryNames;
//elements are kinds of AXCIconPackEntry
- (NSArray *) entriesInCategory:(NSString *)categoryName;
- (NSArray *) entriesForNewDocumentInCategory:(NSString *)categoryName;

@end
