//
//  AIAbstractListController.h
//  Adium
//
//  Created by Evan Schoenberg on 8/21/04.
//

#import <Cocoa/Cocoa.h>
#import "AIWindowController.h"

@class AIAutoScrollView, AIListOutlineView, AIListContactCell, AIListGroupCell;

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

#define	KEY_LIST_LAYOUT_EXTENDED_STATUS_STYLE	@"Extended Status Style"
#define KEY_LIST_LAYOUT_EXTENDED_STATUS_POSITION @"Extended Status Position"
#define KEY_LIST_LAYOUT_USER_ICON_POSITION		@"User Icon Position"
#define KEY_LIST_LAYOUT_STATUS_ICON_POSITION	@"Status Icon Position"
#define KEY_LIST_LAYOUT_SERVICE_ICON_POSITION	@"Service Icon Position"

#define KEY_LIST_LAYOUT_CONTACT_SPACING			@"Contact Spacing"
#define KEY_LIST_LAYOUT_GROUP_TOP_SPACING		@"Group Top Spacing"

#define KEY_LIST_LAYOUT_WINDOW_SHADOWED			@"Window Shadowed"

#define KEY_LIST_LAYOUT_VERTICAL_AUTOSIZE		@"Vertical Autosizing"
#define KEY_LIST_LAYOUT_HORIZONTAL_AUTOSIZE		@"Horizontal Autosizing"
#define KEY_LIST_LAYOUT_HORIZONTAL_WIDTH		@"Horizontal Width"
#define KEY_LIST_LAYOUT_WINDOW_TRANSPARENCY		@"Window Transparency"

#define KEY_LIST_LAYOUT_CONTACT_FONT			@"Contact Font"
#define KEY_LIST_LAYOUT_STATUS_FONT				@"Status Font"
#define KEY_LIST_LAYOUT_GROUP_FONT				@"Group Font"

#define KEY_LIST_LAYOUT_CONTACT_LEFT_INDENT		@"Contact Left Indent"
#define KEY_LIST_LAYOUT_CONTACT_RIGHT_INDENT	@"Contact Right Indent"

#define	KEY_LIST_LAYOUT_OUTLINE_BUBBLE			@"Outline Bubble"
#define	KEY_LIST_LAYOUT_CONTACT_BUBBLE_GRADIENT	@"Contact Bubble Draw With Gradient"
#define	KEY_LIST_LAYOUT_GROUP_HIDE_BUBBLE		@"Group Hide Bubble"
#define	KEY_LIST_LAYOUT_OUTLINE_BUBBLE_WIDTH	@"Outline Bubble Line Width"

typedef enum {
	WINDOW_STYLE_STANDARD = 0,
    WINDOW_STYLE_BORDERLESS,
    WINDOW_STYLE_MOCKIE,
    WINDOW_STYLE_PILLOWS,
    WINDOW_STYLE_PILLOWS_FITTED
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
	EXTENDED_STATUS_POSITION_BESIDE_NAME = 0,
	EXTENDED_STATUS_POSITION_BELOW_NAME
} EXTENDED_STATUS_POSITION;

typedef enum {
	STATUS_ONLY = 0,
	IDLE_ONLY,
	IDLE_AND_STATUS
} EXTENDED_STATUS_STYLE;

//AIListThemeWindowController defines
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

#define KEY_LIST_THEME_BACKGROUND_IMAGE_ENABLED		@"Use Background Image"
#define KEY_LIST_THEME_BACKGROUND_IMAGE_PATH		@"Background Image Path"
#define KEY_LIST_THEME_BACKGROUND_FADE				@"Background Fade"

#define KEY_LIST_THEME_BACKGROUND_COLOR				@"Background Color"
#define KEY_LIST_THEME_GRID_COLOR					@"Grid Color"

#define KEY_LIST_THEME_GROUP_BACKGROUND				@"Group Background"
#define KEY_LIST_THEME_GROUP_BACKGROUND_GRADIENT	@"Group Background Gradient"
#define KEY_LIST_THEME_GROUP_TEXT_COLOR				@"Group Text Color"
#define KEY_LIST_THEME_GROUP_TEXT_COLOR_INVERTED	@"Group Inverted Text Color"
#define KEY_LIST_THEME_GROUP_SHADOW_COLOR			@"Group Shadow Color"
#define KEY_LIST_THEME_GROUP_GRADIENT				@"Group Gradient"
#define KEY_LIST_THEME_GROUP_SHADOW					@"Group Shadow"

#define KEY_LIST_THEME_CONTACT_STATUS_COLOR			@"Contact Status Text Color"

#define KEY_LIST_THEME_GRID_ENABLED					@"Grid Enabled"
#define KEY_LIST_THEME_BACKGROUND_AS_STATUS			@"Background As Status"
#define KEY_LIST_THEME_BACKGROUND_AS_EVENTS			@"Background As Events"

#define KEY_LIST_THEME_FADE_OFFLINE_IMAGES			@"Fade Offline Images"

@protocol AIListControllerDelegate
- (void)performDefaultActionOnSelectedObject:(AIListObject *)listObject sender:(id)sender;
@end

@interface AIAbstractListController : AIObject {	
	AIAutoScrollView					*scrollView_contactList;
    AIListOutlineView					*contactListView;
	
	AISmoothTooltipTracker				*tooltipTracker;
	
	AIListContactCell					*contentCell;
	AIListGroupCell						*groupCell;
	
    AIListObject <AIContainingObject> 	*contactList;
	BOOL								hideRoot;
	
	BOOL								inDrag;
	NSArray								*dragItems;
	
	BOOL								alreadyDidDealloc;	
	
	id									delegate;
}

- (id)initWithContactListView:(AIListOutlineView *)inContactListView inScrollView:(AIAutoScrollView *)inScrollView_contactList delegate:(id<AIListControllerDelegate>)inDelegate;
- (id)delegate;

- (void)setContactListRoot:(ESObjectWithStatus<AIContainingObject> *)newContactListRoot;
- (ESObjectWithStatus<AIContainingObject> *)contactListRoot;

- (void)setHideRoot:(BOOL)inHideRoot;
- (void)reloadData;

- (IBAction)performDefaultActionOnSelectedItem:(id)sender;

- (void)updateLayoutFromPrefDict:(NSDictionary *)prefDict andThemeFromPrefDict:(NSDictionary *)themeDict;
- (void)updateTransparencyFromLayoutDict:(NSDictionary *)layoutDict themeDict:(NSDictionary *)themeDict;
- (void)updateCellRelatedThemePreferencesFromDict:(NSDictionary *)prefDict;

- (void)contactListDesiredSizeChanged:(NSNotification *)notification;
- (void)updateTransparency;
- (BOOL)useAliasesInContactListAsRequested;
- (BOOL)shouldUseContactTextColors;

//Tooltip
- (void)showTooltipAtPoint:(NSPoint)screenPoint;
- (AIListObject *)contactListItemAtScreenPoint:(NSPoint)screenPoint;
- (void)hideTooltip;

@end
