//
//  AIStatusOverlayPreferences.h
//  Adium
//
//  Created by Adam Iser on Mon Jun 23 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AIStatusOverlayPreferences : NSObject {
    AIAdium			*owner;
    IBOutlet	NSView		*view_prefView;

    IBOutlet	NSButton	*checkBox_showStatusOverlays;
    IBOutlet	NSButton	*checkBox_showContentOverlays;
    IBOutlet	NSButton	*radioButton_topOfIcon;
    IBOutlet	NSButton	*radioButton_bottomOfIcon;
}

+ (id)statusOverlayPreferencesWithOwner:(id)inOwner;
- (IBAction)changePreference:(id)sender;

@end