//
//  ESStatusSort.m
//  Adium
//
//  Created by Evan Schoenberg on Tue Mar 09 2004.
//

#import "ESStatusSort.h"

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
#define MAX_SORT_ORDER_DIMENSION	6

int statusSort(id objectA, id objectB, BOOL groups);

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

DeclareString(sAway)
DeclareString(sIdle)
DeclareString(sOnline)

@implementation ESStatusSort

//Sort contacts and groups by status.
- (id)init
{
	InitString(sAway,@"Away");
	InitString(sIdle,@"Idle");
	InitString(sOnline,@"Online");
	
	[super init];
	
	return self;
}

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
	
	while (sortTypeNumber = [enumerator nextObject]){
		switch ([sortTypeNumber intValue]){
			case Available: 
				if (groupAvailable || groupUnavailable || groupAway || groupIdle || groupIdleAndAway) sortOrder[i++] = Available;
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
					((groupAvailable || (groupAway || groupIdle || groupIdleAndAway)) && !(groupAway && groupIdle) &&
					 !sortIdleTime)){
					sortOrder[i++] = Unavailable;
				}
				break;
				
			case Online:
				if (sortIdleTime && !groupAvailable && !groupUnavailable && !groupAway && !groupIdle && !groupIdleAndAway)
					sortOrder[i++] = Online;
				break;
		}
	}
	
	sortOrder[i] = -1;
	
	sizeOfSortOrder = i;
	
	[tableView_sortOrder reloadData];
}
- (NSString *)description{
    return(@"Sort by Status.");
}
- (NSString *)identifier{
    return(@"by Status");
}
- (NSString *)displayName{
    return(AILocalizedString(@"by Status","Sort Contacts... <by Status>"));
}
- (NSArray *)statusKeysRequiringResort{
	return([NSArray arrayWithObjects:sOnline,sIdle,sAway,nil]);
}
- (NSArray *)attributeKeysRequiringResort{
	return([NSArray arrayWithObject:@"Display Name"]);
}

//Configuration
#pragma mark Configuration
- (NSString *)configureSortMenuItemTitle{ 
	return(AILocalizedString(@"Configure Status Sort...",nil));
}
- (NSString *)configureSortWindowTitle{
	return(AILocalizedString(@"Configure Status Sort",nil));	
}
- (NSString *)configureNibName{
	return @"StatusSortConfiguration";
}

- (void)viewDidLoad
{
	[checkBox_groupAvailable setState:groupAvailable];
	[checkBox_groupAway setState:groupAway];
	[checkBox_groupIdle setState:groupIdle];
	[checkBox_groupIdleAndAway setState:groupIdleAndAway];
	[checkBox_sortIdleTime setState:sortIdleTime];
	[checkBox_alphabeticallyByLastName setState:resolveAlphabeticallyByLastName];
	
	[buttonCell_alphabetically  setState:(resolveAlphabetically ? NSOnState : NSOffState)];
	[buttonCell_manually		setState:(resolveAlphabetically ? NSOffState : NSOnState)];

	[buttonCell_allUnavailable			setState:(groupUnavailable ? NSOnState : NSOffState)];
	[buttonCell_separateUnavailable		setState:(groupUnavailable ? NSOffState : NSOnState)];
	
	[self configureControlDimming];
	
	[tableView_sortOrder setDataSource:self];
	[tableView_sortOrder setDelegate:self];
    [tableView_sortOrder registerForDraggedTypes:[NSArray arrayWithObject:STATUS_DRAG_TYPE]];
}

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

- (void)configureControlDimming
{
	[checkBox_alphabeticallyByLastName setEnabled:resolveAlphabetically];
	[checkBox_groupAway setEnabled:!groupUnavailable];
	[checkBox_groupIdle setEnabled:!groupUnavailable];
	[checkBox_groupIdleAndAway setEnabled:!groupUnavailable];
}

#pragma mark Sort Order Tableview datasource
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return sizeOfSortOrder;
}

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

- (sortfunc)sortFunction{
	return(&statusSort);
}

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
		BOOL onlineA = ([[objectA numberStatusObjectForKey:sOnline] boolValue]);
		BOOL onlineB = ([[objectB numberStatusObjectForKey:sOnline] boolValue]);
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
			away[0] = [objectA integerStatusObjectForKey:sAway];
			away[1] = [objectB integerStatusObjectForKey:sAway];
			
			idle[0] = [objectA integerStatusObjectForKey:sIdle];
			idle[1] = [objectB integerStatusObjectForKey:sIdle];

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
							status = idle[objectCounter];
							break;

						case Away_And_Idle:
							status =  away[objectCounter] && idle[objectCounter];
							definitelyFinishedIfSuccessful = YES;
							break;
							
						case Unavailable:
							status =  away[objectCounter] || idle[objectCounter];
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
				//Ordering is determined if either has a positive idle time and their idle times are not identical
				if ((idle[0] || idle[1]) && (idle[0] != idle[1])){
					if(idle[0] > idle[1]){
						return(NSOrderedDescending);
					}else{
						return(NSOrderedAscending);
					}
				}
			}
		}
		
		//If we made it here, resolve the ordering either alphabetically or by manual ordering
		if (resolveAlphabetically){
			NSComparisonResult returnValue;
			
			if (resolveAlphabeticallyByLastName){
				NSString	*space = @" ";
				NSString	*displayNameA = [objectA displayName];
				NSString	*displayNameB = [objectB displayName];
				NSArray		*componentsA = [displayNameA componentsSeparatedByString:space];
				NSArray		*componentsB = [displayNameB componentsSeparatedByString:space];
				
				returnValue = [[componentsA lastObject] caseInsensitiveCompare:[componentsB lastObject]];
				//If the last names are the same, compare the whole object, which will amount to sorting these objects by first name
				if (returnValue == NSOrderedSame){
					returnValue = [displayNameA caseInsensitiveCompare:displayNameB];
					if (returnValue == NSOrderedSame){
						returnValue = [[objectA uniqueObjectID] caseInsensitiveCompare:[objectB uniqueObjectID]];
					}
				}
			}else{
				returnValue = [[objectA longDisplayName] caseInsensitiveCompare:[objectB longDisplayName]];
				if (returnValue == NSOrderedSame){
					returnValue = [[objectA uniqueObjectID] caseInsensitiveCompare:[objectB uniqueObjectID]];
				}
			}
			
			return (returnValue);
		}else{
			//Keep groups in manual order
			if([objectA orderIndex] > [objectB orderIndex]){
				return(NSOrderedDescending);
			}else{
				return(NSOrderedAscending);
			}
		}
	}
}

@end