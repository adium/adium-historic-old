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

#import "AIContactController.h"
#import "AIPreferenceController.h"
#import "ESStatusSort.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <Adium/AIListObject.h>
#import <Adium/AILocalizationTextField.h>

#define STATUS_SORT_DEFAULT_PREFS   @"StatusSortDefaults"

#define KEY_GROUP_AVAILABLE			@"Status:Group Available"
#define KEY_GROUP_UNAVAILABLE		@"Status:Group Unavailable"
#define KEY_GROUP_AWAY				@"Status:Group Away"
#define KEY_GROUP_IDLE				@"Status:Group Idle"
#define KEY_GROUP_IDLE_AND_AWAY		@"Status:Group Idle+Away"
#define KEY_SORT_IDLE_TIME			@"Status:Sort by Idle Time"
#define KEY_RESOLVE_ALPHABETICALLY  @"Status:Resolve Alphabetically"
#define KEY_SORT_ORDER				@"Status:Sort Order"
#define KEY_RESOLVE_BY_LAST_NAME	@"Status:Resolve Alphabetically By Last Name"

#define AVAILABLE					AILocalizedString(@"Available",nil)
#define AWAY						AILocalizedString(@"Away",nil)
#define IDLE						AILocalizedString(@"Idle",nil)
#define AWAY_AND_IDLE				AILocalizedString(@"Away and Idle",nil)
#define UNAVAILABLE					AILocalizedString(@"Unavailable",nil)
#define OTHER_UNAVAILABLE			AILocalizedString(@"Other Unavailable",nil)		
#define ONLINE						AILocalizedString(@"Online",nil)		

#define STATUS_DRAG_TYPE			@"Status Sort"

typedef enum {
	Available = 0,
	Away = 1,
	Idle = 2,
	Away_And_Idle = 3,
	Unavailable = 4,
	Online = 5
} Status_Sort_Type;
#define MAX_SORT_ORDER_DIMENSION	6

static BOOL groupAvailable;
static BOOL groupUnavailable;
static BOOL	groupAway;
static BOOL	groupIdle;
static BOOL groupIdleAndAway;
static BOOL	sortIdleTime;

static BOOL	resolveAlphabetically;
static BOOL resolveAlphabeticallyByLastName;

static int  sortOrder[MAX_SORT_ORDER_DIMENSION];
static int  sizeOfSortOrder;

@interface ESStatusSort (PRIVATE)
- (void)configureControlDimming;
- (void)pruneAndSetSortOrderFromArray:(NSArray *)sortOrderArray;
@end

DeclareString(sIdle)
DeclareString(sOnline)

/*!
 * @class ESStatusSort
 * @brief AISortController to sort by contacts and groups
 *
 * Extensive configuration is allowed.
 */
@implementation ESStatusSort

/*!
 * @brief Initialize
 */
- (id)init
{
	InitString(sIdle,@"Idle");
	InitString(sOnline,@"Online");
	
	self = [super init];
	
	return self;
}

/*!
 * @brief Did become active first time
 *
 * Called only once; gives the sort controller an opportunity to set defaults and load preferences lazily.
 */
- (void)didBecomeActiveFirstTime
{
	//Register our default preferences
	[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:STATUS_SORT_DEFAULT_PREFS 
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_CONTACT_SORTING];
	
	//Load our preferences
	NSDictionary *prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_SORTING];
	
	groupAvailable = [[prefDict objectForKey:KEY_GROUP_AVAILABLE] boolValue];
	groupUnavailable = [[prefDict objectForKey:KEY_GROUP_UNAVAILABLE] boolValue];
	
	groupAway = [[prefDict objectForKey:KEY_GROUP_AWAY] boolValue];
	groupIdle = [[prefDict objectForKey:KEY_GROUP_IDLE] boolValue];
	groupIdleAndAway = [[prefDict objectForKey:KEY_GROUP_IDLE_AND_AWAY] boolValue];
	
	sortIdleTime = [[prefDict objectForKey:KEY_SORT_IDLE_TIME] boolValue];
	resolveAlphabetically = [[prefDict objectForKey:KEY_RESOLVE_ALPHABETICALLY] boolValue];
	resolveAlphabeticallyByLastName = [[prefDict objectForKey:KEY_RESOLVE_BY_LAST_NAME] boolValue];
	
	[self pruneAndSetSortOrderFromArray:[prefDict objectForKey:KEY_SORT_ORDER]];
}

