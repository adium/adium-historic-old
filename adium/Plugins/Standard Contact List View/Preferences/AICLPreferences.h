//
//  AICLPreferences.h
//  Adium
//
//  Created by Vinay Venkatesh on Wed Dec 18 2002.
//  Copyright (c) 2002 Vinay Venkatesh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium;

@interface AICLPreferences : NSObject {
    AIAdium		*owner;
    
    IBOutlet	NSView			*view_prefView;

    IBOutlet	NSButton		*button_setFont;
    IBOutlet	NSTextField		*textField_fontName;
    IBOutlet	NSButton		*checkBox_alternatingGrid;
    IBOutlet	NSColorWell		*colorWell_background;
    IBOutlet	NSColorWell		*colorWell_grid;
    IBOutlet	NSSlider		*slider_opacity;
    IBOutlet	NSTextField		*textField_opacityPercent;

    NSDictionary		*preferenceDict;
}

+ (AICLPreferences *)contactListPreferencesWithOwner:(id)inOwner;
- (IBAction)changePreference:(id)sender;

@end
