//
//  AIDockBehaviorPreferences.h
//  Adium
//
//  Created by Adam Atlas on Wed Jan 29 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium, AIAlternatingRowTableView;

@interface AIDockBehaviorPreferences : NSObject {
    AIAdium					*owner;

    IBOutlet	AIAlternatingRowTableView	*tableView_events;
    IBOutlet	NSButton			*button_delete;
    IBOutlet	NSPopUpButton			*popUp_addEvent;
    IBOutlet	NSPopUpButton			*popUp_behaviorSet;
    
    IBOutlet	NSView				*view_prefView;

    NSMutableArray				*behaviorArray;

    BOOL				usingCustomBehavior;
}

+ (id)dockBehaviorPreferencesWithOwner:(id)inOwner;


- (IBAction)selectBehaviorSet:(id)sender;
- (IBAction)deleteEvent:(id)sender;

@end
