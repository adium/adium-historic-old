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
#import "AIListGroup.h"
#import "AISortController.h"
#import "AIPreferenceController.h"
#import <AIUtilities/AIStringAdditions.h>

#define KEY_RESOLVE_ALPHABETICALLY  @"Status:Resolve Alphabetically"

int basicGroupVisibilitySort(id objectA, id objectB, void *context);
int basicVisibilitySort(id objectA, id objectB, void *context);

@implementation AISortController

/*
 * @brief Initialize
 */
- (id)init
{
	if ((self = [super init])) {
		statusKeysRequiringResort = [[self statusKeysRequiringResort] retain];
		attributeKeysRequiringResort = [[self attributeKeysRequiringResort] retain];
		sortFunction = [self sortFunction];
		alwaysSortGroupsToTop = [self alwaysSortGroupsToTopByDefault];
		
		configureView = nil;
		becameActiveFirstTime = NO;
	}
	
	return self;
}

/*
 * @brief Deallocate
 */
- (void)dealloc
{
	[statusKeysRequiringResort release];
	[attributeKeysRequiringResort release];
	
	[configureView release]; configureView = nil;
	
	[super dealloc];
}

/*
 * @brief Configure our customization view
 */
- (NSView *)configureView
{
	if (!configureView)
		[NSBundle loadNibNamed:[self configureNibName] owner:self];
	
	[self viewDidLoad];
	
	return configureView;
}

//Sort Logic -------------------------------------------------------------------------------------------------------
#pragma mark Sort Logic
/*
 * @brief Should we resort for a set of changed status keys?
 *
 * @param inModifiedKeys NSSet of NSString keys to test
 * @result YES if we need to resort
 */
- (BOOL)shouldSortForModifiedStatusKeys:(NSSet *)inModifiedKeys
{
	if (statusKeysRequiringResort) {
		return [statusKeysRequiringResort intersectsSet:inModifiedKeys] != nil;
	} else {
		return NO;
	}
}

/*
 * @brief Should we resort for a set of changed attribute keys?
 *
 * @param inModifiedKeys NSSet of NSString keys to test
 * @result YES if we need to resort
 */
- (BOOL)shouldSortForModifiedAttributeKeys:(NSSet *)inModifiedKeys
{
	if (attributeKeysRequiringResort) {
		return [attributeKeysRequiringResort intersectsSet:inModifiedKeys] != nil;
	} else {
		return NO;
	}
}

/*
 * @brief Always sort groups to the top by default?
 *
 * By default, manual sort ignores groups and sorts them alongside all other objects
 * while alphabetical and status sort them to the top of any given array.
 */
- (BOOL)alwaysSortGroupsToTopByDefault
{
	return YES;
}

/*
 * @brief Force ignoring of groups?
 *
 * @param shouldForce If YES, groups are ignored. If NO, default behavior for this sort is used.
 */
- (void)forceIgnoringOfGroups:(BOOL)shouldForce
{
	if (shouldForce) {
		alwaysSortGroupsToTop = NO;
	} else {
		alwaysSortGroupsToTop = [self alwaysSortGroupsToTopByDefault];
	}
}

/*
 * @brief Should we be sorted?
 *
 * @param canSortManually If YES, We should allow manual sorting. If NO, disable it.
 */
