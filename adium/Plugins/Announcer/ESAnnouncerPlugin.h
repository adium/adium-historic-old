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


#define PREF_GROUP_ANNOUNCER	@"Announcer"
#define KEY_ANNOUNCER_OUTGOING	@"Speak Outgoing"
#define KEY_ANNOUNCER_INCOMING 	@"Speak Incoming"
#define KEY_ANNOUNCER_STATUS	@"Speak Status"
#define KEY_ANNOUNCER_TIME	@"Speak Time"
#define KEY_ANNOUNCER_SENDER	@"Speak Sender"

#define VOICE_STRING			@"Voice"
#define PITCH				@"Pitch"
#define RATE				@"Rate"

@interface ESAnnouncerPlugin : AIPlugin <AIPreferenceViewControllerDelegate> {
    ESAnnouncerPreferences	* preferences;

    NSString 			* lastSenderString;
    BOOL speakIncoming;
    BOOL speakOutgoing;
    BOOL speakMessages;
    BOOL speakStatus;
    BOOL speakTime;
    BOOL speakSender;
    BOOL observingContent;

    //Contact Editor view
    IBOutlet	NSView		*view_contactAnnouncerInfoView;
    IBOutlet	NSPopUpButton	*popUp_voice;
    IBOutlet	NSSlider	*slider_pitch;
    IBOutlet	NSSlider	*slider_rate;
    AIPreferenceViewController	*contactView;
    AIListObject	*activeListObject;
}

- (IBAction)changedSetting:(id)sender;

@end
