/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

/*
    An array that keeps track of who owns each of its objects.
    
    Every object in the array has an associated owner.  The best use for this class is when multiple pieces of code may be trying to control the same thing.  For instance, if there are several events that can cause something to change colors, by using an owner-array it is possible to prevent conflicts and determine an average color based on all the values.  It's also easy for a specific owner to remove the value they contributed, or replace it with another.
*/

#import "AIMutableOwnerArray.h"

@implementation AIMutableOwnerArray

//inits the array
- (id)init
{
    [super init];
    
    contentArray = [[NSMutableArray alloc] init];
    ownerArray = [[NSMutableArray alloc] init];
    
    return(self);
}

- (void)dealloc
{
    [contentArray release];
    [ownerArray release];

    [super dealloc];
}

//Adds an object with a specified owner (Pass nil to remove the object)
- (void)setObject:(id)anObject withOwner:(id)inOwner
{
    int	ownerIndex;
    
    //Remove any existing objects
    ownerIndex = [ownerArray indexOfObject:inOwner];
    if(ownerIndex != NSNotFound){
        [ownerArray removeObjectAtIndex:ownerIndex];
        [contentArray removeObjectAtIndex:ownerIndex];
    }

    //Add the new object
    if(anObject != nil){
        [contentArray addObject:anObject];
        [ownerArray addObject:inOwner];
    }
}

//Returns an object with the specified owner
- (id)objectWithOwner:(id)inOwner
{
    int	index = [ownerArray indexOfObject:inOwner];
    
    if(index != NSNotFound){
        return([contentArray objectAtIndex:index]);
    }else{
        return(nil);
    }

}

//Return the number of objects
- (unsigned)count
{
    return([contentArray count]);
}

//Return the specified object
- (id)objectAtIndex:(unsigned)index
{
    return([contentArray objectAtIndex:index]);
}

//Return the average color
- (NSColor *)averageColor
{
    NSColor	*average = nil;
    int		loop;

    for(loop = 0;loop < [ownerArray count];loop++){
        average = [contentArray objectAtIndex:loop];
    }

    return(average);
}

//Returns YES if the array contains the specified integer value
- (BOOL)containsAnyIntegerValueOf:(int)inValue
{
    int	loop;

    for(loop = 0;loop < [ownerArray count];loop++){
        if([[contentArray objectAtIndex:loop] intValue] == inValue){
            return(YES);
        }
    }

    return(NO);
}

//Returns the greatest integer value
- (int)greatestIntegerValue
{
    int	loop;
    int	count = [ownerArray count];
    int	greatest = 0;

    if(count != 0){
        greatest = [[contentArray objectAtIndex:0] intValue];

        for(loop = 1;loop < count;loop++){
            int	current = [[contentArray objectAtIndex:loop] intValue];

            if(current > greatest){
                greatest = current;
            }
        }
    }
    
    return(greatest);
}

//Returns the greatest double value
- (double)greatestDoubleValue
{
    int		loop;
    int		count = [ownerArray count];
    double	greatest = 0;

    if(count != 0){
        greatest = [[contentArray objectAtIndex:0] doubleValue];

        for(loop = 1;loop < [ownerArray count];loop++){
            double	current = [[contentArray objectAtIndex:loop] doubleValue];

            if(current > greatest){
            greatest = current;
            }
        }
    }

    return(greatest);
}

@end
