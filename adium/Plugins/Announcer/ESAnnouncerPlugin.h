//
//  ESAnnouncerPlugin.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Sep 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import <Cocoa/Cocoa.h>
#import "ESAnnouncerPreferences.h"


#define PREF_GROUP_SOUNDS	@"Sounds"
#define KEY_ANNOUNCER_OUTGOING	@"Speak Outgoing"
#define KEY_ANNOUNCER_INCOMING 	@"Speak Incoming"
#define KEY_ANNOUNCER_STATUS	@"Speak Status"
#define KEY_ANNOUNCER_TIME	@"Speak Time"
#define KEY_ANNOUNCER_SENDER	@"Speak Sender"

@interface ESAnnouncerPlugin : AIPlugin {
    ESAnnouncerPreferences	* preferences;
    SUSpeaker			* speaker;

    BOOL speakIncoming;
    BOOL speakOutgoing;
    BOOL speakMessages;
    BOOL speakStatus;
    BOOL speakTime;
    BOOL speakSender;
    BOOL observingContent;
}

@end
