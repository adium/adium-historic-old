//
//  ESStatusSort.m
//  Adium
//
//  Created by Evan Schoenberg on Tue Mar 09 2004.
//

#import "ESStatusSort.h"

#define STATUS_SORT_DEFAULT_PREFS   @"StatusSortDefaults"

#define KEY_GROUP_AVAILABLE			@"Status:Group Available"
#define KEY_GROUP_AWAY				@"Status:Group Away"
#define KEY_GROUP_IDLE				@"Status:Group Idle"
#define KEY_SORT_IDLE_TIME			@"Status:Sort by Idle Time"
#define KEY_RESOLVE_ALPHABETICALLY  @"Status:Resolve Alphabetically"
#define KEY_RESOLVE_ALPHABETICALLY_BY_LAST_NAME @"Status:Resolve Alphabetically By Last Name"

int statusSort(id objectA, id objectB, BOOL groups);

static BOOL groupAvailable;
static BOOL	groupAway;
static BOOL	groupIdle;
static BOOL	sortIdleTime;
static BOOL	resolveAlphabetically;
static BOOL resolveAlphabeticallyByLastName;

@implementation ESStatusSort

//Sort contacts and groups by status.

- (id)init
{
	[super init];
	
	//Register our default preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:STATUS_SORT_DEFAULT_PREFS 
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_CONTACT_SORTING];
	
	//Load our preferences
	NSDictionary *prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_SORTING];
	groupAvailable = [[prefDict objectForKey:KEY_GROUP_AVAILABLE] boolValue];
	groupAway = [[prefDict objectForKey:KEY_GROUP_AWAY] boolValue];
	groupIdle = [[prefDict objectForKey:KEY_GROUP_IDLE] boolValue];
	sortIdleTime = [[prefDict objectForKey:KEY_SORT_IDLE_TIME] boolValue];
	resolveAlphabetically = [[prefDict objectForKey:KEY_RESOLVE_ALPHABETICALLY] boolValue];
	resolveAlphabeticallyByLastName = [[prefDict objectForKey:KEY_RESOLVE_ALPHABETICALLY_BY_LAST_NAME] boolValue];
	
	return self;
}

- (NSString *)identifier{
    return(@"by Status");
}
- (NSString *)displayName{
    return(AILocalizedString(@"by Status","Sort Contacts... <by Status>"));
}
- (NSArray *)statusKeysRequiringResort{
	return([NSArray arrayWithObjects:@"Idle", @"Away", nil]);
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
	[checkBox_sortIdleTime setState:sortIdleTime];
	[checkBox_alphabeticallyByLastName setState:resolveAlphabeticallyByLastName];
	if (resolveAlphabetically) {
		[buttonCell_alphabetically  setState:NSOnState];
		[buttonCell_manually		setState:NSOffState];
		[checkBox_alphabeticallyByLastName setEnabled:YES];
	} else {
		[buttonCell_alphabetically  setState:NSOffState];
		[buttonCell_manually		setState:NSOnState];		
		[checkBox_alphabeticallyByLastName setEnabled:NO];
	}
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
	}else if (sender == checkBox_sortIdleTime){
		sortIdleTime = [sender state];
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:sortIdleTime]
                                             forKey:KEY_SORT_IDLE_TIME
                                              group:PREF_GROUP_CONTACT_SORTING];				
	}else if(sender == matrix_resolution){
		id selectedCell = [sender selectedCell];
		
		if (selectedCell == buttonCell_alphabetically){
			resolveAlphabetically = YES;
			[checkBox_alphabeticallyByLastName setEnabled:YES];
			[[adium preferenceController] setPreference:[NSNumber numberWithBool:resolveAlphabetically]
												 forKey:KEY_RESOLVE_ALPHABETICALLY
												  group:PREF_GROUP_CONTACT_SORTING];				
		}else if (selectedCell == buttonCell_manually){
			resolveAlphabetically = NO;
			[checkBox_alphabeticallyByLastName setEnabled:NO];
			[[adium preferenceController] setPreference:[NSNumber numberWithBool:resolveAlphabetically]
												 forKey:KEY_RESOLVE_ALPHABETICALLY
												  group:PREF_GROUP_CONTACT_SORTING];				
		}
	}else if (sender == checkBox_alphabeticallyByLastName){
		resolveAlphabeticallyByLastName = [sender state];
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:resolveAlphabeticallyByLastName]
                                             forKey:KEY_RESOLVE_ALPHABETICALLY_BY_LAST_NAME
                                              group:PREF_GROUP_CONTACT_SORTING];
	}
	
	[[adium contactController] sortContactList];
}

