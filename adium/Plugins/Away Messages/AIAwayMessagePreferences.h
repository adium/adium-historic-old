//
//  AIAwayMessagePreferences.h
//  Adium
//
//  Created by Adam Iser on Sun Jan 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium, AIFlexibleTableView, AIFlexibleTableColumn;

@protocol AIFlexibleTableViewDelegate;

@interface AIAwayMessagePreferences : NSObject <AIFlexibleTableViewDelegate> {
    AIAdium				*owner;

    IBOutlet	NSView			*view_prefView;
    IBOutlet	NSView			*view_awayWindowPrefView;
    IBOutlet	AIFlexibleTableView	*tableView_aways;
    IBOutlet	NSButton		*button_delete;
    IBOutlet	NSButton		*checkBox_showAway;
    IBOutlet	NSButton		*checkBox_floatAway;
    IBOutlet 	NSButton		*checkBox_hideInBackground;

    AIFlexibleTableColumn		*imageColumn;
    AIFlexibleTableColumn		*messageColumn;

    NSMutableArray			*awayMessageArray;

    NSImage				*awayImage;

}

+ (AIAwayMessagePreferences *)awayMessagePreferencesWithOwner:(id)inOwner;
- (IBAction)deleteAwayMessage:(id)sender;
- (IBAction)newAwayMessage:(id)sender;
- (IBAction)toggleShowAway:(id)sender;
- (IBAction)toggleHideInBackground:(id)sender;

@end
