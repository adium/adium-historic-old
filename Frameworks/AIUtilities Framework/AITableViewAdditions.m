/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AITableViewAdditions.h"
#import "CBApplicationAdditions.h"

@implementation NSTableView (AITableViewAdditions)

- (int)indexOfTableColumn:(NSTableColumn *)inColumn
{
    NSTableColumn	*column;
    NSEnumerator	*enumerator;
    int			index = 0;

    enumerator = [[self tableColumns] objectEnumerator];
    while((column = [enumerator nextObject])){
        if(column == inColumn) return(index);
        index++;
    }

    return(NSNotFound);
}


//Return an array of items which are currently selected. SourceArray should be an array from which to pull the items;
//its count must be the same as the number of rows
- (NSArray *)arrayOfSelectedItemsUsingSourceArray:(NSArray *)sourceArray
{
	NSParameterAssert([sourceArray count] == [self numberOfRows]);

	NSMutableArray 	*itemArray = [NSMutableArray array];
	id 				item;
	
	//Apple wants us to do some pretty crazy stuff for selections in 10.3
	//We'll continue to use the old simpler cleaner safer easier method for 10.2
	if([NSApp isOnPantherOrBetter]){
		NSIndexSet *indices = [self selectedRowIndexes];
		unsigned int bufSize = [indices count];
		unsigned int *buf = malloc(bufSize + sizeof(unsigned int));
		unsigned int i;
		
		NSRange range = NSMakeRange([indices firstIndex], ([indices lastIndex]-[indices firstIndex]) + 1);
		[indices getIndexes:buf maxCount:bufSize inIndexRange:&range];
		
		for(i = 0; i != bufSize; i++){
			if(item = [sourceArray objectAtIndex:buf[i]]){
				[itemArray addObject:item];
			}
		}
		
		free(buf);
		
	}else{
		NSEnumerator 	*enumerator = [self selectedRowEnumerator]; 
		NSNumber 		*row;
		
		while(row = [enumerator nextObject]){
			if(item = [sourceArray objectAtIndex:[row intValue]]){
				[itemArray addObject:item]; 
			}
		} 
	}
	
	return(itemArray);
}

- (int)indexOfTableColumnWithIdentifier:(id)inIdentifier
{
    NSTableColumn	*column;
    NSEnumerator	*enumerator;
    int			index = 0;
    
    enumerator = [[self tableColumns] objectEnumerator];
    while((column = [enumerator nextObject])){
        if([column identifier] == inIdentifier/*[(NSString *)[column identifier] compare:inIdentifier] == 0*/) return(index);
        index++;
    }

    return(NSNotFound);
}  

@end
