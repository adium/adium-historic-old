//
//  AIDockBehaviorPreferences.h
//  Adium
//
//  Created by Adam Atlas on Wed Jan 29 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium;

@interface AIDockBehaviorPreferences : NSObject {
    AIAdium			*owner;

    IBOutlet	NSView		*view_prefView;
    IBOutlet	NSButton	*checkBox_enableBouncing;
    IBOutlet	NSMatrix	*matrix_bounceCount;
    IBOutlet	NSButtonCell	*radioButton_bounceForever;
    IBOutlet	NSButtonCell	*radioButton_bounceNTimes;
    IBOutlet	NSTextField	*textField_thisManyTimes;
    IBOutlet	NSMatrix	*matrix_bounceDelay;
    IBOutlet	NSButtonCell	*radioButton_bounceConstantly;
    IBOutlet	NSButtonCell	*radioButton_bounceEveryNSeconds;
    IBOutlet	NSTextField	*textField_thisManySeconds;

    NSDictionary		*preferenceDict;
}

+ (id)dockBehaviorPreferencesWithOwner:(id)inOwner;

- (IBAction)changePreference:(id)sender;

@end
