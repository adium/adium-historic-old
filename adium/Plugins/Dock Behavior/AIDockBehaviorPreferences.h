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

    IBOutlet	NSTableView	*tableView_events;
    IBOutlet	NSButton	*button_delete;
    IBOutlet	NSPopUpButton	*popUp_addEvent;
    
    IBOutlet	NSView		*view_prefView;

    NSMutableArray		*dockEventArray;
    /*    IBOutlet 	NSTextField	*bounceField;
    IBOutlet	NSTextField	*delayField;
    IBOutlet	NSButton	*enableBouncingCheckBox;
    IBOutlet	NSButton	*enableAnimationCheckBox;
    IBOutlet	NSMatrix	*bounceMatrix;
    
    NSDictionary		*preferenceDict;*/
}

+ (id)dockBehaviorPreferencesWithOwner:(id)inOwner;

- (IBAction)changePreference:(id)sender;

- (IBAction)selectBehaviorSet:(id)sender;
- (IBAction)deleteEvent:(id)sender;

@end
