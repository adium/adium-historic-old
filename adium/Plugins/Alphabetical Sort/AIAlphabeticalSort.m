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

#import "AIAlphabeticalSort.h"

#define KEY_SORT_BY_LAST_NAME				@"ABC:Sort by Last Name"
#define KEY_SORT_GROUPS						@"ABC:Sort Groups"
#define ALPHABETICAL_SORT_DEFAULT_PREFS		@"AlphabeticalSortDefaults"

int alphabeticalSort(id objectA, id objectB, BOOL groups);
static 	BOOL	sortGroups;
static  BOOL	sortByLastName;

@implementation AIAlphabeticalSort

//Sort contacts and groups alphabetically.

- (id)init
{
	[super init];
	
	//Register our default preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:ALPHABETICAL_SORT_DEFAULT_PREFS 
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_CONTACT_SORTING];
	
	//Load our preferences
	NSDictionary *prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_SORTING];
	sortGroups = [[prefDict objectForKey:KEY_SORT_GROUPS] boolValue];
	sortByLastName = [[prefDict objectForKey:KEY_SORT_BY_LAST_NAME] boolValue];
	
	return self;
}

- (NSString *)identifier{
    return(@"Alphabetical");
}
- (NSString *)displayName{
    return(AILocalizedString(@"Alphabetically","Sort Contacts... <Alphabetically>"));
}
- (NSArray *)statusKeysRequiringResort{
	return(nil);
}
- (NSArray *)attributeKeysRequiringResort{
	return([NSArray arrayWithObject:@"Display Name"]);
}

#pragma mark Configuration
//Configuration
- (NSString *)configureSortMenuItemTitle{ 
	return(AILocalizedString(@"Configure Alphabetical Sort...",nil));
}
- (NSString *)configureSortWindowTitle{
	return(AILocalizedString(@"Configure Alphabetical Sort",nil));	
}
- (NSString *)configureNibName{
	return @"AlphabeticalSortConfiguration";
}
- (void)viewDidLoad{
	[checkBox_sortByLastName setState:sortByLastName];
	[checkBox_sortGroups setState:sortGroups];
}
- (IBAction)changePreference:(id)sender
{
	if (sender == checkBox_sortGroups){
		sortGroups = [sender state];
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:sortGroups]
                                             forKey:KEY_SORT_GROUPS
                                              group:PREF_GROUP_CONTACT_SORTING];		
	}else if (sender == checkBox_sortByLastName){
		sortByLastName = [sender state];
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:sortByLastName]
                                             forKey:KEY_SORT_BY_LAST_NAME
                                              group:PREF_GROUP_CONTACT_SORTING];			
	}
	
	[[adium contactController] sortContactList];
}

#pragma mark Sorting
//Sort functions
- (sortfunc)sortFunction{
	return(&alphabeticalSort);
}
int alphabeticalSort(id objectA, id objectB, BOOL groups)
{
	//If we were not passed groups or if we should be sorting groups, sort alphabetically
	if (!groups){
		if (sortByLastName){
			NSString	*space = @" ";
			NSArray		*componentsA = [[objectA displayName] componentsSeparatedByString:space];
			NSArray		*componentsB = [[objectB displayName] componentsSeparatedByString:space];
			
			return ([[componentsA lastObject] caseInsensitiveCompare:[componentsB lastObject]]);
			
		}else{
			return([[objectA longDisplayName] caseInsensitiveCompare:[objectB longDisplayName]]);
		}
	}else{
		//If sorting groups, do a caseInsesitiveCompare; otherwise, keep groups in manual order
		if (sortGroups){
			return([[objectA longDisplayName] caseInsensitiveCompare:[objectB longDisplayName]]);
		}else if([objectA orderIndex] > [objectB orderIndex]){
			return(NSOrderedDescending);
		}else{
			return(NSOrderedAscending);
		}
	}
}

@end
