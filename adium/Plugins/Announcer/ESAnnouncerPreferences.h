//
//  ESAnnouncerPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Sep 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium;

@interface ESAnnouncerPreferences : NSObject {
    AIAdium			*owner;

    IBOutlet	NSView		*view_prefView;
	
    IBOutlet	NSButton	*checkBox_outgoing;
    IBOutlet	NSButton	*checkBox_incoming;
    IBOutlet	NSButton	*checkBox_status;
    IBOutlet	NSButton	*checkBox_time;
    IBOutlet	NSButton	*checkBox_sender;
}

+ (ESAnnouncerPreferences *)announcerPreferencesWithOwner:(id)inOwner;
- (IBAction)changePreference:(id)sender;

@end