- (BOOL)canSortManually {
	if([[self identifier] isEqualToString:@"ManualSort"] || (![[[[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_SORTING] objectForKey:KEY_RESOLVE_ALPHABETICALLY] boolValue])) {
		return YES;
	}
	return NO;
}

//Sorting -------------------------------------------------------------------------------------------------------
#pragma mark Sorting
/*
 * @brief Index for inserting an object into an array
 *
 * @param inObject The AIListObject to be inserted object
 * @param inObjects An NSArray of AIListObject objects
 * @result The index for insertion
 */
- (int)indexForInserting:(AIListObject *)inObject intoObjects:(NSArray *)inObjects
{
	NSEnumerator 	*enumerator = [inObjects objectEnumerator];
	AIListObject	*object;
	int				index = 0;

	if (alwaysSortGroupsToTop) {
		while ((object = [enumerator nextObject]) && ((object == inObject) || 
			  basicGroupVisibilitySort(inObject, object, sortFunction) == NSOrderedDescending)) index++;
	} else {
		while ((object = [enumerator nextObject]) && ((object == inObject) ||
			  basicVisibilitySort(inObject, object, sortFunction) == NSOrderedDescending)) index++;
	}
	
	return index;
}

/*!
 * @brief Sort an array of list objects
 *
 * The passed list objects are sorted using sortFunction.
 *
 * We assume that, in general, the array is already close to being properly sorted; we therefore generate and use a hint.
 * This mildly hurts our worst case performance, but it improves both our best and average cases, so it is a worthwhile tradeoff.
 *
 * @param inObjects An NSArray of AIListObject instances to sort
 * @result A sorted NSArray containing the same AIListObjects from inObjects
 */
- (NSArray *)sortListObjects:(NSArray *)inObjects
{
	return [inObjects sortedArrayUsingFunction:(alwaysSortGroupsToTop ? basicGroupVisibilitySort : basicVisibilitySort)
									   context:sortFunction
										  hint:[inObjects sortedArrayHint]];
}

/*
 * @brief Primary sort when groups are sorted alongside contacts (alwaysSortGroupsToTop == FALSE)
 *
 * Visible contacts go above invisible ones.  For contacts which are both visible, use the sort function.
 */
int basicVisibilitySort(id objectA, id objectB, void *context)
{
    BOOL	visibleA = [objectA visible];
    BOOL	visibleB = [objectB visible];
	
	if (visibleA || visibleB) {
		if (!visibleA && visibleB) {
			return NSOrderedDescending;
		} else if (visibleA && !visibleB) {
			return NSOrderedAscending;
		} else {
			sortfunc	function = context;
			
			return (function)(objectA, objectB, NO);
		}

	} else {
		//We don't care about the relative ordering of two invisible contacts
		return NSOrderedSame;
	}
}

/*
 * @brief Primary sort when groups are always sorted to the top
 *
 * Visible contacts go above invisible ones.  For contacts which are both visible, use the sort function.
 */
int basicGroupVisibilitySort(id objectA, id objectB, void *context)
{
    BOOL	visibleA = [objectA visible];
    BOOL	visibleB = [objectB visible];
	
	if (visibleA || visibleB) {
		if (!visibleA && visibleB) {
			return NSOrderedDescending;
		} else if (visibleA && !visibleB) {
			return NSOrderedAscending;
		} else {
			BOOL	groupA = [objectA isKindOfClass:[AIListGroup class]];
			BOOL	groupB = [objectB isKindOfClass:[AIListGroup class]];
			
			if (groupA && !groupB) {
				return NSOrderedAscending;
			} else if (!groupA && groupB) {
				return NSOrderedDescending;
			} else {
				sortfunc	function = context;
				
				return (function)(objectA, objectB, groupA);
			}
		}

	} else {
		//We don't care about the relative ordering of two invisible contacts
		return NSOrderedSame;
	}
}

/*!
 * @brief The controller became active (in use by Adium)
 */
- (void)didBecomeActive 
{
	if (!becameActiveFirstTime) {
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
	if (configureSortWindowTitle) {
		return [[self configureSortWindowTitle] stringByAppendingEllipsis];
	} else {
		return nil;
	}
}

//For subclasses -------------------------------------------------------------------------------------------------------
#pragma mark For Subclasses:

/*!
 * @brief Non-localized identifier
 */
- (NSString *)identifier{ return nil; };

/*!
 * @brief Localized display name
 */
- (NSString *)displayName{ return nil; };

/*!
 * @brief Status keys which, when changed, should trigger a resort
 */
- (NSSet *)statusKeysRequiringResort{ return nil; };

/*!
 * @brief Attribute keys which, when changed, should trigger a resort
 */
- (NSSet *)attributeKeysRequiringResort{ return nil; };

/*!
 * @brief Sort function
 */
- (int (*)(id, id, BOOL))sortFunction{ return NULL; };

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
- (NSString *)configureSortWindowTitle{ return nil; };

/*!
 * @brief Nib name for configuration
 */
- (NSString *)configureNibName{ return nil; };

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
