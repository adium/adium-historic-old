//
//  AIListLayoutWindowController.h
//  Adium
//
//  Created by Adam Iser on Sun Aug 01 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#define PREF_GROUP_LIST_LAYOUT					@"List Layout"
#define KEY_LIST_LAYOUT_ALIGNMENT				@"Contact Text Alignment"
#define KEY_LIST_LAYOUT_GROUP_ALIGNMENT			@"Group Text Alignment"
#define KEY_LIST_LAYOUT_SHOW_ICON				@"Show User Icon"
#define KEY_LIST_LAYOUT_USER_ICON_SIZE			@"User Icon Size"
#define KEY_LIST_LAYOUT_SHOW_EXT_STATUS			@"Show Extended Status"
#define KEY_LIST_LAYOUT_SHOW_STATUS_ICONS		@"Show Status Icons"
#define KEY_LIST_LAYOUT_SHOW_SERVICE_ICONS		@"Show Service Icons"
#define KEY_LIST_LAYOUT_WINDOW_STYLE			@"Window Style"

#define KEY_LIST_LAYOUT_USER_ICON_POSITION		@"User Icon Position"
#define KEY_LIST_LAYOUT_STATUS_ICON_POSITION	@"Status Icon Position"
#define KEY_LIST_LAYOUT_SERVICE_ICON_POSITION	@"Service Icon Position"

#define KEY_LIST_LAYOUT_CONTACT_SPACING			@"Contact Spacing"
#define KEY_LIST_LAYOUT_GROUP_TOP_SPACING		@"Group Top Spacing"
#define KEY_LIST_LAYOUT_GROUP_BOTTOM_SPACING	@"Group Bottom Spacing"

#define KEY_LIST_LAYOUT_CONTACT_CELL_STYLE		@"Contact Cell Style"
#define KEY_LIST_LAYOUT_GROUP_CELL_STYLE		@"Group Cell Style"

typedef enum {
	WINDOW_STYLE_STANDARD = 0,
    WINDOW_STYLE_MOCKIE,
    WINDOW_STYLE_BORDERLESS
} LIST_WINDOW_STYLE;

typedef enum {
	LIST_POSITION_NA = -1,
	LIST_POSITION_FAR_LEFT,
	LIST_POSITION_LEFT,
	LIST_POSITION_RIGHT,
	LIST_POSITION_FAR_RIGHT,
	LIST_POSITION_BADGE_LEFT,
	LIST_POSITION_BADGE_RIGHT,
} LIST_POSITION;

typedef enum {
	CELL_STYLE_STANDARD = 0,
    CELL_STYLE_BRICK,
    CELL_STYLE_BUBBLE,
    CELL_STYLE_BUBBLE_FIT
} LIST_CELL_STYLE;

@interface AIListLayoutWindowController : AIWindowController {
	IBOutlet		NSPopUpButton		*popUp_contactTextAlignment;
	IBOutlet		NSPopUpButton		*popUp_groupTextAlignment;
	IBOutlet		NSPopUpButton		*popUp_windowStyle;
	IBOutlet		NSPopUpButton		*popUp_userIconPosition;
	IBOutlet		NSPopUpButton		*popUp_statusIconPosition;
	IBOutlet		NSPopUpButton		*popUp_serviceIconPosition;
	IBOutlet		NSPopUpButton		*popUp_contactCellStyle;
	IBOutlet		NSPopUpButton		*popUp_groupCellStyle;

	IBOutlet		NSButton			*checkBox_userIconVisible;
	IBOutlet		NSButton			*checkBox_extendedStatusVisible;
	IBOutlet		NSButton			*checkBox_statusIconsVisible;
	IBOutlet		NSButton			*checkBox_serviceIconsVisible;
	
	IBOutlet		NSSlider			*slider_userIconSize;
	IBOutlet		NSTextField			*textField_userIconSize;
	IBOutlet		NSSlider			*slider_contactSpacing;
	IBOutlet		NSTextField			*textField_contactSpacing;
	IBOutlet		NSSlider			*slider_groupTopSpacing;
	IBOutlet		NSTextField			*textField_groupTopSpacing;
	IBOutlet		NSSlider			*slider_groupBottomSpacing;
	IBOutlet		NSTextField			*textField_groupBottomSpacing;
}

+ (id)listLayoutOnWindow:(NSWindow *)parentWindow;
- (IBAction)cancel:(id)sender;
- (IBAction)okay:(id)sender;
- (void)preferenceChanged:(id)sender;

@end
