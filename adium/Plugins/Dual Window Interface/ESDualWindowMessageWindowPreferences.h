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

    IBOutlet	NSButton	*createMessages_inTabs;
    IBOutlet	NSButton	*createTabs_inLastWindow;
    IBOutlet	NSButton	*autohide_tabBar;
}
+ (ESDualWindowMessageWindowPreferences *)dualWindowMessageWindowInterfacePreferencesWithOwner:(id)inOwner;
- (IBAction)changePreference:(id)sender;

@end
