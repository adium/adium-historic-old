//
//  AIListThemeWindowController.h
//  Adium
//
//  Created by Adam Iser on Wed Aug 04 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#define PREF_GROUP_LIST_THEME		@"List Theme"

// Contact List Colors Enabled
#define KEY_AWAY_ENABLED			@"Away Enabled"
#define KEY_IDLE_ENABLED			@"Idle Enabled"
#define KEY_TYPING_ENABLED			@"Typing Enabled"
#define KEY_SIGNED_OFF_ENABLED		@"Signed Off Enabled"
#define KEY_SIGNED_ON_ENABLED		@"Signed On Enabled"
#define KEY_UNVIEWED_ENABLED		@"Unviewed Content Enabled"
#define KEY_ONLINE_ENABLED			@"Online Enabled"
#define KEY_IDLE_AWAY_ENABLED		@"Idle And Away Enabled"
#define KEY_OFFLINE_ENABLED			@"Offline Enabled"

#define KEY_LABEL_AWAY_COLOR		@"Away Label Color"
#define KEY_LABEL_IDLE_COLOR		@"Idle Label Color"
#define KEY_LABEL_TYPING_COLOR		@"Typing Label Color"
#define KEY_LABEL_SIGNED_OFF_COLOR	@"Signed Off Label Color"
#define KEY_LABEL_SIGNED_ON_COLOR	@"Signed On Label Color"
#define KEY_LABEL_UNVIEWED_COLOR	@"Unviewed Content Label Color"
#define KEY_LABEL_ONLINE_COLOR		@"Online Label Color"
#define KEY_LABEL_IDLE_AWAY_COLOR	@"Idle And Away Label Color"
#define KEY_LABEL_OFFLINE_COLOR		@"Offline Label Color"

#define KEY_AWAY_COLOR				@"Away Color"
#define KEY_IDLE_COLOR				@"Idle Color"
#define KEY_TYPING_COLOR			@"Typing Color"
#define KEY_SIGNED_OFF_COLOR		@"Signed Off Color"
#define KEY_SIGNED_ON_COLOR			@"Signed On Color"
#define KEY_UNVIEWED_COLOR			@"Unviewed Content Color"
#define KEY_ONLINE_COLOR			@"Online Color"
#define KEY_IDLE_AWAY_COLOR			@"Idle And Away Color"
#define KEY_OFFLINE_COLOR			@"Offline Color"

#define KEY_LIST_THEME_TRANSPARENCY				@"Transparency"
#define KEY_LIST_THEME_BACKGROUND_IMAGE_ENABLED	@"Use Background Image"
#define KEY_LIST_THEME_BACKGROUND_IMAGE_PATH	@"Background Image Path"

@interface AIListThemeWindowController : AIWindowController {
    IBOutlet	NSButton	*checkBox_signedOff;
    IBOutlet	NSColorWell	*colorWell_signedOff;
    IBOutlet	NSColorWell	*colorWell_signedOffLabel;
	
    IBOutlet	NSButton	*checkBox_signedOn;
    IBOutlet	NSColorWell	*colorWell_signedOn;
    IBOutlet	NSColorWell	*colorWell_signedOnLabel;
	
    IBOutlet	NSButton	*checkBox_away;
    IBOutlet	NSColorWell	*colorWell_away;
    IBOutlet	NSColorWell	*colorWell_awayLabel;
	
    IBOutlet	NSButton	*checkBox_idle;
    IBOutlet	NSColorWell	*colorWell_idle;
    IBOutlet	NSColorWell	*colorWell_idleLabel;
	
    IBOutlet	NSButton	*checkBox_typing;
    IBOutlet	NSColorWell	*colorWell_typing;
    IBOutlet	NSColorWell	*colorWell_typingLabel;
	
    IBOutlet	NSButton	*checkBox_unviewedContent;
    IBOutlet	NSColorWell	*colorWell_unviewedContent;
    IBOutlet	NSColorWell	*colorWell_unviewedContentLabel;
	
    IBOutlet	NSButton	*checkBox_online;
    IBOutlet	NSColorWell	*colorWell_online;
    IBOutlet	NSColorWell	*colorWell_onlineLabel;
	
    IBOutlet	NSButton	*checkBox_idleAndAway;
    IBOutlet	NSColorWell	*colorWell_idleAndAway;
    IBOutlet	NSColorWell	*colorWell_idleAndAwayLabel;
	
    IBOutlet	NSButton	*checkBox_offline;
    IBOutlet	NSColorWell	*colorWell_offline;
    IBOutlet	NSColorWell	*colorWell_offlineLabel;
	
	IBOutlet	NSButton	*checkBox_useBackgroundImage;
	IBOutlet	NSButton	*button_setBackgroundImage;
	IBOutlet	NSTextField	*textField_backgroundImagePath;
	
}

+ (id)listThemeOnWindow:(NSWindow *)parentWindow;
- (IBAction)cancel:(id)sender;
- (IBAction)okay:(id)sender;
- (void)preferenceChanged:(id)sender;
- (IBAction)selectBackgroundImage:(id)sender;

@end
