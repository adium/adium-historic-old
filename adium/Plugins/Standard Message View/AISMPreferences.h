//
//  AISMPreferences.h
//  Adium
//
//  Created by Adam Iser on Wed Jan 22 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium;

@interface AISMPreferences : NSObject {
    AIAdium			*owner;

    //Prefixes
    IBOutlet	NSView		*view_prefixes;
    IBOutlet	NSButton	*button_setPrefixFont;
    IBOutlet	NSTextField	*textField_prefixFontName;
    IBOutlet	NSButton	*checkBox_hideDuplicatePrefixes;
    IBOutlet	NSPopUpButton	*popUp_incomingPrefix;
    IBOutlet	NSPopUpButton	*popUp_outgoingPrefix;
    
    //TimeStamps
    IBOutlet	NSView		*view_timeStamps;
    IBOutlet	NSButton	*checkBox_showTimeStamps;
    IBOutlet	NSButton	*checkBox_hideDuplicateTimeStamps;
    IBOutlet	NSButton	*checkBox_showSeconds;
    
    //Gridding
    IBOutlet	NSView		*view_gridding;
    IBOutlet	NSButton	*checkBox_displayGridlines;
    IBOutlet	NSSlider	*slider_gridDarkness;
    IBOutlet	NSButton	*checkBox_senderGradient;
    IBOutlet	NSSlider	*slider_gradientDarkness;

    NSDictionary		*prefixColors;

    NSDictionary		*preferenceDict;
}

+ (AISMPreferences *)messageViewPreferencesWithOwner:(id)inOwner;
- (IBAction)changePreference:(id)sender;

@end
