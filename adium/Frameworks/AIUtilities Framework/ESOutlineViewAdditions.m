//
//  ESOutlineViewAdditions.m
//  Adium
//
//  Created by Evan Schoenberg on Fri Jul 09 2004.
//

#import "ESOutlineViewAdditions.h"

@implementation NSOutlineView (ESOutlineViewAdditions)

- (id)firstSelectedItem
{
    int selectedRow = [self selectedRow];
	
    if(selectedRow >= 0 && selectedRow < [self numberOfRows]){
        return([self itemAtRow:selectedRow]);
    }else{
        return(nil);
    }
}

//Redislpay an item on the contact list
- (void)redisplayItem:(id)item
{
	int row = [self rowForItem:item];
	if(row >= 0 && row < [self numberOfRows]){
		[self setNeedsDisplayInRect:[self rectOfRow:row]];
	}else{
		[self setNeedsDisplay:YES];
	}
}

//
- (NSArray *)arrayOfSelectedItems
{
	NSMutableArray *itemArray = [NSMutableArray array];

	//The nastiness that selectedRowIndexes returns will crash if called on an item which needs to be reloaded but hasn't been yet.
	//Interestingly, selectedRowEnumerator does just fine.
#ifdef I_WOULD_LIKE_THIS_STUPID_THING_TO_CRASH_CONSTANTLY
	//selectedRowIndexes is recommended in 10.3 or better
	if([NSApp isOnPantherOrBetter]){
		NSIndexSet *indices = [self selectedRowIndexes];
		unsigned int bufSize = [indices count];
		unsigned int *buf = malloc(bufSize + 1);
		unsigned int i;
		NSRange range = NSMakeRange([indices firstIndex], ([indices lastIndex]-[indices firstIndex]) + 1);
		[indices getIndexes:buf maxCount:bufSize inIndexRange:&range];
		
		for(i = 0; i != bufSize; i++) {
			unsigned int index = buf[i];
			id  item = [self itemAtRow:index];
			if (item && [item retainCount]){
				[itemArray addObject:item];
			}
		}
		
		free(buf);
		
	}else{
#endif
		//selectedRowEnumerator is deprecated as of 10.3... but it works properly
		NSNumber *row;
		NSEnumerator *enumerator = [self selectedRowEnumerator]; 
		while (row = [enumerator nextObject]){
			id item = [self itemAtRow:[row intValue]];
			if (item){
				[itemArray addObject:item]; 
			}
		} 
#ifdef I_WOULD_LIKE_THIS_STUPID_THING_TO_CRASH_CONSTANTLY
	}
#endif
	
	return (itemArray);
}

//
- (void)selectItemsInArray:(NSArray *)selectedItems
{
	Class 			NSMutableIndexSetClass = NSClassFromString(@"NSMutableIndexSet");	
	NSEnumerator	*enumerator = [selectedItems objectEnumerator];
	id				selectedItem;
	int 			selectedRow;
	
	if([NSApp isOnPantherOrBetter]){
		id  indexSet = [NSMutableIndexSetClass indexSet];
		
		//Build an index set
		while(selectedItem = [enumerator nextObject]){
			selectedRow = [self rowForItem:selectedItem];
			if(selectedRow != NSNotFound){
				[indexSet addIndex:selectedRow];
			}
		}
		
		//Select the indexes
		[self selectRowIndexes:indexSet byExtendingSelection:NO];
		
	}else{
		//Selected each previously selected row if possible
		while(selectedItem = [enumerator nextObject]){
			selectedRow = [self rowForItem:selectedItem];
			if(selectedRow != NSNotFound){
				[self selectRow:selectedRow byExtendingSelection:[self allowsMultipleSelection]];
			}
		}			
	}
	
}

@end
