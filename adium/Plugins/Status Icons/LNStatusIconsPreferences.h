#import <Cocoa/Cocoa.h>


@interface LNStatusIconsPreferences : NSObject {

    AIAdium			*owner;

    IBOutlet	NSView		*view_prefView;
    IBOutlet	NSButton	*checkBox_displayStatusIcons;


}

+ (LNStatusIconsPreferences *)statusIconsPreferencesWithOwner:(id)inOwner;
- (IBAction)changePreference:(id)sender;

@end