/*!
 * @brief Determines how the statusSort() method will operate.
 *
 * The sortOrder array, when it is done, contains, in order, the statuses which will be sorted upon.
 *
 * @param sortOrderArray An <tt>NSArray</tt> of <tt>NSNumber</tt>s whose values are Status_Sort_Type
 */
- (void)pruneAndSetSortOrderFromArray:(NSArray *)sortOrderArray
{
	NSEnumerator	*enumerator = [sortOrderArray objectEnumerator];
	NSNumber		*sortTypeNumber;
	
	unsigned int i;
	
	for (i = 0; i < MAX_SORT_ORDER_DIMENSION; i++){
		sortOrder[i] = -1;
	}
	
	i = 0;
	
	//Enumerate the ordering array.  For all sort types which are valid given the active sorting types,
	//add to sortOrder[].  Finalize sortOrder with -1.
	
	BOOL	groupIdleOrIdleTime = (groupIdle || sortIdleTime);
	
	while (sortTypeNumber = [enumerator nextObject]){
		switch ([sortTypeNumber intValue]){
			case Available: 
				/* Group available if:
					Group available,
					Group all unavailable, or 
					Group separetely the idle and the away (such that the remaining alternative is Available)
				*/
				if (groupAvailable || 
					groupUnavailable ||
					(/*!groupUnavailable &&*/ groupAway && groupIdleOrIdleTime)) sortOrder[i++] = Available;
				break;
				
			case Away:
				if (!groupUnavailable && groupAway) sortOrder[i++] = Away;
				break;
				
			case Idle:
				if ((!groupUnavailable && groupIdle) || sortIdleTime) sortOrder[i++] = Idle;
				break;
				
			case Away_And_Idle:
				if (!groupUnavailable && groupIdleAndAway) sortOrder[i++] = Away_And_Idle;
				break;
				
			case Unavailable: 
				//If one of groupAway or groupIdle is off, or we need a generic unavailable sort
				if (groupUnavailable ||
					((groupAvailable && (!groupAway || !groupIdleOrIdleTime)))){
					sortOrder[i++] = Unavailable;
				}
				break;
				
			case Online:
				/* Show Online category if:
					We aren't grouping all the available ones (this would imply grouping unavailable)
					We aren't grouping all the unavailable ones (this would imply grouping available)
					We aren't grouping both the away and the idle ones (this would imply grouping available)
				*/
				if (!groupAvailable && !groupUnavailable && !(groupAway && (groupIdleOrIdleTime))){
					sortOrder[i++] = Online;
				}
				break;
		}
	}
	
	sortOrder[i] = -1;
	
	sizeOfSortOrder = i;
	
	[tableView_sortOrder reloadData];
}

/*!
 * @brief Non-localized identifier
 */
- (NSString *)identifier{
    return(@"by Status");
}

/*!
 * @brief Localized display name
 */
- (NSString *)displayName{
    return(AILocalizedString(@"Sort Contacts by Status",nil));
}

/*!
 * @brief Status keys which, when changed, should trigger a resort
 */
- (NSSet *)statusKeysRequiringResort{
	return([NSSet setWithObjects:sOnline,sIdle,@"StatusState",nil]);
}

/*!
 * @brief Attribute keys which, when changed, should trigger a resort
 */
- (NSSet *)attributeKeysRequiringResort{
	return([NSSet setWithObject:@"Display Name"]);
}

//Configuration
#pragma mark Configuration
/*!
 * @brief Window title when configuring the sort
 *
 * Subclasses should provide a title for configuring the sort only if configuration is possible.
 * @result Localized title. If nil, the menu item will be disabled.
 */
- (NSString *)configureSortWindowTitle{
	return(AILocalizedString(@"Configure Status Sort",nil));	
}

/*!
 * @brief Nib name for configuration
 */
