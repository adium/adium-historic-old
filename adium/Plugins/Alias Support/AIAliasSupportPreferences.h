//
//  AIAliasSupportPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on Mon Aug 18 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

@interface AIAliasSupportPreferences : NSObject {
    IBOutlet	NSView			*view_prefView;
    IBOutlet	NSPopUpButton		*format_menu;	
    AIAdium				*owner;

}

+ (AIAliasSupportPreferences *)displayFormatPreferencesWithOwner:(id)inOwner;

@end
