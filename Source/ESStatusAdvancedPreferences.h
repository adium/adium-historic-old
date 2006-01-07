//
//  ESStatusAdvancedPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on 1/6/06.
//

#import <Adium/AIPreferencePane.h>

@interface ESStatusAdvancedPreferences : AIPreferencePane {
	IBOutlet	NSTextField	*label_statusWindow;
	IBOutlet	NSButton	*checkBox_statusWindowHideInBackground;
	IBOutlet	NSButton	*checkBox_statusWindowAlwaysOnTop;	
}

@end
