/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

@interface AIMutableOwnerArray (PRIVATE)
- (void)_createArrays;
- (void)_destroyArrays;
@end

@implementation AIMutableOwnerArray

//inits the array
- (id)init
{
    [super init];

    contentArray = nil;
    ownerArray = nil;
    
    return(self);
}

- (void)dealloc
{
    [self _destroyArrays];

    [super dealloc];
}

//Adds an object with a specified owner (Pass nil to remove the object)
- (void)setObject:(id)anObject withOwner:(id)inOwner
{
    int	ownerIndex;

    if(!contentArray || !ownerArray) [self _createArrays];
    
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
    }else{
        if([contentArray count] == 0) [self _destroyArrays];
    }
}

//Adds an object with a specified owner (Pass nil to remove the object) - the object at index 0 is considered primary and is used by default
- (void)setPrimaryObject:(id)anObject withOwner:(id)inOwner
{
    int	ownerIndex;
    
    if(!contentArray || !ownerArray) [self _createArrays];
    
    //Remove any existing objects
    ownerIndex = [ownerArray indexOfObject:inOwner];
    if(ownerIndex != NSNotFound){
        [ownerArray removeObjectAtIndex:ownerIndex];
        [contentArray removeObjectAtIndex:ownerIndex];
    }
    
    //Add the new object
    if(anObject != nil){
        if ([contentArray count]) {
            [contentArray insertObject:anObject atIndex:0];
            [ownerArray insertObject:inOwner atIndex:0];
        } else {
            [contentArray addObject:anObject];
            [ownerArray addObject:inOwner];
        }
    }else{
        if([contentArray count] == 0) [self _destroyArrays];
    }
}


//Returns an object with the specified owner
- (id)objectWithOwner:(id)inOwner
{
    if(ownerArray && contentArray){
        int	index = [ownerArray indexOfObject:inOwner];
        if(index != NSNotFound) return([contentArray objectAtIndex:index]);
    }
    
    return(nil);
}

//Returns the owner of the specified object
- (id)ownerWithObject:(id)inObject
{
    if(ownerArray && contentArray){
        int	index = [contentArray indexOfObject:inObject];
        if(index != NSNotFound) return([ownerArray objectAtIndex:index]);
    }
    
    return(nil);
}

//
- (NSEnumerator *)objectEnumerator
{
	return([contentArray objectEnumerator]);
}

//
- (NSEnumerator *)ownerEnumerator
{
	return([ownerArray objectEnumerator]);
}
//
- (NSArray *)allValues
{
	return(contentArray);
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

//Return the specific owner
- (id)ownerAtIndex:(unsigned)index
{
    return ([ownerArray objectAtIndex:index]);   
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

- (NSDate *)earliestDate
{
    if([ownerArray count] != 0){
        NSDate	*earlyDate = [contentArray objectAtIndex:0];
        int		loop;

        for(loop = 1;loop < [ownerArray count];loop++){
            NSDate	*date = [contentArray objectAtIndex:loop];

            if([earlyDate timeIntervalSinceDate:date] > 0){
                earlyDate = date;
            }
        }

        return(earlyDate);
    }else{
        return(nil);
    }
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

//Returns the first image
- (NSImage *)firstImage
{
    return([ownerArray count] ? [contentArray objectAtIndex:0] : nil);
}

- (void)_createArrays
{
    if(!contentArray) contentArray = [[NSMutableArray alloc] init];
    if(!ownerArray) ownerArray = [[NSMutableArray alloc] init];
}

- (void)_destroyArrays
{
    [contentArray release]; contentArray = nil;
    [ownerArray release]; ownerArray = nil;
}

@end
