//
//  ESStatusAdvancedPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on 1/6/06.
//

#import <Adium/AIAdvancedPreferencePane.h>

@interface ESStatusAdvancedPreferences : AIAdvancedPreferencePane {
	IBOutlet	NSTextField	*label_statusWindow;
	IBOutlet	NSButton	*checkBox_statusWindowHideInBackground;
	IBOutlet	NSButton	*checkBox_statusWindowAlwaysOnTop;	
	
	IBOutlet	NSTextField *label_statusMenuItem;
	IBOutlet	NSButton	*checkBox_statusMenuItemBadge;
	IBOutlet	NSButton	*checkBox_statusMenuItemFlash;
}

@end
