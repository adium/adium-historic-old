//
//  ESDualWindowMessageWindowPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on Thu Sep 18 2003.
//

#import <Cocoa/Cocoa.h>

@class AIAdium;


@interface ESDualWindowMessageWindowPreferences : NSObject {
    AIAdium			*owner;

    IBOutlet	NSView		*view_pref;

    IBOutlet	NSMatrix	*matrix_windowMode;
    IBOutlet	NSButtonCell		*modeWindow;
    IBOutlet	NSButtonCell		*modeTab;
    
    IBOutlet	NSMatrix	*matrix_tabPref;
    IBOutlet	NSButtonCell		*primaryWindow;
    IBOutlet	NSButtonCell		*lastUsedWindow;
}
+ (ESDualWindowMessageWindowPreferences *)dualWindowMessageWindowInterfacePreferencesWithOwner:(id)inOwner;
- (IBAction)changePreference:(id)sender;

@end