- (NSString *)configureNibName{
	return @"StatusSortConfiguration";
}

/*!
 * @brief View did load
 */
- (void)viewDidLoad
{
	[checkBox_groupAvailable setState:groupAvailable];
	[checkBox_groupAway setState:groupAway];
	[checkBox_groupIdle setState:groupIdle];
	[checkBox_groupIdleAndAway setState:groupIdleAndAway];
	[checkBox_sortIdleTime setState:sortIdleTime];
	[checkBox_alphabeticallyByLastName setState:resolveAlphabeticallyByLastName];
	
	[buttonCell_alphabetically setState:(resolveAlphabetically ? NSOnState : NSOffState)];
	[buttonCell_manually setState:(resolveAlphabetically ? NSOffState : NSOnState)];

	[buttonCell_allUnavailable setState:(groupUnavailable ? NSOnState : NSOffState)];
	[buttonCell_separateUnavailable	setState:(groupUnavailable ? NSOffState : NSOnState)];
	
	[self configureControlDimming];
	
	[tableView_sortOrder setDataSource:self];
	[tableView_sortOrder setDelegate:self];
    [tableView_sortOrder registerForDraggedTypes:[NSArray arrayWithObject:STATUS_DRAG_TYPE]];

	[checkBox_groupAvailable setTitle:AILocalizedString(@"Group available contacts","Status sort configuration")];
	[buttonCell_allUnavailable setTitle:AILocalizedString(@"Group all unavailable contacts together","Status sort configuration")];
	[buttonCell_separateUnavailable setTitle:AILocalizedString(@"Group unavailable contact separately","Status sort configuration")];
	[checkBox_groupAway setTitle:AILocalizedString(@"Group all away contacts","Status sort configuration")];
	[checkBox_groupIdle setTitle:AILocalizedString(@"Group all idle contacts","Status sort configuration")];
	[checkBox_groupIdleAndAway setTitle:AILocalizedString(@"Group all idle+away contacts","Status sort configuration")];
	
	[checkBox_sortIdleTime setTitle:AILocalizedString(@"Sort idle contacts by ascending idle time","Status sort configuration")];

	[label_sortWithinEachStatusGrouping setStringValue:AILocalizedString(@"Sort within each status grouping:","Status sort configuration")];
	[buttonCell_alphabetically setTitle:AILocalizedString(@"Alphabetically","Status sort configuration")];
	[checkBox_alphabeticallyByLastName setTitle:AILocalizedString(@"...by last name","Status sort configuration: [Alphabetically]... by last name")];
	[buttonCell_manually setTitle:AILocalizedString(@"Manually","Status sort configuration")];
	
	[label_statusGroupOrdering setStringValue:AILocalizedString(@"Status group ordering:","Status sort configuration")];
}

/*!
 * @brief Preference changed
 *
 * Sort controllers should live update as preferences change.
 */
