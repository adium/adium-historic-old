//
//  IdleTimePreferences.h
//  Adium
//
//  Created by Adam Iser on Tue Jan 07 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium;

@interface IdleTimePreferences : NSObject {
    AIAdium			*owner;
    
    IBOutlet	NSView			*view_prefView;

    IBOutlet	NSButton		*checkBox_enableIdle;
    IBOutlet	NSTextField		*textField_idleMinutes;

    NSDictionary		*preferenceDict;
}

+ (IdleTimePreferences *)idleTimePreferencesWithOwner:(id)inOwner;
- (IBAction)changePreference:(id)sender;

@end
