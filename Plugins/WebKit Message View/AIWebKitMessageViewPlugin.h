/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
| This program is free software; you can redistribute it and/or modify it under the terms of the GNU
| General Public License as published by the Free Software Foundation; either version 2 of the License,
| or (at your option) any later version.
|
| This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
| the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
| Public License for more details.
|
| You should have received a copy of the GNU General Public License along with this program; if not,
| write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
\------------------------------------------------------------------------------------------------------ */

#define PREF_GROUP_WEBKIT_MESSAGE_DISPLAY	@"WebKit Message Display"
#define WEBKIT_DEFAULT_PREFS				@"WebKit Defaults"

#define KEY_WEBKIT_VERSION					@"MessageViewVersion"
#define	KEY_WEBKIT_TIME_STAMP_FORMAT		@"Time Stamp"
#define KEY_WEBKIT_SHOW_USER_ICONS			@"Show User Icons"
#define KEY_WEBKIT_NAME_FORMAT				@"Name Format"
#define KEY_WEBKIT_USE_NAME_FORMAT			@"Use Custom Name Format"
#define KEY_WEBKIT_STYLE					@"Message Style"
#define KEY_WEBKIT_COMBINE_CONSECUTIVE		@"Combine Consecutive Messages"
#define KEY_WEBKIT_DEFAULT_FONT_FAMILY		@"DefaultFontFamily"
#define KEY_WEBKIT_DEFAULT_FONT_SIZE		@"DefaultFontSize"
#define KEY_WEBKIT_USE_BACKGROUND			@"Use Background Color"
#define KEY_WEBKIT_TEMP_LOCATION			@"Current Background Temp Path"

#define NEW_CONTENT_RETRY_DELAY				0.01

#define MESSAGE_STYLES_SUBFOLDER_OF_APP_SUPPORT @"Message Styles"

#import <WebKit/WebKit.h>
#import "ESWebKitMessageViewPreferences.h"
#import "ESWKMVAdvancedPreferences.h"

typedef enum {
	Display_Name = 1,
	Display_Name_Screen_Name = 2,
	Screen_Name_Display_Name = 3,
	Screen_Name = 4
} NameFormat;

typedef enum {
	Fill = 0,
	Tile,
	NoStretch,
	Center
} AIImageBackgroundStyle;

@interface AIWebKitMessageViewPlugin : AIPlugin <AIMessageViewPlugin> {
	ESWebKitMessageViewPreferences  *preferences;
	ESWKMVAdvancedPreferences		*advancedPreferences;
	
	
	NSMutableDictionary				*styleDictionary;
}

- (id <AIMessageViewController>)messageViewControllerForChat:(AIChat *)inChat;

- (NSDictionary *)availableStyleDictionary;
- (NSBundle *)messageStyleBundleWithName:(NSString *)name;

- (NSString *)variantKeyForStyle:(NSString *)desiredStyle;
- (NSString *)backgroundKeyForStyle:(NSString *)desiredStyle;
- (NSString *)cachedBackgroundKeyForStyle:(NSString *)desiredStyle;
- (NSString *)backgroundColorKeyForStyle:(NSString *)desiredStyle;

- (BOOL)boolForKey:(NSString *)key style:(NSBundle *)style variant:(NSString *)variant boolDefault:(BOOL)defaultValue;
- (id)valueForKey:(NSString *)key style:(NSBundle *)style variant:(NSString *)variant;

@end