- (IBAction)changePreference:(id)sender
{
	if (sender == checkBox_groupAvailable){
		groupAvailable = [sender state];
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:groupAvailable]
                                             forKey:KEY_GROUP_AVAILABLE
                                              group:PREF_GROUP_CONTACT_SORTING];		
	}else if (sender == checkBox_groupAway){
		groupAway = [sender state];
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:groupAway]
                                             forKey:KEY_GROUP_AWAY
                                              group:PREF_GROUP_CONTACT_SORTING];		
	}else if (sender == checkBox_groupIdle){
		groupIdle = [sender state];
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:groupIdle]
                                             forKey:KEY_GROUP_IDLE
                                              group:PREF_GROUP_CONTACT_SORTING];
		
	}else if (sender == checkBox_groupIdleAndAway){
		groupIdleAndAway = [sender state];
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:groupIdleAndAway]
                                             forKey:KEY_GROUP_IDLE_AND_AWAY
                                              group:PREF_GROUP_CONTACT_SORTING];
		
	}else if (sender == checkBox_sortIdleTime){
		sortIdleTime = [sender state];
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:sortIdleTime]
                                             forKey:KEY_SORT_IDLE_TIME
                                              group:PREF_GROUP_CONTACT_SORTING];				
	}else if(sender == matrix_resolution){
		id selectedCell = [sender selectedCell];
		
		resolveAlphabetically = (selectedCell == buttonCell_alphabetically);
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:resolveAlphabetically]
											 forKey:KEY_RESOLVE_ALPHABETICALLY
											  group:PREF_GROUP_CONTACT_SORTING];
		
		[self configureControlDimming];
		
	}else if(sender == matrix_unavailableGrouping){
		id selectedCell = [sender selectedCell];
		
		groupUnavailable = (selectedCell == buttonCell_allUnavailable);
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:groupUnavailable]
											 forKey:KEY_GROUP_UNAVAILABLE
											  group:PREF_GROUP_CONTACT_SORTING];
		
		[self configureControlDimming];
		
	}else if (sender == checkBox_alphabeticallyByLastName){
		resolveAlphabeticallyByLastName = [sender state];
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:resolveAlphabeticallyByLastName]
                                             forKey:KEY_RESOLVE_BY_LAST_NAME
                                              group:PREF_GROUP_CONTACT_SORTING];
	}
	
	[self pruneAndSetSortOrderFromArray:[[adium preferenceController] preferenceForKey:KEY_SORT_ORDER
																				 group:PREF_GROUP_CONTACT_SORTING]];
	
	[[adium contactController] sortContactList];
}

/*!
 * @brief Configure control dimming
 */
- (void)configureControlDimming
{
	[checkBox_alphabeticallyByLastName setEnabled:resolveAlphabetically];
	[checkBox_groupAway setEnabled:!groupUnavailable];
	[checkBox_groupIdle setEnabled:!groupUnavailable];
	[checkBox_groupIdleAndAway setEnabled:!groupUnavailable];
}

#pragma mark Sort Order Tableview datasource
/*!
 * @brief Table view number of rows
 */
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return sizeOfSortOrder;
}

/*!
 * @brief Table view object value
 */
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	switch (sortOrder[rowIndex]){
		case Available:
			return AVAILABLE;
			break;
			
		case Away:
			return AWAY;
			break;
			
		case Idle:
			return IDLE;
			break;
			
		case Away_And_Idle:
			return AWAY_AND_IDLE;
			break;
			
		case Unavailable:
			//Unavailable is always the same sort, but to the user it can be either "Unavailable" or "Other Unavailable"
			//depending upon what other options are active.  The test here is purely cosmetic.
			return ((!sortIdleTime && (groupUnavailable || !(groupAway || groupIdle || groupIdleAndAway))) ?
					UNAVAILABLE :
					OTHER_UNAVAILABLE);
			break;
		
		case Online:
			return ONLINE;
			break;
	}
	
	return @"";
}

/*!
 * @brief The NSNumber Status_Sort_Type which corresponds to a string
 *
 * @param string A string such as AVAILABLE or AWAY (localized)
 * @result The NSNumber Status_Sort_Type which corresponds to the string 
 */
- (NSNumber *)numberForString:(NSString *)string
{
	int equivalent = -1;

	if ([string isEqualToString:AVAILABLE]){
		equivalent = Available;
	}else if ([string isEqualToString:AWAY]){
		equivalent = Away;
	}else if ([string isEqualToString:IDLE]){
		equivalent = Idle;
	}else if ([string isEqualToString:AWAY_AND_IDLE]){
		equivalent = Away_And_Idle;
	}else if ([string isEqualToString:UNAVAILABLE] || ([string isEqualToString:OTHER_UNAVAILABLE])){
		equivalent = Unavailable;
	}else if ([string isEqualToString:ONLINE]){
		equivalent = Online;
	}
	
	return [NSNumber numberWithInt:equivalent];
}

/*!
 * @brief Table view write rows
 */
