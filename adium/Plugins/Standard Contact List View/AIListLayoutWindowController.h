//
//  AIListLayoutWindowController.h
//  Adium
//
//  Created by Adam Iser on Sun Aug 01 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//


#define LIST_LAYOUT_FOLDER						@"Contact List"
#define LIST_LAYOUT_EXTENSION					@"ListLayout"
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

#define KEY_LIST_LAYOUT_WINDOW_SHADOWED			@"Window Shadowed"

#define KEY_LIST_LAYOUT_VERTICAL_AUTOSIZE		@"Vertical Autosizing"
#define KEY_LIST_LAYOUT_HORIZONTAL_AUTOSIZE		@"Horizontal Autosizing"
#define KEY_LIST_LAYOUT_WINDOW_TRANSPARENCY		@"Window Transparency"

#define KEY_LIST_LAYOUT_CONTACT_FONT			@"Contact Font"
#define KEY_LIST_LAYOUT_STATUS_FONT				@"Status Font"
#define KEY_LIST_LAYOUT_GROUP_FONT				@"Group Font"

#define KEY_LIST_LAYOUT_CONTACT_LEFT_INDENT		@"Contact Left Indent"
#define KEY_LIST_LAYOUT_CONTACT_RIGHT_INDENT	@"Contact Right Indent"


typedef enum {
	WINDOW_STYLE_STANDARD = 0,
    WINDOW_STYLE_BORDERLESS,
    WINDOW_STYLE_MOCKIE,
    WINDOW_STYLE_PILLOWS
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
	IBOutlet		NSButton			*checkBox_windowHasShadow;
	IBOutlet		NSButton			*checkBox_verticalAutosizing;
	IBOutlet		NSButton			*checkBox_horizontalAutosizing;

	IBOutlet		NSSlider			*slider_userIconSize;
	IBOutlet		NSTextField			*textField_userIconSize;
	IBOutlet		NSSlider			*slider_contactSpacing;
	IBOutlet		NSTextField			*textField_contactSpacing;
	IBOutlet		NSSlider			*slider_groupTopSpacing;
	IBOutlet		NSTextField			*textField_groupTopSpacing;
	IBOutlet		NSSlider			*slider_groupBottomSpacing;
	IBOutlet		NSTextField			*textField_groupBottomSpacing;
	IBOutlet		NSSlider			*slider_windowTransparency;
	IBOutlet		NSTextField			*textField_windowTransparency;
	IBOutlet		NSSlider			*slider_contactLeftIndent;
	IBOutlet		NSTextField			*textField_contactLeftIndent;
	IBOutlet		NSSlider			*slider_contactRightIndent;
	IBOutlet		NSTextField			*textField_contactRightIndent;
	
	IBOutlet		JVFontPreviewField	*fontField_contact;	
	IBOutlet		JVFontPreviewField	*fontField_status;	
	IBOutlet		JVFontPreviewField	*fontField_group;	
	
	IBOutlet		NSTextField			*textField_layoutName;
	
	NSString				*layoutName;
}

+ (id)listLayoutOnWindow:(NSWindow *)parentWindow withName:(NSString *)inName;
- (IBAction)cancel:(id)sender;
- (IBAction)okay:(id)sender;
- (void)preferenceChanged:(id)sender;

- (NSArray *)availableSetsWithExtension:(NSString *)extension fromFolder:(NSString *)folder;
- (void)applySet:(NSDictionary *)setDictionary toPreferenceGroup:(NSString *)preferenceGroup;
- (void)createSetFromPreferenceGroup:(NSString *)preferenceGroup withName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder;

@end
