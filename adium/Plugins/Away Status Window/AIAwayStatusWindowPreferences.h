//
//  AIAwayStatusWindowPreferences.h
//  Adium
//
//  Created by Adam Iser on Tue May 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AIAwayStatusWindowPreferences : NSObject {
    AIAdium				*owner;
    IBOutlet	NSView			*view_prefView;
    IBOutlet	NSButton		*checkBox_showAway;
    IBOutlet	NSButton		*checkBox_floatAway;
    IBOutlet 	NSButton		*checkBox_hideInBackground;
    
}

+ (AIAwayStatusWindowPreferences *)awayStatusWindowPreferencesWithOwner:(id)inOwner;
- (IBAction)toggleShowAway:(id)sender;
- (IBAction)toggleHideInBackground:(id)sender;
- (IBAction)toggleFloatAway:(id)sender;

@end
