//
//  AITableViewAdditions.m
//  Adium
//
//  Created by Adam Iser on Tue Mar 18 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AITableViewAdditions.h"


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

- (int)indexOfTableColumnWithIdentifier:(id)inIdentifier
{
    NSTableColumn	*column;
    NSEnumerator	*enumerator;
    int			index = 0;

    enumerator = [[self tableColumns] objectEnumerator];
    while((column = [enumerator nextObject])){
        if([(NSString *)[column identifier] compare:inIdentifier] == 0) return(index);
        index++;
    }

    return(NSNotFound);
}    

@end
