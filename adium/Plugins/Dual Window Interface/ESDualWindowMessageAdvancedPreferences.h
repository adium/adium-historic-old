//
//  ESDualWindowMessageWindowPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on Thu Sep 18 2003.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@interface ESDualWindowMessageAdvancedPreferences : AIPreferencePane {
    IBOutlet	NSButton	*createMessages_inTabs;
    IBOutlet	NSButton	*createTabs_inLastWindow;
    IBOutlet	NSButton	*autohide_tabBar;
}

@end
