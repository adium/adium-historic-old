//
//  CSCheckmarkPreferences.h
//  Adium XCode
//
//  Created by Chris Serino on Sun Jan 04 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//


@interface CSCheckmarkPreferences : AIObject {
	IBOutlet	NSView		*view_prefView;
	IBOutlet	NSButton	*checkBox_displayCheckmark;
}
+ (CSCheckmarkPreferences *)checkmarkPreferences;
- (IBAction)changePreference:(id)sender;

@end
