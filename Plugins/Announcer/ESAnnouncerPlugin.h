//
//  ESAnnouncerPlugin.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Sep 14 2003.
//

#define ANNOUNCER_DEFAULT_PREFS 	@"AnnouncerDefaults"
#define PREF_GROUP_ANNOUNCER		@"Announcer"
#define KEY_ANNOUNCER_TIME			@"Speak Time"
#define KEY_ANNOUNCER_SENDER		@"Speak Sender"

#define KEY_ANNOUNCER_TEXT_TO_SPEAK @"TextToSpeak"

#define KEY_VOICE_STRING				@"Voice"
#define KEY_PITCH						@"Pitch"
#define KEY_RATE						@"Rate"

#define SPEAK_TEXT_ALERT_IDENTIFIER		@"SpeakText"
#define SPEAK_EVENT_ALERT_IDENTIFIER	@"SpeakEvent"

#define	SPEAK_EVENT_TIME				AILocalizedString(@"Speak Event Time",nil)

@interface ESAnnouncerPlugin : AIPlugin <AIActionHandler> {
    NSString					*lastSenderString;
    
    //Contact Editor view
    IBOutlet	NSView			*view_contactAnnouncerInfoView;
    IBOutlet	NSPopUpButton	*popUp_voice;
    IBOutlet	NSSlider		*slider_pitch;
    IBOutlet	NSSlider		*slider_rate;
    AIPreferenceViewController	*contactView;
    AIListObject                *activeListObject;
}

- (IBAction)changedSetting:(id)sender;

+ (BOOL)customEventSpeechHandlingForEventID:(NSString *)eventID;

@end
