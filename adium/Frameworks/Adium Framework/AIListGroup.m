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

#import "AIListGroup.h"

@interface AIListGroup (PRIVATE)
- (void)_setVisibleCount:(int)newCount;
@end

@implementation AIListGroup

//init
- (id)initWithUID:(NSString *)inUID
{
    [super initWithUID:inUID serviceID:nil];
	
    objectArray = [[NSMutableArray alloc] init];
    expanded = YES;
	
	//Default invisible
    visibleCount = 0;
	visible = NO;
	[self setStatusObject:[NSNumber numberWithInt:visibleCount] forKey:@"VisibleObjectCount" notify:YES];
    
    return(self);
}


//Expanded State -------------------------------------------------------------------------------------------------------
#pragma mark Expanded State
//Set the expanded/collapsed state of this group (PRIVATE: For the contact list view to let us know our state)
- (void)setExpanded:(BOOL)inExpanded
{
    expanded = inExpanded;
}
//Returns the current expanded/collapsed state of this group
- (BOOL)isExpanded
{
    return(expanded);
}


//Visibility -----------------------------------------------------------------------------------------------------------
#pragma mark Visibility
/*
 The visible objects contained in a group are always sorted to the top.  This allows us to easily retrieve only visible
 objects without having to physically remove invisible objects from the group.
 */
//Returns the number of visible objects in this group
- (unsigned)visibleCount
{
    return(visibleCount);
}

//Called when the visibility of an object in this group changes
- (void)visibilityOfContainedObject:(AIListObject *)inObject changedTo:(BOOL)inVisible
{
	//Update our visibility as a result of this change
	[self _setVisibleCount:(inVisible ? visibleCount + 1 : visibleCount - 1)];
	
	//Sort the contained object to the bottom (invisible section) of the group
	[[adium contactController] sortListObject:inObject];
}

//Set this group as visible if it contains anything visible
- (void)_setVisibleCount:(int)newCount
{
//	if((newCount && !visibleCount) || (!newCount && visibleCount)){
//		[self setVisible:(newCount != 0)];
//	}
	visibleCount = newCount;
	
	//
	[self setStatusObject:[NSNumber numberWithInt:visibleCount] forKey:@"VisibleObjectCount" notify:YES];
}


//Contained Objects ----------------------------------------------------------------------------------------------------
#pragma mark Contained Objects
//Returns the number of objects in this group
- (unsigned)count
{
    return([objectArray count]);
}

//Retrieve an object by index
- (id)objectAtIndex:(unsigned)index
{
    NSParameterAssert(index >= 0 && index < [objectArray count]);
	
    return([objectArray objectAtIndex:index]);
}

//Return an enumerator of our contents
- (NSEnumerator *)objectEnumerator
{
    return([objectArray objectEnumerator]);
}

//Test for the presence of an object in our group
- (BOOL)containsObject:(AIListObject *)inObject
{
	return([objectArray containsObject:inObject]);
}

- (NSArray *)containedObjects
{
	return(objectArray);
}

//Retrieve the index of an object
- (int)indexOfObject:(AIListObject *)inObject
{
    return([objectArray indexOfObject:inObject]);
}

//
- (AIListObject *)objectWithServiceID:(NSString *)inServiceID UID:(NSString *)inUID
{
	NSEnumerator	*enumerator = [objectArray objectEnumerator];
	AIListObject	*object;
	
	while(object = [enumerator nextObject]){
		if([inUID compare:[object UID]] == 0 && [inServiceID compare:[object serviceID]] == 0){
			return(object);
		}
	}
	
	return(nil);
}

//Contained Object Editing ---------------------------------------------------------------------------------------------
#pragma mark Contained Object Editing
//Add an object to this group (PRIVATE: For contact controller only)
- (void)addObject:(AIListObject *)inObject
{
	if(![objectArray containsObject:inObject]){
		//Update our visible count
		if([inObject isVisible]){
			[self _setVisibleCount:visibleCount+1];
		}
		
		//Add the object
		[inObject setContainingGroup:self];
		[objectArray addObject:inObject];
		
		//Sort this object on our own.  This always comes along with a content change, so calling contact controller's
		//sort code would invoke an extra update that we don't need.  We can skip sorting if this object is not visible,
		//since it will add to the bottom/non-visible section of our array.
		if([inObject isVisible]){
			[self sortListObject:inObject sortController:[[adium contactController] activeSortController]];
		}
		
		//
		[self setStatusObject:[NSNumber numberWithInt:[objectArray count]] forKey:@"ObjectCount" notify:YES];
	}
}

//Remove an object from this group (PRIVATE: For contact controller only)
- (void)removeObject:(AIListObject *)inObject
{	
	if([objectArray containsObject:inObject]){
		//Update our visible count
		if([inObject isVisible]){
			[self _setVisibleCount:visibleCount-1];
		}
		
		//Remove the object
		[inObject setContainingGroup:nil];
		[objectArray removeObject:inObject];

		//
		[self setStatusObject:[NSNumber numberWithInt:[objectArray count]] forKey:@"ObjectCount" notify:YES];
	}
}

//Remove all the objects from this group (PRIVATE: For contact controller only)
- (void)removeAllObjects
{	
	//Remove all the objects
	while([objectArray count]){
		[self removeObject:[objectArray objectAtIndex:0]];
	}
}


//Sorting --------------------------------------------------------------------------------------------------------------
#pragma mark Sorting
//Resort an object in this group (PRIVATE: For contact controller only)
- (void)sortListObject:(AIListObject *)inObject sortController:(AISortController *)sortController
{
	[inObject retain];
	[objectArray removeObject:inObject];
	[objectArray insertObject:inObject atIndex:[sortController indexForInserting:inObject intoObjects:objectArray]];
	[inObject release];
}

//Resorts the group contents (PRIVATE: For contact controller only)
- (void)sortGroupAndSubGroups:(BOOL)subGroups sortController:(AISortController *)sortController
{
    //Sort the groups within this group
    if(subGroups){
		NSEnumerator		*enumerator;
		AIListObject		*object;
		
        enumerator = [objectArray objectEnumerator];
        while((object = [enumerator nextObject])){
            if([object isMemberOfClass:[AIListGroup class]]){
                [(AIListGroup *)object sortGroupAndSubGroups:YES sortController:sortController];
            }
        }
    }
	
    //Sort this group
    if(sortController){
        [sortController sortListObjects:objectArray];
    }
}

@end
