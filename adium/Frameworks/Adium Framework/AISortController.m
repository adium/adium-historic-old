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

#import "AISortController.h"

int basicGroupVisibilitySort(id objectA, id objectB, void *context);

@implementation AISortController

- (id)init
{
	[super init];
	
	statusKeysRequiringResort = [[self statusKeysRequiringResort] retain];
	attributeKeysRequiringResort = [[self attributeKeysRequiringResort] retain];
	sortFunction = [self sortFunction];
	
	return(self);
}

- (void)dealloc
{
	[statusKeysRequiringResort release];
	[attributeKeysRequiringResort release];
	
	[super dealloc];
}

- (BOOL)shouldSortForModifiedStatusKeys:(NSArray *)inModifiedKeys
{
	if(statusKeysRequiringResort){
		return([statusKeysRequiringResort firstObjectCommonWithArray:inModifiedKeys] != nil);
	}else{
		return(NO);
	}
}

- (BOOL)shouldSortForModifiedAttributeKeys:(NSArray *)inModifiedKeys
{
	if(attributeKeysRequiringResort){
		return([attributeKeysRequiringResort firstObjectCommonWithArray:inModifiedKeys] != nil);
	}else{
		return(NO);
	}
}

- (int)indexForInserting:(AIListObject *)inObject intoObjects:(NSMutableArray *)inObjects inGroup:(AIListGroup *)inGroup
{
	NSEnumerator 	*enumerator = [inObjects objectEnumerator];
	AIListObject	*object;
	int				index = 0;
	sortContextInfo	info;
	
	info.group = inGroup;
	info.function = sortFunction;

	while((object = [enumerator nextObject]) && basicGroupVisibilitySort(inObject, object, &info) == NSOrderedDescending){
		index++;
	}
	
	return(index);
}

- (void)sortListObjects:(NSMutableArray *)inObjects inGroup:(AIListGroup *)inGroup
{
	sortContextInfo	info;

	info.group = inGroup;
	info.function = sortFunction;

    [inObjects sortUsingFunction:basicGroupVisibilitySort context:&info];
}

int basicGroupVisibilitySort(id objectA, id objectB, void *context)
{
    BOOL	visibleA = [objectA isVisible];
    BOOL	visibleB = [objectB isVisible];
	
    if(!visibleA && visibleB){
        return(NSOrderedDescending);
    }else if(visibleA && !visibleB){
        return(NSOrderedAscending);
    }else{
        BOOL	groupA = [objectA isKindOfClass:[AIListGroup class]];
        BOOL	groupB = [objectB isKindOfClass:[AIListGroup class]];
		
        if(groupA && !groupB){
            return(NSOrderedAscending);
        }else if(!groupA && groupB){
            return(NSOrderedDescending);
        }else{
			sortContextInfo	*info = context;
			
			return((info->function)(objectA, objectB, info->group, groupA));
        }
    }
}

//For subclasses
- (NSString *)description{ return(nil); };
- (NSString *)identifier{ return(nil); };
- (NSString *)displayName{ return(nil); };
- (NSArray *)statusKeysRequiringResort{ return(nil); };
- (NSArray *)attributeKeysRequiringResort{ return(nil); };
- (int (*)(id, id, AIListGroup *, BOOL))sortFunction{ return(nil); };

@end
