//
//  AIAwayMessagePreferences.h
//  Adium
//
//  Created by Adam Iser on Sun Jan 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium;


@interface AIAwayMessagePreferences : NSObject {
    AIAdium			*owner;

    IBOutlet	NSView			*view_prefView;

}

+ (AIAwayMessagePreferences *)awayMessagePreferencesWithOwner:(id)inOwner;

@end
