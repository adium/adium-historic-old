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

@class JVFontPreviewField, AIContentObject, AIAutoScrollView;
@protocol AIMessageViewController;

typedef enum {
	DefaultBackground = 0,
	CustomBackground,
	NoBackground
} BackgroundOptions;

@interface ESWebKitMessageViewPreferences : AIPreferencePane {
	IBOutlet	ESWebView		*preview;
	BOOL						webViewIsReady;
		
	IBOutlet	NSPopUpButton   *popUp_styles;
	IBOutlet	NSPopUpButton   *popUp_variants;
	
	IBOutlet	JVFontPreviewField  *fontPreviewField_currentFont;
	IBOutlet	NSPopUpButton   *popUp_minimumFontSize;
	
    IBOutlet    NSPopUpButton   *popUp_timeStamps;
	IBOutlet    NSButton        *checkBox_showUserIcons;
	IBOutlet	NSPopUpButton   *popUp_customBackground;
	IBOutlet	NSColorWell		*colorWell_customBackgroundColor;
	IBOutlet	NSButton		*button_restoreDefaultBackgroundColor;
	IBOutlet	NSPopUpButton   *popUp_backgroundImageType;
	
	NSMutableDictionary			*previewListObjectsDict;
	
	AIContentObject				*previousContent;
	NSMutableArray				*newContent;
	NSTimer						*newContentTimer;
	
	NSString					*stylePath;
	BOOL						allowColors;
	
	AIChat						*previewChat;
	
	id<AIMessageViewController>		previewController;
	IBOutlet	AIAutoScrollView	*scrollView_previewLocation;
    IBOutlet	NSView				*view_previewLocation;
	
	BOOL						viewIsOpen;
}

- (IBAction)changePreference:(id)sender;
- (void)messageStyleXtrasDidChange;

@end
