//
//  AIOutlineView.h
//  Adium
//
//  Created by Adam Iser on Tue Mar 23 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//


@interface AIOutlineView : NSOutlineView {
    BOOL		needsReload;
}

- (void)_init;
- (void)itemDidExpand:(NSNotification *)notification;
- (void)itemDidCollapse:(NSNotification *)notification;

@end

@interface NSObject (AIOutlineViewDelegate)
- (NSMenu *)outlineView:(NSOutlineView *)outlineView menuForEvent:(NSEvent *)theEvent;
- (void)outlineView:(NSOutlineView *)outlineView setExpandState:(BOOL)state ofItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView expandStateOfItem:(id)item;
- (void)outlineViewDeleteSelectedRows:(NSOutlineView *)tableView;
@end
