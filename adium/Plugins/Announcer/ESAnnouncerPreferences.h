//
//  ESAnnouncerPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Sep 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@interface ESAnnouncerPreferences : AIPreferencePane {
    IBOutlet	NSButton	*checkBox_outgoing;
    IBOutlet	NSButton	*checkBox_incoming;
    IBOutlet	NSButton	*checkBox_status;
    IBOutlet	NSButton	*checkBox_time;
    IBOutlet	NSButton	*checkBox_sender;
}

@end
