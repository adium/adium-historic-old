//
//  RAFDragArrayController.h
//  Adium
//
//  Created by Augie Fackler on 7/6/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium,AIListObject;

@interface RAFDragArrayController : NSArrayController {
	IBOutlet NSTableView *tableView;
	AIAdium *adium;
	NSArray *dragItems;
}

- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard;
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op;
- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op;
- (void)addListObjectToList:(AIListObject *)listObject;

@end
