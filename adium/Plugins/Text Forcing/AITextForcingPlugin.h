//
//  AITextForcingPlugin.h
//  Adium
//
//  Created by Adam Iser on Tue Jan 21 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>


#define PREF_GROUP_TEXT_FORCING			@"Text Forcing"

#define KEY_FORCE_FONT				@"Force Font"
#define KEY_FORCE_TEXT_COLOR			@"Force Text Color"
#define KEY_FORCE_BACKGROUND_COLOR		@"Force Background Color"

#define KEY_FORCE_DESIRED_FONT			@"Desired Font"
#define KEY_FORCE_DESIRED_TEXT_COLOR		@"Desired Text Color"
#define KEY_FORCE_DESIRED_BACKGROUND_COLOR	@"Desired Background Color"

@class AITextForcingPreferences;
@protocol AIContentFilter;

@interface AITextForcingPlugin : AIPlugin <AIContentFilter> {
    AITextForcingPreferences	*preferences;

    BOOL		forceFont;
    BOOL		forceText;
    BOOL		forceBackground;
    NSFont		*force_desiredFont;
    NSColor		*force_desiredTextColor;
    NSColor		*force_desiredBackgroundColor;
    
}

@end
