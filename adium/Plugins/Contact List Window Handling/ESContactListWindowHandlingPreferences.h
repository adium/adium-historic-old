//
//  ESContactListWindowHandlingPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on Mon Sep 15 2003.
//

#import <Cocoa/Cocoa.h>

@class AIAdium;

@interface ESContactListWindowHandlingPreferences : NSObject {
    AIAdium			*owner;

    IBOutlet	NSView		*view_prefView;

    IBOutlet	NSButton	*checkBox_alwaysOnTop;
    IBOutlet	NSButton	*checkBox_hide;
}

+ (ESContactListWindowHandlingPreferences *)contactListWindowHandlingPreferencesWithOwner:(id)inOwner;
- (IBAction)changePreference:(id)sender;

@end
