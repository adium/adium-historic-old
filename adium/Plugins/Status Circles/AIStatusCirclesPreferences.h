//
//  AIStatusCirclePreferences.h
//  Adium
//
//  Created by Arno Hautala on Thu May 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium;

@interface AIStatusCirclesPreferences : NSObject {
    AIAdium			*owner;

    NSDictionary		*preferenceDict;

    IBOutlet	NSView			*view_prefView;

    IBOutlet	NSButton		*checkBox_displayIdle;

    IBOutlet	NSColorWell		*colorWell_signedOff;
    IBOutlet	NSColorWell		*colorWell_signedOn;
    IBOutlet	NSColorWell		*colorWell_online;
    IBOutlet	NSColorWell		*colorWell_away;
    IBOutlet	NSColorWell		*colorWell_idle;
    IBOutlet	NSColorWell		*colorWell_idleAway;
    IBOutlet	NSColorWell		*colorWell_openTab;
    IBOutlet	NSColorWell		*colorWell_unviewedContent;
    IBOutlet	NSColorWell		*colorWell_warning;
}

+ (AIStatusCirclesPreferences *)statusCirclesPreferencesWithOwner:(id)inOwner;
- (IBAction)changePreference:(id)sender;

@end
