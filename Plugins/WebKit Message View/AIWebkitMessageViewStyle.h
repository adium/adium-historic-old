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
#import <Adium/AIObject.h>

@class AIChat, AIContentObject;

/*!
 *	@brief Key used to retrieve the user's icon
 */
#define KEY_WEBKIT_USER_ICON 				@"WebKitUserIconPath"

/*!
 *	@brief Key used to retrieve the default font family
 */
#define KEY_WEBKIT_DEFAULT_FONT_FAMILY		@"DefaultFontFamily"

/*!
 *	@brief Key used to retrieve the default font size
 */
#define KEY_WEBKIT_DEFAULT_FONT_SIZE		@"DefaultFontSize"

/*!
 *	@brief Key used to retrieve the mask for the user's icon
 */
#define KEY_WEBKIT_USER_ICON_MASK			@"ImageMask"

/*!
 *	@brief Different ways of formatting display names
 */
typedef enum {
	Display_Name = 1,
	Display_Name_Screen_Name = 2,
	Screen_Name_Display_Name = 3,
	Screen_Name = 4
} NameFormat;

/*!
 *	@brief Different ways of formatting display names
 */
typedef enum {
	AIDefaultName = 0,
	AIDisplayName = 1,
	AIDisplayName_ScreenName = 2,
	AIScreenName_DisplayName = 3,
	AIScreenName = 4
} AINameFormat;

/*!
 *	@brief Different ways of displaying background images
 */
typedef enum {
	BackgroundNormal = 0,
	BackgroundCenter,
	BackgroundTile,
	BackgroundTileCenter,
	BackgroundScale
} AIWebkitBackgroundType;

@class ESFileTransfer;

/*!
 *	@class AIWebkitMessageViewStyle AIWebkitMessageViewStyle.h
 *	@brief Handles all interaction between the webkit message view controller and the message style, including creating the actual html strings to be appended
 *	@see AIWebKitMessageViewController
 */
@interface AIWebkitMessageViewStyle : AIObject {
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
	NSString			*fileTransferHTML;

	//Style settings
	BOOL				allowsCustomBackground;
	BOOL				transparentDefaultBackground;
	BOOL				allowsUserIcons;
	BOOL				usingCustomTemplateHTML;

	//Behavior
	NSDateFormatter		*timeStampFormatter;
	AINameFormat		nameFormat;
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
	
	//icon path caches
	NSMutableDictionary *statusIconPathCache;
}

/*!
 *	@brief Create a message view style instance for the passed style bundle
 */
+ (id)messageViewStyleFromBundle:(NSBundle *)inBundle;

/*!
 *	@brief Create a message view style instance by loading the bundle at the passed path
 */
+ (id)messageViewStyleFromPath:(NSString *)path;

/*!
 *	@brief The NSBundle for this style
 */
- (NSBundle *)bundle;

/*!
 *	Returns YES if this style is considered legacy
 *
 *	Legacy/outdated styles may perform sub-optimally because they lack beneficial changes made in modern styles.
 */
- (BOOL)isLegacy;

#pragma mark Templates
/*!
 *	@brief Returns the base template for this style
 *
 *	The base template is basically the empty view, and serves as the starting point of all content insertion.
 */
- (NSString *)baseTemplateWithVariant:(NSString *)variant chat:(AIChat *)chat;

/*!
 *	@brief Returns the template for inserting content
 * 
 *	Templates may be different for different content types and for content objects similar to the one preceding them.
 */
- (NSString *)templateForContent:(AIContentObject *)content similar:(BOOL)contentIsSimilar;

/*!
 *	@brief Returns the BOM script for appending content
 */
- (NSString *)scriptForAppendingContent:(AIContentObject *)content similar:(BOOL)contentIsSimilar willAddMoreContentObjects:(BOOL)willAddMoreContentObjects replaceLastContent:(BOOL)replaceLastContent;

/*!
 *	@brief Returns the BOM script for changing the view's variant
 */
- (NSString *)scriptForChangingVariant:(NSString *)variant;

/*!
 *	@brief Returns the BOM script for scrolling after adding multiple content objects
 *
 * Only applicable for styles which use the internal template
 */
- (NSString *)scriptForScrollingAfterAddingMultipleContentObjects;

#pragma mark Settings
/*!
 *	@brief Style supports custom backgrounds
 */
- (BOOL)allowsCustomBackground;

/*!
 *	@brief Style has a transparent background
 */
- (BOOL)isBackgroundTransparent;


/*!
 *	@brief Style's default font family
 */
- (NSString *)defaultFontFamily;


/*!
 *	@brief Style's default font size
 */
- (NSNumber *)defaultFontSize;

/*!
 *	@brief Style has a header
 */
- (BOOL)hasHeader;

/*!
 *	@brief Style's user icon mask
 */
- (NSImage *)userIconMask;

/*!
 *	@brief Style supports user icons
 */
- (BOOL)allowsUserIcons;

//Behavior
/*!
 *	@brief Set format of dates/time stamps
 */
- (void)setDateFormat:(NSString *)format;

/*!
 *	@brief Set visibility of user icons
 */
- (void)setShowUserIcons:(BOOL)inValue;

/*!
 *	@brief Set visibility of header
 */
- (void)setShowHeader:(BOOL)inValue;

/*!
 *	@brief Toggle use of a custom name format
 */
- (void)setUseCustomNameFormat:(BOOL)inValue;

/*!
 *	@brief Set the custom name format being used
 */
- (void)setNameFormat:(AINameFormat)inValue;

/*!
 *	@brief Set visibility of message background colors
 */
- (void)setAllowTextBackgrounds:(BOOL)inValue;

/*!
 *	@brief Set the custom background image
 *	@param inPath the path to the backgroun image to use
 */
- (void)setCustomBackgroundPath:(NSString *)inPath;

/*!
 *	@brief Set the custom background image type (How it is displayed - stretched, tiled, centered, etc)
 */
- (void)setCustomBackgroundType:(AIWebkitBackgroundType)inType;

/*!
 *	@brief Set the custom background color
 */
- (void)setCustomBackgroundColor:(NSColor *)inColor;

/*!
 *	@brief Toggle visibility of received coloring
 */
- (void)setShowIncomingMessageColors:(BOOL)inValue;

/*!
 *	@brief Toggle visibility of received fonts
 */
- (void)setShowIncomingMessageFonts:(BOOL)inValue;

#pragma mark Variants
/*!
 *	@brief Returns an alphabetized array of available variant names for this style
 */
- (NSArray *)availableVariants;

/*!
 *	@brief Returns the file path to the css file defining a variant of this style
 */
- (NSString *)pathForVariant:(NSString *)variant;

/*!
 *	@brief Default variant for all style versions
 */
- (NSString *)defaultVariant;
+ (NSString *)defaultVariantForBundle:(NSBundle *)inBundle;

#pragma mark Keyword Substitution

/*!
 *	@brief Substitute content keywords
 *
 *	Substitute keywords in a template with the appropriate values for the passed content object
 *	We allow the message style to handle this since the behavior of keywords is dependent on the style and may change
 *	for future style versions
 */
- (NSMutableString *)fillKeywords:(NSMutableString *)inString forContent:(AIContentObject *)content similar:(BOOL)contentIsSimilar;

/*!
 *	@brief Substitute base keywords
 *
 * We allow the message style to handle this since the behavior of keywords is dependent on the style and may change
 * for future style versions
 */
- (NSMutableString *)fillKeywordsForBaseTemplate:(NSMutableString *)inString chat:(AIChat *)chat;
@end
