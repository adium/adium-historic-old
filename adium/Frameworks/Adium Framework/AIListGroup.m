/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
#import "AISortController.h"

@interface AIListGroup (PRIVATE)
- (void)_setVisibleCount:(int)newCount;
@end

@implementation AIListGroup

//init
- (id)initWithUID:(NSString *)inUID
{
    [super initWithUID:inUID serviceID:nil];
	
    containedObjects = [[NSMutableArray alloc] init];

	//Default invisible
    visibleCount = 0;
	visible = NO;
//	[self setStatusObject:[NSNumber numberWithInt:visibleCount] forKey:@"VisibleObjectCount" notify:YES];
    
    return(self);
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

//Called when the visibility of an object in this group changes
- (void)visibilityOfContainedObject:(AIListObject *)inObject changedTo:(BOOL)inVisible
{
	//Update our visibility as a result of this change
	[self _setVisibleCount:(inVisible ? visibleCount + 1 : visibleCount - 1)];
	
	//Sort the contained object to or from the bottom (invisible section) of the group
	//Dend a notification for the object, the tabs will use this to auto-arrange.  Then, we send
	//a notification for the group, which the contact list needs to correctly update
	[[adium contactController] sortListObject:inObject];
	[[adium contactController] sortListObject:self];
}

//Object Storage ---------------------------------------------------------------------------------------------
#pragma mark Object Storage
//Add an object to this group (PRIVATE: For contact controller only)
//Returns YES if the object was added (that is, was not already present)
- (BOOL)addObject:(AIListObject *)inObject
{
	BOOL success = NO;
	
	if(![containedObjects containsObject:inObject]){
		//Update our visible count
		if([inObject visible]){
			[self _setVisibleCount:visibleCount+1];
		}
		
		//Add the object
		[inObject setContainingObject:self];
		[containedObjects addObject:inObject];
		
		//Sort this object on our own.  This always comes along with a content change, so calling contact controller's
		//sort code would invoke an extra update that we don't need.  We can skip sorting if this object is not visible,
		//since it will add to the bottom/non-visible section of our array.
		if([inObject visible]){
			[self sortListObject:inObject
				  sortController:[[adium contactController] activeSortController]];
		}
		
		//
		[self setStatusObject:[NSNumber numberWithInt:[containedObjects count]] 
					   forKey:@"ObjectCount"
					   notify:YES];
		
		success = YES;
	}
	
	return success;
}

//Remove an object from this group (PRIVATE: For contact controller only)
- (void)removeObject:(AIListObject *)inObject
{	
	if([containedObjects containsObject:inObject]){
		//Update our visible count
		if([inObject visible]){
			[self _setVisibleCount:visibleCount-1];
		}
		
		//Remove the object
		[inObject setContainingObject:nil];
		[containedObjects removeObject:inObject];

		//
		[self setStatusObject:[NSNumber numberWithInt:[containedObjects count]]
					   forKey:@"ObjectCount" 
					   notify:YES];
	}
}

//Sorting --------------------------------------------------------------------------------------------------------------
#pragma mark Sorting
//Resort an object in this group (PRIVATE: For contact controller only)
- (void)sortListObject:(AIListObject *)inObject sortController:(AISortController *)sortController
{
	[inObject retain];
	[containedObjects removeObject:inObject];
	[containedObjects insertObject:inObject 
						   atIndex:[sortController indexForInserting:inObject 
														 intoObjects:containedObjects]];
	[inObject release];
}

//Resorts the group contents (PRIVATE: For contact controller only)
- (void)sortGroupAndSubGroups:(BOOL)subGroups sortController:(AISortController *)sortController
{
    //Sort the groups within this group
    if(subGroups){
		NSEnumerator		*enumerator;
		AIListObject		*object;
		
        enumerator = [containedObjects objectEnumerator];
        while((object = [enumerator nextObject])){
            if([object isMemberOfClass:[AIListGroup class]]){
                [(AIListGroup *)object sortGroupAndSubGroups:YES
											  sortController:sortController];
            }
        }
    }
	
    //Sort this group
    if(sortController){
        [sortController sortListObjects:containedObjects];
    }
}

@end
