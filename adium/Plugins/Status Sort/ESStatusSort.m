//
//  ESStatusSort.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Tue Mar 09 2004.
//

#import "ESStatusSort.h"

#define STATUS_SORT_DEFAULT_PREFS   @"StatusSortDefaults"

#define KEY_GROUP_AWAY				@"Status:Group Away"
#define KEY_GROUP_IDLE				@"Status:Group Idle"
#define KEY_SORT_IDLE_TIME			@"Status:Sort by Idle Time"
#define KEY_RESOLVE_ALPHABETICALLY  @"Status:Resolve Alphabetically"

int statusSort(id objectA, id objectB, BOOL groups);

static BOOL	groupAway;
static BOOL	groupIdle;
static BOOL	sortIdleTime;
static BOOL	resolveAlphabetically;

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
	groupAway = [[prefDict objectForKey:KEY_GROUP_AWAY] boolValue];
	groupIdle = [[prefDict objectForKey:KEY_GROUP_IDLE] boolValue];
	sortIdleTime = [[prefDict objectForKey:KEY_SORT_IDLE_TIME] boolValue];
	resolveAlphabetically = [[prefDict objectForKey:KEY_RESOLVE_ALPHABETICALLY] boolValue];
	
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
	[checkBox_groupAway setState:groupAway];
	[checkBox_groupIdle setState:groupIdle];
	[checkBox_sortIdleTime setState:sortIdleTime];
	if (resolveAlphabetically) {
		[buttonCell_alphabetically  setState:NSOnState];
		[buttonCell_manually		setState:NSOffState];
	} else {
		[buttonCell_alphabetically  setState:NSOffState];
		[buttonCell_manually		setState:NSOnState];		
	}
}
- (IBAction)changePreference:(id)sender
{
	if (sender == checkBox_groupAway){
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
			[[adium preferenceController] setPreference:[NSNumber numberWithBool:resolveAlphabetically]
												 forKey:KEY_RESOLVE_ALPHABETICALLY
												  group:PREF_GROUP_CONTACT_SORTING];				
		}else if (selectedCell == buttonCell_manually){
			resolveAlphabetically = NO;
			[[adium preferenceController] setPreference:[NSNumber numberWithBool:resolveAlphabetically]
												 forKey:KEY_RESOLVE_ALPHABETICALLY
												  group:PREF_GROUP_CONTACT_SORTING];				
		}
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
		BOOL onlineA = ([objectA integerStatusObjectForKey:@"Online"]);
		BOOL onlineB = ([objectB integerStatusObjectForKey:@"Online"]);
		if (!onlineB && onlineA){
			return NSOrderedAscending;
		}else if (!onlineA && onlineB){
			return NSOrderedDescending;
		}
		
		//Get the idle times now rather than potentially doing it twice below
		double idleA = ([objectA doubleStatusObjectForKey:@"Idle"]);
		double idleB = ([objectB doubleStatusObjectForKey:@"Idle"]);
		
		//If grouping by idle and one is idle but the other is not, we have our ordering
		if (groupIdle){
			if (idleA && !idleB){
				return(NSOrderedDescending);
			}else if(!idleA && idleB){
				return(NSOrderedAscending);
			}
		}
		
		//If grouping by away and one contact is away but the other isn't, we have our ordering
		if (groupAway){			
			BOOL awayA = ([objectA integerStatusObjectForKey:@"Away"]);
			BOOL awayB = ([objectB integerStatusObjectForKey:@"Away"]);
			
			if(awayA && !awayB){
				return(NSOrderedDescending);
			}else if(!awayA && awayB){
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
			return([[objectA longDisplayName] caseInsensitiveCompare:[objectB longDisplayName]]);
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