#pragma mark Sorting

- (sortfunc)sortFunction{
	return(&statusSort);
}

int statusSort(id objectA, id objectB, BOOL groups)
{
	if(!groups){
		
		//Always sort offline contacts to the bottom
		BOOL onlineA = ([[objectA numberStatusObjectForKey:@"Online"] boolValue]);
		BOOL onlineB = ([[objectB numberStatusObjectForKey:@"Online"] boolValue]);
		if (!onlineB && onlineA){
			return NSOrderedAscending;
		}else if (!onlineA && onlineB){
			return NSOrderedDescending;
		}
		
		//Get the away state and idle times now rather than potentially doing each twice below
		BOOL awayA = ([objectA integerStatusObjectForKey:@"Away"]);
		BOOL awayB = ([objectB integerStatusObjectForKey:@"Away"]);
		
		int idleA = ([[objectA numberStatusObjectForKey:@"Idle"] intValue]);
		int idleB = ([[objectB numberStatusObjectForKey:@"Idle"] intValue]);
		
		//If grouping by availability and one is either idle or away and the other is neither, we have our ordering
		if (groupAvailable){
			BOOL unavailableA = (awayA || idleA);
			BOOL unavailableB = (awayB || idleB);
			if (unavailableA && !unavailableB){
				return(NSOrderedDescending);
			}else if (unavailableB && !unavailableA){
				return (NSOrderedAscending);
			}
		}
		
		//If grouping by idle and one is idle but the other is not, we have our ordering
		if (groupIdle){
			if (idleA && !idleB){
				return(NSOrderedDescending);
			}else if(idleB && !idleA){
				return(NSOrderedAscending);
			}
		}
		
		//If grouping by away and one contact is away but the other isn't, we have our ordering
		if (groupAway){
			if(awayA && !awayB){
				return(NSOrderedDescending);
			}else if(awayB && !awayA){
				return(NSOrderedAscending);
			}
		}
		
		//If one idle time is greater than the other and we want to sort on that basis, we have an ordering
		if (sortIdleTime){
			//Ordering is determined if either has a positive idle time and their idle times are not identical
			if ((idleA || idleB) && (idleA != idleB)){
				if(idleA > idleB){
					return(NSOrderedDescending);
				}else{
					return(NSOrderedAscending);
				}
			}
		}
		
		//If we made it here, resolve the ordering either alphabetically or by manual ordering
		if (resolveAlphabetically){
			if (resolveAlphabeticallyByLastName){
				NSString	*space = @" ";
				NSArray		*componentsA = [[objectA displayName] componentsSeparatedByString:space];
				NSArray		*componentsB = [[objectB displayName] componentsSeparatedByString:space];
				
				return ([[componentsA lastObject] caseInsensitiveCompare:[componentsB lastObject]]);
				
			}else{
				return([[objectA longDisplayName] caseInsensitiveCompare:[objectB longDisplayName]]);
			}
			
		}else{
			//Keep groups in manual order
			if([objectA orderIndex] > [objectB orderIndex]){
				return(NSOrderedDescending);
			}else{
				return(NSOrderedAscending);
			}
		}
	}else{
		//Keep groups in manual order
		if([objectA orderIndex] > [objectB orderIndex]){
			return(NSOrderedDescending);
		}else{
			return(NSOrderedAscending);
		}
	}
}

@end