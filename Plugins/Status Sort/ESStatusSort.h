//
//  ESStatusSort.h
//  Adium
//
//  Created by Evan Schoenberg on Tue Mar 09 2004.

typedef enum {
	Available = 0,
	Away = 1,
	Idle = 2,
	Away_And_Idle = 3,
	Unavailable = 4,
	Online = 5
} Status_Sort_Type;

@interface ESStatusSort : AISortController {
	IBOutlet	NSButton		*checkBox_groupAvailable;
	IBOutlet	NSButton		*checkBox_groupAway;
	IBOutlet	NSButton		*checkBox_groupIdle;
	IBOutlet	NSButton		*checkBox_groupIdleAndAway;
	IBOutlet	NSButton		*checkBox_sortIdleTime;
	
	IBOutlet	NSMatrix		*matrix_resolution;
	IBOutlet	NSButtonCell	*buttonCell_alphabetically;
	IBOutlet	NSButton		*checkBox_alphabeticallyByLastName;
	IBOutlet	NSButtonCell	*buttonCell_manually;
	
	IBOutlet	NSMatrix		*matrix_unavailableGrouping;
	IBOutlet	NSButtonCell	*buttonCell_allUnavailable;
	IBOutlet	NSButtonCell	*buttonCell_separateUnavailable;
		
	IBOutlet	NSTableView		*tableView_sortOrder;
}

@end
