//
//  AIDefaultFormattingPlugin.h
//  Adium
//
//  Created by Adam Iser on Thu May 22 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

#define PREF_GROUP_FORMATTING			@"Formatting"

#define KEY_FORMATTING_FONT			@"Default Font"
#define KEY_FORMATTING_TEXT_COLOR		@"Default Text Color"
#define KEY_FORMATTING_BACKGROUND_COLOR		@"Default Background Color"
#define KEY_FORMATTING_SUBBACKGROUND_COLOR	@"Default SubBackground Color"

@class AIDefaultFormattingPreferences;
@protocol AITextEntryFilter;

@interface AIDefaultFormattingPlugin : AIPlugin <AITextEntryFilter> {
    AIDefaultFormattingPreferences	*preferences;

}

@end
