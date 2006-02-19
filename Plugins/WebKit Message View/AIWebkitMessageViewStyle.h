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

#import <Cocoa/Cocoa.h>

@class AIChat, AIContentObject;

#define KEY_WEBKIT_USER_ICON 				@"WebKitUserIconPath"
#define KEY_WEBKIT_DEFAULT_FONT_FAMILY		@"DefaultFontFamily"
#define KEY_WEBKIT_DEFAULT_FONT_SIZE		@"DefaultFontSize"
#define KEY_WEBKIT_USER_ICON_MASK			@"ImageMask"

typedef enum {
	Display_Name = 1,
	Display_Name_Screen_Name = 2,
	Screen_Name_Display_Name = 3,
	Screen_Name = 4
} NameFormat;

typedef enum {
	BackgroundNormal = 0,
	BackgroundCenter,
	BackgroundTile
} AIWebkitBackgroundType;

@interface AIWebkitMessageViewStyle : NSObject {
	int					styleVersion;
	NSBundle			*styleBundle;
	NSString			*stylePath;
	
	//Templates
	NSString			*headerHTML;
	NSString			*footerHTML;
	NSString			*baseHTML;
	NSString			*contentInHTML;
	NSString			*nextContentInHTML;
	NSString			*contextInHTML;
	NSString			*nextContextInHTML;
	NSString			*contentOutHTML;
	NSString			*nextContentOutHTML;
	NSString			*contextOutHTML;
	NSString			*nextContextOutHTML;
	NSString			*statusHTML;

	//Style settings
	BOOL				allowsCustomBackground;
	BOOL				transparentDefaultBackground;
	BOOL				allowsUserIcons;
	BOOL				usingCustomBaseHTML;

	//Behavior
	NSDateFormatter		*timeStampFormatter;
	NameFormat			nameFormat;
	BOOL				useCustomNameFormat;
	BOOL				showUserIcons;
	BOOL				showHeader;
	BOOL				combineConsecutive;
	BOOL				allowTextBackgrounds;
	BOOL				showIncomingFonts;
	BOOL				showIncomingColors;
	int					customBackgroundType;
	NSString			*customBackgroundPath;
	NSColor				*customBackgroundColor;
	NSImage				*userIconMask;
}

+ (id)messageViewStyleFromBundle:(NSBundle *)inBundle;
- (BOOL)isLegacy;

//Templates
- (NSString *)baseTemplateWithVariant:(NSString *)variant chat:(AIChat *)chat;
- (NSString *)templateForContent:(AIContentObject *)content similar:(BOOL)contentIsSimilar;
- (NSString *)scriptForAppendingContent:(AIContentObject *)content similar:(BOOL)contentIsSimilar willAddMoreContentObjects:(BOOL)willAddMoreContentObjects;
- (NSString *)scriptForChangingVariant:(NSString *)variant;
- (NSString *)scriptForScrollingAfterAddingMultipleContentObjects;

//Settings
- (BOOL)allowsCustomBackground;
- (BOOL)isBackgroundTransparent;
- (NSString *)defaultFontFamily;
- (NSNumber *)defaultFontSize;
- (BOOL)hasHeader;
- (NSImage *)userIconMask;
- (BOOL)allowsUserIcons;

//Behavior
- (void)setDateFormat:(NSString *)format;
- (void)setShowUserIcons:(BOOL)inValue;
- (void)setShowHeader:(BOOL)inValue;
- (void)setUseCustomNameFormat:(BOOL)inValue;
- (void)setNameFormat:(int)inValue;
- (void)setAllowTextBackgrounds:(BOOL)inValue;
- (void)setCustomBackgroundPath:(NSString *)inPath;
- (void)setCustomBackgroundType:(AIWebkitBackgroundType)inType;
- (void)setCustomBackgroundColor:(NSColor *)inColor;
- (void)setShowIncomingMessageColors:(BOOL)inValue;
- (void)setShowIncomingMessageFonts:(BOOL)inValue;

//Variants
- (NSArray *)availableVariants;
- (NSString *)pathForVariant:(NSString *)variant;
- (NSString *)defaultVariant;
+ (NSString *)defaultVariantForBundle:(NSBundle *)inBundle;

//Keyword substitution
- (void) replaceKeyword:(NSString *)word inString:(NSMutableString *)string withString:(NSString *)newWord;
- (NSMutableString *)fillKeywords:(NSMutableString *)inString forContent:(AIContentObject *)content;
- (NSMutableString *)fillKeywordsForBaseTemplate:(NSMutableString *)inString chat:(AIChat *)chat;

@end
