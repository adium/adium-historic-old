/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import <Adium/AIPlugin.h>
#import <WebKit/WebKit.h>
#import "ESWebKitMessageViewPreferences.h"

#define PREF_GROUP_WEBKIT_MESSAGE_DISPLAY		@"WebKit Message Display"
#define PREF_GROUP_WEBKIT_BACKGROUND_IMAGES		@"WebKit Custom Backgrounds"
#define WEBKIT_DEFAULT_PREFS					@"WebKit Defaults"

#define KEY_WEBKIT_SHOW_USER_ICONS				@"Show User Icons"
#define KEY_WEBKIT_SHOW_HEADER					@"Show Header"
#define KEY_WEBKIT_SHOW_MESSAGE_COLORS			@"Show Message Colors"
#define KEY_WEBKIT_SHOW_MESSAGE_FONTS			@"Show Message Fonts"
#define KEY_WEBKIT_NAME_FORMAT					@"Name Format"
#define KEY_WEBKIT_USE_NAME_FORMAT				@"Use Custom Name Format"
#define KEY_WEBKIT_STYLE						@"Message Style"
#define KEY_WEBKIT_ALLOW_BACKGROUND_COLORING 	@"Allow Background Coloring"
#define	KEY_WEBKIT_TIME_STAMP_FORMAT			@"Time Stamp"
#define KEY_WEBKIT_MIN_FONT_SIZE				@"Min Font Size"

#define NEW_CONTENT_RETRY_DELAY					0.01
#define MESSAGE_STYLES_SUBFOLDER_OF_APP_SUPPORT @"Message Styles"

typedef enum {
	Fill = 0,
	Tile,
	NoStretch,
	Center
} AIImageBackgroundStyle;

@protocol AIMessageViewPlugin, AIMessageViewController;

@interface AIWebKitMessageViewPlugin : AIPlugin <AIMessageViewPlugin> {
	ESWebKitMessageViewPreferences  *preferences;
	NSMutableDictionary				*styleDictionary;
}

- (id <AIMessageViewController>)messageViewControllerForChat:(AIChat *)inChat;
- (NSDictionary *)availableMessageStyles;
- (NSBundle *)messageStyleBundleWithName:(NSString *)name;
- (NSString *)styleSpecificKey:(NSString *)key forStyle:(NSString *)style;

@end
