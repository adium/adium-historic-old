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

#import "AISortController.h"
#import "AIListContact.h"

int basicGroupVisibilitySort(id objectA, id objectB, void *context);
int basicVisibilitySort(id objectA, id objectB, void *context);

@implementation AISortController

- (id)init
{
	[super init];
	
	statusKeysRequiringResort = [[self statusKeysRequiringResort] retain];
	attributeKeysRequiringResort = [[self attributeKeysRequiringResort] retain];
	sortFunction = [self sortFunction];
	alwaysSortGroupsToTop = [self alwaysSortGroupsToTopByDefault];
	
	configureView = nil;
	becameActiveFirstTime = NO;
	
	return(self);
}

- (void)dealloc
{
	[statusKeysRequiringResort release];
	[attributeKeysRequiringResort release];
	
	[super dealloc];
}

- (NSView *)configureView
{
	if (!configureView)
		[NSBundle loadNibNamed:[self configureNibName] owner:self];
	
	[self viewDidLoad];
	
	return configureView;
}

//Sort Logic -------------------------------------------------------------------------------------------------------
#pragma mark Sort Logic
- (BOOL)shouldSortForModifiedStatusKeys:(NSSet *)inModifiedKeys
{
	if(statusKeysRequiringResort){
		return([statusKeysRequiringResort intersectsSet:inModifiedKeys] != nil);
	}else{
		return(NO);
	}
}

- (BOOL)shouldSortForModifiedAttributeKeys:(NSSet *)inModifiedKeys
{
	if(attributeKeysRequiringResort){
		return([attributeKeysRequiringResort intersectsSet:inModifiedKeys] != nil);
	}else{
		return(NO);
	}
}

- (BOOL)alwaysSortGroupsToTopByDefault
{
	return(YES);
}

- (void)forceIgnoringOfGroups:(BOOL)shouldForce
{
	if(shouldForce){
		alwaysSortGroupsToTop = NO;
	}else{
		alwaysSortGroupsToTop = [self alwaysSortGroupsToTopByDefault];
	}
}

//Sorting -------------------------------------------------------------------------------------------------------
#pragma mark Sorting
- (int)indexForInserting:(AIListObject *)inObject intoObjects:(NSArray *)inObjects
{
	NSEnumerator 	*enumerator = [inObjects objectEnumerator];
	AIListObject	*object;
	int				index = 0;

	if(alwaysSortGroupsToTop){
		while((object = [enumerator nextObject]) && ((object == inObject) || 
			  basicGroupVisibilitySort(inObject, object, sortFunction) == NSOrderedDescending)) index++;
	}else{
		while((object = [enumerator nextObject]) && ((object == inObject) ||
			  basicVisibilitySort(inObject, object, sortFunction) == NSOrderedDescending)) index++;
	}
	
	return(index);
}

- (void)sortListObjects:(NSMutableArray *)inObjects
{
    [inObjects sortUsingFunction:(alwaysSortGroupsToTop ? basicGroupVisibilitySort : basicVisibilitySort)
						 context:sortFunction];
}

//Sort
int basicVisibilitySort(id objectA, id objectB, void *context)
{
    BOOL	visibleA = [objectA visible];
    BOOL	visibleB = [objectB visible];
	
    if(!visibleA && visibleB){
        return(NSOrderedDescending);
    }else if(visibleA && !visibleB){
        return(NSOrderedAscending);
    }else{
		sortfunc	function = context;

		return((function)(objectA, objectB, NO));
    }
}

//Sort, groups always at the top
int basicGroupVisibilitySort(id objectA, id objectB, void *context)
{
    BOOL	visibleA = [objectA visible];
    BOOL	visibleB = [objectB visible];
	
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
			sortfunc	function = context;
			
			return((function)(objectA, objectB, groupA));
        }
    }
}

//For subclasses -------------------------------------------------------------------------------------------------------
#pragma mark For Subclasses:
- (NSString *)description{ return(nil); };
- (NSString *)identifier{ return(nil); };
- (NSString *)displayName{ return(nil); };
- (NSSet *)statusKeysRequiringResort{ return(nil); };
- (NSSet *)attributeKeysRequiringResort{ return(nil); };
- (int (*)(id, id, BOOL))sortFunction{ return(nil); };
- (void)didBecomeActiveFirstTime {};
- (void)didBecomeActive 
{
	if (!becameActiveFirstTime){
		[self didBecomeActiveFirstTime];
		becameActiveFirstTime = YES;
	}
}

//Subclasses should provide a title for configuring the sort only if configuration is possible
- (NSString *)configureSortMenuItemTitle{ return(nil); };
- (NSString *)configureSortWindowTitle{ return(nil); };
- (NSString *)configureNibName{ return(nil); };
- (void)viewDidLoad{ };
- (IBAction)changePreference:(id)sender{ };
@end
