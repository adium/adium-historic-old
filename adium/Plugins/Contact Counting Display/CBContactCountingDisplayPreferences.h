//
//  CBContactCountingDisplayPreferences.h
//  Adium XCode
//
//  Created by Colin Barrett on Sun Jan 11 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@interface CBContactCountingDisplayPreferences : AIObject {
	IBOutlet	NSView		*view_prefView;
	IBOutlet	NSButton	*checkBox_visibleContacts;
	IBOutlet	NSButton	*checkBox_allContacts;
}
+ (CBContactCountingDisplayPreferences *)contactCountingDisplayPreferences;
- (IBAction)changePreference:(id)sender;

@end
