//
//  AIContactStatusColoringPreferences.h
//  Adium
//
//  Created by Arno Hautala on Thu May 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium;

@interface AIContactStatusColoringPreferences : NSObject {
    AIAdium			*owner;

    NSDictionary		*preferenceDict;

    IBOutlet	NSView			*view_prefView;
    
    IBOutlet	NSColorWell		*colorWell_signedOff;
    IBOutlet	NSColorWell		*colorWell_signedOn;
    IBOutlet	NSColorWell		*colorWell_online;
    IBOutlet	NSColorWell		*colorWell_away;
    IBOutlet	NSColorWell		*colorWell_idle;
    IBOutlet	NSColorWell		*colorWell_idleAway;
    IBOutlet	NSColorWell		*colorWell_openTab;
    IBOutlet	NSColorWell		*colorWell_unviewedContent;
    IBOutlet	NSColorWell		*colorWell_warning;

    IBOutlet	NSColorWell		*colorWell_signedOffInverted;
    IBOutlet	NSColorWell		*colorWell_signedOnInverted;
    IBOutlet	NSColorWell		*colorWell_onlineInverted;
    IBOutlet	NSColorWell		*colorWell_awayInverted;
    IBOutlet	NSColorWell		*colorWell_idleInverted;
    IBOutlet	NSColorWell		*colorWell_idleAwayInverted;
    IBOutlet	NSColorWell		*colorWell_openTabInverted;
    IBOutlet	NSColorWell		*colorWell_unviewedContentInverted;
    IBOutlet	NSColorWell		*colorWell_warningInverted;
}

+ (AIContactStatusColoringPreferences *)contactStatusColoringPreferencesWithOwner:(id)inOwner;
- (IBAction)changePreference:(id)sender;

@end
