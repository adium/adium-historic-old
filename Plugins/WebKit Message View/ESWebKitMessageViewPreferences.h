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

#import <Adium/AIPreferencePane.h>
#import <WebKit/WebKit.h>
#import "ESWebView.h"

@class JVFontPreviewField, AIContentObject, AIAutoScrollView, AIWebkitMessageViewController;

@interface ESWebKitMessageViewPreferences : AIPreferencePane {
	IBOutlet	JVFontPreviewField  *fontPreviewField_currentFont;
	IBOutlet	NSPopUpButton   	*popUp_styles;
	IBOutlet	NSPopUpButton   	*popUp_variants;
	IBOutlet	NSPopUpButton   	*popUp_backgroundImageType;
	IBOutlet	NSColorWell			*colorWell_customBackgroundColor;
	IBOutlet	NSImageView			*imageView_backgroundImage;
	IBOutlet    NSButton        	*checkBox_showUserIcons;
	IBOutlet    NSButton        	*checkBox_showHeader;
	IBOutlet	NSButton			*checkBox_showMessageColors;
	IBOutlet	NSButton			*checkBox_showMessageFonts;
	IBOutlet	NSButton			*checkBox_useCustomBackground;
	
	//Message preview
	IBOutlet	NSView				*view_previewLocation;
	NSMutableDictionary				*previewListObjectsDict;
	AIWebkitMessageViewController	*previewController;
	ESWebView						*preview;
	
	BOOL							viewIsOpen;
}

- (void)messageStyleXtrasDidChange;
- (IBAction)resetDisplayFontToDefault:(id)sender;

@end
