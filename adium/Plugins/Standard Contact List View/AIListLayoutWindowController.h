//
//  AIListLayoutWindowController.h
//  Adium
//
//  Created by Adam Iser on Sun Aug 01 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#define PREF_GROUP_LIST_LAYOUT				@"List Layout"
#define KEY_LIST_LAYOUT_ALIGNMENT			@"Contact Text Alignment"
#define KEY_LIST_LAYOUT_GROUP_ALIGNMENT		@"Group Text Alignment"
#define KEY_LIST_LAYOUT_SHOW_ICON			@"Show User Icon"
#define KEY_LIST_LAYOUT_USER_ICON_SIZE		@"User Icon Size"
#define KEY_LIST_LAYOUT_SHOW_EXT_STATUS		@"Show Extended Status"
#define KEY_LIST_LAYOUT_SHOW_STATUS_ICONS	@"Show Status Icons"
#define KEY_LIST_LAYOUT_SHOW_SERVICE_ICONS	@"Show Service Icons"
#define KEY_LIST_LAYOUT_WINDOW_STYLE		@"Window Style"

typedef enum {
	WINDOW_STYLE_STANDARD = 0,
    WINDOW_STYLE_MOCKIE,
    WINDOW_STYLE_BORDERLESS
} LIST_WINDOW_STYLE;

@interface AIListLayoutWindowController : AIWindowController {
	IBOutlet		NSPopUpButton		*popUp_contactTextAlignment;
	IBOutlet		NSPopUpButton		*popUp_groupTextAlignment;
	IBOutlet		NSPopUpButton		*popUp_windowStyle;

	IBOutlet		NSButton			*checkBox_userIconVisible;
	IBOutlet		NSButton			*checkBox_extendedStatusVisible;
	IBOutlet		NSButton			*checkBox_statusIconsVisible;
	IBOutlet		NSButton			*checkBox_serviceIconsVisible;
	
	IBOutlet		NSSlider			*slider_userIconSize;
	IBOutlet		NSTextField			*textField_userIconSize;
	
}

+ (id)listLayoutOnWindow:(NSWindow *)parentWindow;
- (IBAction)cancel:(id)sender;
- (IBAction)okay:(id)sender;
- (void)preferenceChanged:(id)sender;

@end
