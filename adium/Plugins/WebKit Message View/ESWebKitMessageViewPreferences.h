//
//  ESWebKitMessageViewPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Apr 18 2004.

#import <WebKit/WebKit.h>
#import "ESWebView.h"

typedef enum {
	DefaultBackground = 0,
	CustomBackground,
	NoBackground
} BackgroundOptions;

@interface ESWebKitMessageViewPreferences : AIPreferencePane {
	IBOutlet	ESWebView		*preview;
	BOOL						webViewIsReady;
		
	IBOutlet	NSPopUpButton   *popUp_styles;
	
	IBOutlet	NSPopUpButton   *popUp_font;
	IBOutlet	NSPopUpButton   *popUp_fontSize;
	IBOutlet	NSPopUpButton   *popUp_minimumFontSize;
	
    IBOutlet    NSPopUpButton   *popUp_timeStamps;
	IBOutlet    NSButton        *checkBox_showUserIcons;
	IBOutlet	NSPopUpButton   *popUp_customBackground;
	IBOutlet	NSColorWell		*colorWell_customBackgroundColor;
	IBOutlet	NSButton		*button_restoreDefaultBackgroundColor;
	
	NSMutableDictionary			*previewListObjectsDict;
	
	AIContentObject				*previousContent;
	NSMutableArray				*newContent;
	NSTimer						*newContentTimer;
	
	NSString					*stylePath;
}

- (IBAction)changePreference:(id)sender;

@end
