//
//  ESAnnouncerPlugin.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Sep 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESAnnouncerPreferences.h"

#define ANNOUNCER_DEFAULT_PREFS 	@"AnnouncerDefaults"
#define PREF_GROUP_ANNOUNCER	@"Announcer"
#define KEY_ANNOUNCER_ENABLED   @"Speech Enabled"
#define KEY_ANNOUNCER_OUTGOING	@"Speak Outgoing"
#define KEY_ANNOUNCER_INCOMING 	@"Speak Incoming"
#define KEY_ANNOUNCER_MESSAGETEXT @"Speak Message Text"
#define KEY_ANNOUNCER_STATUS	@"Speak Status"
#define KEY_ANNOUNCER_TIME	@"Speak Time"
#define KEY_ANNOUNCER_SENDER	@"Speak Sender"

#define VOICE_STRING			@"Voice"
#define PITCH				@"Pitch"
#define RATE				@"Rate"

#define CONTACT_ALERT_IDENTIFIER        @"Speak"

@interface ESAnnouncerPlugin : AIPlugin <AIPreferenceViewControllerDelegate,ESContactAlertProvider>{
    ESAnnouncerPreferences	*preferences;

    NSString 			*lastSenderString;
    
	BOOL						speechEnabled;
    BOOL                        speakIncoming;
    BOOL                        speakOutgoing;
    BOOL                        speakMessages;
    BOOL                        speakMessageText;
    BOOL                        speakStatus;
    BOOL                        speakTime;
    BOOL                        speakSender;
    BOOL                        observingContent;

    //Contact Editor view
    IBOutlet	NSView		*view_contactAnnouncerInfoView;
    IBOutlet	NSPopUpButton	*popUp_voice;
    IBOutlet	NSSlider	*slider_pitch;
    IBOutlet	NSSlider	*slider_rate;
    AIPreferenceViewController	*contactView;
    AIListObject                *activeListObject;
}

- (IBAction)changedSetting:(id)sender;

@end
