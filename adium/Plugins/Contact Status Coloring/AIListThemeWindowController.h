//
//  AIListThemeWindowController.h
//  Adium
//
//  Created by Adam Iser on Wed Aug 04 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#define LIST_THEME_FOLDER			@"Contact List"
#define LIST_THEME_EXTENSION		@"ListTheme"
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

#define KEY_LIST_THEME_BACKGROUND_IMAGE_ENABLED	@"Use Background Image"
#define KEY_LIST_THEME_BACKGROUND_IMAGE_PATH	@"Background Image Path"
#define KEY_LIST_THEME_BACKGROUND_FADE			@"Background Fade"

#define KEY_LIST_THEME_BACKGROUND_COLOR			@"Background Color"
#define KEY_LIST_THEME_GRID_COLOR				@"Grid Color"

#define KEY_LIST_THEME_GROUP_BACKGROUND				@"Group Background"
#define KEY_LIST_THEME_GROUP_BACKGROUND_GRADIENT	@"Group Background Gradient"
#define KEY_LIST_THEME_GROUP_TEXT_COLOR				@"Group Text Color"
#define KEY_LIST_THEME_GROUP_SHADOW_COLOR			@"Group Shadow Color"

//#define KEY_LIST_THEME_

@class AITextColorPreviewView;

@interface AIListThemeWindowController : AIWindowController {
    IBOutlet	NSButton				*checkBox_signedOff;
    IBOutlet	NSColorWell				*colorWell_signedOff;
    IBOutlet	NSColorWell				*colorWell_signedOffLabel;
	IBOutlet	AITextColorPreviewView	*preview_signedOff;
	
    IBOutlet	NSButton				*checkBox_signedOn;
    IBOutlet	NSColorWell				*colorWell_signedOn;
    IBOutlet	NSColorWell				*colorWell_signedOnLabel;
	IBOutlet	AITextColorPreviewView	*preview_signedOn;
	
    IBOutlet	NSButton				*checkBox_away;
    IBOutlet	NSColorWell				*colorWell_away;
    IBOutlet	NSColorWell				*colorWell_awayLabel;
	IBOutlet	AITextColorPreviewView	*preview_away;
	
    IBOutlet	NSButton				*checkBox_idle;
    IBOutlet	NSColorWell				*colorWell_idle;
    IBOutlet	NSColorWell				*colorWell_idleLabel;
	IBOutlet	AITextColorPreviewView	*preview_idle;
	
    IBOutlet	NSButton				*checkBox_typing;
    IBOutlet	NSColorWell				*colorWell_typing;
    IBOutlet	NSColorWell				*colorWell_typingLabel;
	IBOutlet	AITextColorPreviewView	*preview_typing;
	
    IBOutlet	NSButton				*checkBox_unviewedContent;
    IBOutlet	NSColorWell				*colorWell_unviewedContent;
    IBOutlet	NSColorWell				*colorWell_unviewedContentLabel;
	IBOutlet	AITextColorPreviewView	*preview_unviewedContent;
	
    IBOutlet	NSButton				*checkBox_online;
    IBOutlet	NSColorWell				*colorWell_online;
    IBOutlet	NSColorWell				*colorWell_onlineLabel;
	IBOutlet	AITextColorPreviewView	*preview_online;
	
    IBOutlet	NSButton				*checkBox_idleAndAway;
    IBOutlet	NSColorWell				*colorWell_idleAndAway;
    IBOutlet	NSColorWell				*colorWell_idleAndAwayLabel;
	IBOutlet	AITextColorPreviewView	*preview_idleAndAway;
	
    IBOutlet	NSButton				*checkBox_offline;
    IBOutlet	NSColorWell				*colorWell_offline;
    IBOutlet	NSColorWell				*colorWell_offlineLabel;
	IBOutlet	AITextColorPreviewView	*preview_offline;
	
	IBOutlet	NSButton				*checkBox_useBackgroundImage;
	IBOutlet	NSButton				*button_setBackgroundImage;
	IBOutlet	NSTextField				*textField_backgroundImagePath;
	
	IBOutlet	NSColorWell				*colorWell_background;
	IBOutlet	AITextColorPreviewView	*preview_background;
	IBOutlet	NSColorWell				*colorWell_grid;
	IBOutlet	AITextColorPreviewView	*preview_grid;
	
	IBOutlet	NSSlider				*slider_backgroundFade;
	IBOutlet	NSTextField				*textField_backgroundFade;
	
	IBOutlet	NSColorWell				*colorWell_groupText;
	IBOutlet	NSColorWell				*colorWell_groupBackground;
	IBOutlet	NSColorWell				*colorWell_groupBackgroundGradient;
	IBOutlet	NSColorWell				*colorWell_groupShadow;
	IBOutlet	AITextColorPreviewView	*preview_groupBackground;

	IBOutlet	NSTextField				*textField_themeName;
	
	NSString				*themeName;
}

+ (id)listThemeOnWindow:(NSWindow *)parentWindow withName:(NSString *)inName;
- (IBAction)cancel:(id)sender;
- (IBAction)okay:(id)sender;
- (void)preferenceChanged:(id)sender;
- (IBAction)selectBackgroundImage:(id)sender;

@end
