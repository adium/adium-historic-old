//
//  ESOutlineViewAdditions.h
//  Adium
//
//  Created by Evan Schoenberg on Fri Jul 09 2004.

@interface NSOutlineView (ESOutlineViewAdditions)

- (id)firstSelectedItem;
- (NSArray *)arrayOfSelectedItems;
- (void)selectItemsInArray:(NSArray *)selectedItems;
- (void)redisplayItem:(id)item;

@end

