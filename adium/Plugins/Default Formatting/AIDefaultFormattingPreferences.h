//
//  AIDefaultFormattingPreferences.h
//  Adium
//
//  Created by Adam Iser on Fri May 23 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium;

@interface AIDefaultFormattingPreferences : NSObject {
    AIAdium			*owner;

    NSDictionary		*preferenceDict;

    IBOutlet	NSView			*view_prefView;
    IBOutlet	NSTextField		*textField_desiredFont;
    IBOutlet	NSButton		*button_setFont;
    IBOutlet	NSColorWell		*colorWell_textColor;
    IBOutlet	NSColorWell		*colorWell_backgroundColor;
}

+ (AIDefaultFormattingPreferences *)defaultFormattingPreferencesWithOwner:(id)inOwner;
- (IBAction)changePreference:(id)sender;

@end