-  (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard
{
    [pboard declareTypes:[NSArray arrayWithObject:STATUS_DRAG_TYPE] owner:self];
	
    //Build a list of all the highlighted aways
    NSString	*dragItem = [self tableView:tableView
				  objectValueForTableColumn:nil
										row:[[rows objectAtIndex:0] intValue]];
	
    //put it on the pasteboard
    [pboard setString:dragItem forType:STATUS_DRAG_TYPE];
	
    return(YES);
}

/*!
 * @brief Table view validate drop
 */
- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    NSString	*avaliableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:STATUS_DRAG_TYPE]];

	if([avaliableType isEqualToString:STATUS_DRAG_TYPE]){
        if(operation == NSTableViewDropAbove && row != -1){
            return(NSDragOperationMove);
        }else{
            return(NSDragOperationNone);
		}
	}
	
    return(NSDragOperationNone);
}

/*!
 * @brief Table view accept drop
 */
- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
    NSString		*availableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:STATUS_DRAG_TYPE]];

    if([availableType isEqualToString:STATUS_DRAG_TYPE]){
		NSString		*item = [[info draggingPasteboard] stringForType:STATUS_DRAG_TYPE];
		
		//Remember, sortOrderPref contains all possible sorting types, not just the ones presently visible in the table!
		NSMutableArray  *sortOrderPref = [[[adium preferenceController] preferenceForKey:KEY_SORT_ORDER
																				   group:PREF_GROUP_CONTACT_SORTING] mutableCopy];
		NSNumber		*sortNumber = [self numberForString:item];
		
		//Remove it from our array
		[sortOrderPref removeObject:sortNumber];
		
		if (row == [tableView numberOfRows]){
			//Dropped at the bottom
			[sortOrderPref addObject:sortNumber];
		}else{
			//Find the object which will end up just below it
			int targetIndex = [sortOrderPref indexOfObject:[self numberForString:[self tableView:tableView
																		 objectValueForTableColumn:nil
																							   row:row]]];
			if (targetIndex != NSNotFound){
				//Insert it there
				[sortOrderPref insertObject:sortNumber atIndex:targetIndex];
			}else{
				//Dropped at the bottom
				[sortOrderPref addObject:sortNumber];
			}
		}
		
		[[adium preferenceController] setPreference:sortOrderPref
											 forKey:KEY_SORT_ORDER
											  group:PREF_GROUP_CONTACT_SORTING];
		
		[self pruneAndSetSortOrderFromArray:sortOrderPref];		
		
		//Select and scroll to the dragged object
		[tableView reloadData];
		
		[[adium contactController] sortContactList];

		[sortOrderPref release];
	}
	
   	
    return(YES);
}


#pragma mark Sorting

/*!
 * @brief The status sort method itself
 *
 * It's magic... but it's efficient magic!
 */
