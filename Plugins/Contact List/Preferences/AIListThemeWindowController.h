//
//  AIListThemeWindowController.h
//  Adium
//
//  Created by Adam Iser on Wed Aug 04 2004.
//

@class AITextColorPreviewView;

@interface AIListThemeWindowController : AIWindowController {
	IBOutlet	NSTextField				*textField_themeName;
	
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
	IBOutlet	NSSlider				*slider_backgroundFade;
	IBOutlet	NSTextField				*textField_backgroundFade;
	
	IBOutlet	NSColorWell				*colorWell_background;
	IBOutlet	AITextColorPreviewView	*preview_background;
	IBOutlet	NSColorWell				*colorWell_grid;
	IBOutlet	AITextColorPreviewView	*preview_grid;
	IBOutlet	NSButton				*checkBox_drawGrid;
	IBOutlet	NSButton				*checkBox_backgroundAsStatus;
	IBOutlet	NSButton				*checkBox_backgroundAsEvents;
	IBOutlet	NSColorWell				*colorWell_statusText;
	IBOutlet	NSButton				*checkBox_fadeOfflineImages;

	IBOutlet	NSButton				*checkBox_groupGradient;
	IBOutlet	NSButton				*checkBox_groupShadow;
	IBOutlet	NSColorWell				*colorWell_groupText;
	IBOutlet	NSColorWell				*colorWell_groupShadow;
	IBOutlet	NSColorWell				*colorWell_groupBackground;
	IBOutlet	NSColorWell				*colorWell_groupBackgroundGradient;
	IBOutlet	AITextColorPreviewView	*preview_group;
	
	NSString				*themeName;
}

+ (id)listThemeOnWindow:(NSWindow *)parentWindow withName:(NSString *)inName;
- (IBAction)cancel:(id)sender;
- (IBAction)okay:(id)sender;
- (void)preferenceChanged:(id)sender;
- (IBAction)selectBackgroundImage:(id)sender;

@end
