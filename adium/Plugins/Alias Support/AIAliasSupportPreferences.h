//
//  AIAliasSupportPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on Mon Aug 18 2003.
//

@interface AIAliasSupportPreferences : AIObject {
    IBOutlet	NSView			*view_prefView;
    IBOutlet	NSPopUpButton		*format_menu;	
}

+ (AIAliasSupportPreferences *)displayFormatPreferences;

@end
