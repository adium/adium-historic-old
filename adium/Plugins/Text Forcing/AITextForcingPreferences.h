//
//  AITextForcingPreferences.h
//  Adium
//
//  Created by Adam Iser on Tue Jan 21 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium;

@interface AITextForcingPreferences : NSObject {
    AIAdium			*owner;

    NSDictionary		*preferenceDict;

    IBOutlet	NSView			*view_prefView;

    IBOutlet	NSButton		*checkBox_forceFont;
    IBOutlet	NSTextField		*textField_desiredFont;
    IBOutlet	NSButton		*button_setFont;

    IBOutlet	NSButton		*checkBox_forceTextColor;
    IBOutlet	NSColorWell		*colorWell_textColor;

    IBOutlet	NSButton		*checkBox_forceBackgroundColor;
    IBOutlet	NSColorWell		*colorWell_backgroundColor;
    

}

+ (AITextForcingPreferences *)textForcingPreferencesWithOwner:(id)inOwner;
- (IBAction)changePreference:(id)sender;

@end
