//
//  AITextProfilePreferences.h
//  Adium
//
//  Created by Adam Iser on Fri Jan 10 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium;

@interface AITextProfilePreferences : NSObject {
    AIAdium			*owner;

    IBOutlet	NSView			*view_prefView;
    IBOutlet	NSTextView		*textView_textProfile;
    
}
+ (AITextProfilePreferences *)textProfilePreferencesWithOwner:(id)inOwner;

@end