int statusSort(id objectA, id objectB, BOOL groups)
{
	if(groups){
		//Keep groups in manual order
		if([objectA orderIndex] > [objectB orderIndex]){
			return(NSOrderedDescending);
		}else{
			return(NSOrderedAscending);
		}
		
	}else{
		//Always sort offline contacts to the bottom
		BOOL onlineA = ([[objectA numberStatusObjectForKey:sOnline fromAnyContainedObject:NO] boolValue]);
		BOOL onlineB = ([[objectB numberStatusObjectForKey:sOnline fromAnyContainedObject:NO] boolValue]);
		if (!onlineB && onlineA){
			return NSOrderedAscending;
		}else if (!onlineA && onlineB){
			return NSOrderedDescending;
		}
		
		//We only need to start looking at status for sorting if both are online; 
		//otherwise, skip to resolving alphabetically or manually
		if (onlineA && onlineB){
			unsigned int	i = 0;
			BOOL			away[2];
			BOOL			definitelyFinishedIfSuccessful, onlyIfWeAintGotNothinBetter, status;
			int				idle[2];
			int				sortIndex[2];
			int				objectCounter;
			
			//Get the away state and idle times now rather than potentially doing each twice below
			away[0] = ([[objectA statusState] statusType] == AIAwayStatusType);
			away[1] = ([[objectB statusState] statusType] == AIAwayStatusType);
			
			idle[0] = [objectA integerStatusObjectForKey:sIdle fromAnyContainedObject:NO];
			idle[1] = [objectB integerStatusObjectForKey:sIdle fromAnyContainedObject:NO];

			for (objectCounter = 0; objectCounter < 2; objectCounter++){
				sortIndex[objectCounter] = 999;

				for (i = 0; i < sizeOfSortOrder ; i++){
					//Reset the internal bookkeeping
					onlyIfWeAintGotNothinBetter = NO;
					definitelyFinishedIfSuccessful = NO;
					
					//Determine the state for the status this level of sorting cares about
					switch (sortOrder[i]){
						case Available:
							status = (!away[objectCounter] && !idle[objectCounter]); // TRUE if A is available
							break;

						case Away:
							status = away[objectCounter];
							break;

						case Idle:
							status = (idle[objectCounter] != 0);
							break;

						case Away_And_Idle:
							status =  away[objectCounter] && (idle[objectCounter] != 0);
							definitelyFinishedIfSuccessful = YES;
							break;
							
						case Unavailable:
							status =  away[objectCounter] || (idle[objectCounter] != 0);
							onlyIfWeAintGotNothinBetter = YES;
							break;
							
						case Online:
							status = YES; //we can only get here if the person is online, anyways
							onlyIfWeAintGotNothinBetter = YES;
							break;
						
						default:
							status = NO;
					}

					//If the object has the desired status and we want to use it, store the new index it should go to
					if (status &&
						(!onlyIfWeAintGotNothinBetter || (sortIndex[objectCounter] == 999))){
						sortIndex[objectCounter] = i;
						
						//If definitelyFinishedIfSuccessful is YES, we're done sorting as soon as something fits
						//this category
						if (definitelyFinishedIfSuccessful) break;
					}
				}
			} //End for object loop
			
			if (sortIndex[0] > sortIndex[1]){
				return NSOrderedDescending;
			}else if (sortIndex[1] > sortIndex[0]){
				return NSOrderedAscending;			
			}
			
			//If one idle time is greater than the other and we want to sort on that basis, we have an ordering
			if (sortIdleTime){
				//Ordering is determined if either has a idle time and their idle times are not identical
				if (((idle[0] != 0) || (idle[1] != 0)) && (idle[0] != idle[1])){
					if(idle[0] > idle[1]){
						return(NSOrderedDescending);
					}else{
						return(NSOrderedAscending);
					}
				}
			}
		}
		
		if (!resolveAlphabetically){
			//If we don't want to resolve alphabetically, we do want to resolve by manual ordering if possible
			float orderIndexA = [objectA orderIndex];
			float orderIndexB = [objectB orderIndex];
			
			if(orderIndexA > orderIndexB){
				return(NSOrderedDescending);
			}else if (orderIndexA < orderIndexB){
				return(NSOrderedAscending);
			}
		}
		
		//If we made it here, resolve the ordering alphabetically, which is guaranteed to be consistent.
		//Note that this sort should -never- return NSOrderedSame, so as a last resort we use the internalObjectID.
		NSComparisonResult returnValue;
		
		if (resolveAlphabeticallyByLastName){
			//Split the displayname into parts by spacing and use the last part, the "last name," for comparison
			NSString	*space = @" ";
			NSString	*displayNameA = [objectA displayName];
			NSString	*displayNameB = [objectB displayName];
			NSArray		*componentsA = [displayNameA componentsSeparatedByString:space];
			NSArray		*componentsB = [displayNameB componentsSeparatedByString:space];
			
			returnValue = [[componentsA lastObject] caseInsensitiveCompare:[componentsB lastObject]];
			//If the last names are the same, compare the whole object, which will amount to sorting these objects
			//by first name
			if (returnValue == NSOrderedSame){
				returnValue = [displayNameA caseInsensitiveCompare:displayNameB];
				if (returnValue == NSOrderedSame){
					returnValue = [[objectA internalObjectID] caseInsensitiveCompare:[objectB internalObjectID]];
				}
			}
		}else{
			returnValue = [[objectA longDisplayName] caseInsensitiveCompare:[objectB longDisplayName]];
			if (returnValue == NSOrderedSame){
				returnValue = [[objectA internalObjectID] caseInsensitiveCompare:[objectB internalObjectID]];
			}
		}
		
		return (returnValue);
	}
}

/*!
 * @brief Sort function
 */
- (sortfunc)sortFunction{
	return(&statusSort);
}

@end