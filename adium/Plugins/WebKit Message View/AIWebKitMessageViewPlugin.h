/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#define	KEY_WEBKIT_TIME_STAMP_FORMAT		@"Time Stamp"
#define KEY_WEBKIT_SHOW_USER_ICONS			@"Show User Icons"
#define KEY_WEBKIT_STYLE					@"Message Style"

#define KEY_WEBKIT_DEFAULT_FONT_FAMILY		@"DefaultFontFamily"
#define KEY_WEBKIT_DEFAULT_FONT_SIZE		@"DefaultFontSize"

#define NEW_CONTENT_RETRY_DELAY				0.01

#import "ESWebKitMessageViewPreferences.h"


@interface AIWebKitMessageViewPlugin : AIPlugin <AIMessageViewPlugin> {
	ESWebKitMessageViewPreferences  *preferences;
	NSDateFormatter					*timeStampFormatter;
	BOOL							showUserIcons;
	
	NSMutableDictionary				*styleDictionary;
}

- (NSDictionary *)availableStyleDictionary;
- (NSBundle *)messageStyleBundleWithName:(NSString *)name;
- (NSString *)keyForDesiredVariantOfStyle:(NSString *)desiredStyle;
- (void)processContent:(AIContentObject *)content withPreviousContent:(AIContentObject *)previousContent forWebView:(WebView *)webView fromStylePath:(NSString *)stylePath;
- (void)loadPreferencesForWebView:(ESWebView *)webView withStyleNamed:(NSString *)styleName;
- (NSMutableString *)fillKeywords:(NSMutableString *)inString forChat:(AIChat *)chat;

@end
