//
//  ESWebKitMessageViewPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Apr 18 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

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
