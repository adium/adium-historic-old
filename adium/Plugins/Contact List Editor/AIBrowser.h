//
//  AIBrowser.h
//  Adium XCode
//
//  Created by Adam Iser on Sun Jan 11 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@class AIBrowserColumn;

@interface AIBrowser : NSView {
	NSMutableArray	*columnArray;
	id				dataSource;
	BOOL			ignoreSelectionChanges; //Temporarily ignore selection changes
}

- (void)setDataSource:(id)inDataSource;
- (id)dataSource;
- (void)reloadData;
- (void)sizeToFit;
- (id)selectedItems;
- (id)selectedColumn;

@end

@interface NSObject (AIBrowserViewDelegate)

- (id)browserView:(AIBrowser *)browserView child:(int)index ofItem:(id)item;
- (BOOL)browserView:(AIBrowser *)browserView isItemExpandable:(id)item;
- (int)browserView:(AIBrowser *)browserView numberOfChildrenOfItem:(id)item;
- (id)browserView:(AIBrowser *)browserView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;

@end
