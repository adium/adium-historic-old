/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIListContact.h"
#import "AISortController.h"

int basicGroupVisibilitySort(id objectA, id objectB, void *context);
int basicVisibilitySort(id objectA, id objectB, void *context);

@implementation AISortController

- (id)init
{
	if(self = [super init]){
		statusKeysRequiringResort = [[self statusKeysRequiringResort] retain];
		attributeKeysRequiringResort = [[self attributeKeysRequiringResort] retain];
		sortFunction = [self sortFunction];
		alwaysSortGroupsToTop = [self alwaysSortGroupsToTopByDefault];
		
		configureView = nil;
		becameActiveFirstTime = NO;
	}
	
	return(self);
}

- (void)dealloc
{
	[statusKeysRequiringResort release];
	[attributeKeysRequiringResort release];
	
	[configureView release]; configureView = nil;
	
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

/*!
 * @brief Did become active
 *
 * Called when the controller becomes active
 */
- (void)didBecomeActive 
{
	if (!becameActiveFirstTime){
		[self didBecomeActiveFirstTime];
		becameActiveFirstTime = YES;
	}
}

/*!
 * @brief Title for the Configure Sort menu item  when this sort is active
 *
 * Subclasses should provide a title for configuring the sort only if configuration is possible.
 * @result Localized title. If nil, the menu item will be disabled.
 */
- (NSString *)configureSortMenuItemTitle{ 
	NSString *configureSortWindowTitle = [self configureSortWindowTitle];
	if(configureSortWindowTitle){
		return([NSString stringWithFormat:@"%@%s",[self configureSortWindowTitle],"É"]);
	}else{
		return(nil);
	}
}

//For subclasses -------------------------------------------------------------------------------------------------------
#pragma mark For Subclasses:

/*!
 * @brief Non-localized identifier
 */
- (NSString *)identifier{ return(nil); };

/*!
 * @brief Localized display name
 */
- (NSString *)displayName{ return(nil); };

/*!
 * @brief Status keys which, when changed, should trigger a resort
 */
- (NSSet *)statusKeysRequiringResort{ return(nil); };

/*!
 * @brief Attribute keys which, when changed, should trigger a resort
 */
- (NSSet *)attributeKeysRequiringResort{ return(nil); };

/*!
 * @brief Sort function
 */
- (int (*)(id, id, BOOL))sortFunction{ return(NULL); };

/*!
 * @brief Did become active first time
 *
 * Called only once; gives the sort controller an opportunity to set defaults and load preferences lazily.
 */
- (void)didBecomeActiveFirstTime {};

/*!
 * @brief Window title when configuring the sort
 *
 * Subclasses should provide a title for configuring the sort only if configuration is possible.
 * @result Localized title. If nil, the menu item will be disabled.
 */
- (NSString *)configureSortWindowTitle{ return(nil); };

/*!
 * @brief Nib name for configuration
 */
- (NSString *)configureNibName{ return(nil); };

/*!
 * @brief View did load
 */
- (void)viewDidLoad{ };

/*!
 * @brief Preference changed
 *
 * Sort controllers should live update as preferences change.
 */
- (IBAction)changePreference:(id)sender{ };

@end
