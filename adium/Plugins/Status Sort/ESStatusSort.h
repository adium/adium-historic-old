//
//  ESStatusSort.h
//  Adium
//
//  Created by Evan Schoenberg on Tue Mar 09 2004.

@interface ESStatusSort : AISortController {
	IBOutlet	NSButton		*checkBox_groupAvailable;
	IBOutlet	NSButton		*checkBox_groupAway;
	IBOutlet	NSButton		*checkBox_groupIdle;
	IBOutlet	NSButton		*checkBox_sortIdleTime;
	
	IBOutlet	NSMatrix		*matrix_resolution;
	IBOutlet	NSButtonCell	*buttonCell_alphabetically;
	IBOutlet	NSButton		*checkBox_alphabeticallyByLastName;
	IBOutlet	NSButtonCell	*buttonCell_manually;
}

@end
