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
    IBOutlet	AIFlexibleTableView	*tableView_aways;

    AIFlexibleTableColumn		*imageColumn;
    AIFlexibleTableColumn		*messageColumn;

    NSMutableArray			*awayMessageArray;

}

+ (AIAwayMessagePreferences *)awayMessagePreferencesWithOwner:(id)inOwner;
- (IBAction)deleteAwayMessage:(id)sender;
- (IBAction)newAwayMessage:(id)sender;

@end
