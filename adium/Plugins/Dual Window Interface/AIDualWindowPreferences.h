//
//  AIDualWindowPreferences.h
//  Adium
//
//  Created by Adam Iser on Sat Jul 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium;

@interface AIDualWindowPreferences : NSObject {
    AIAdium			*owner;

    IBOutlet	NSView		*view_resizing;
    
    IBOutlet	NSButton	*checkBox_autoResize;
    IBOutlet	NSButton	*checkBox_horizontalResize;
}

+ (AIDualWindowPreferences *)dualWindowInterfacePreferencesWithOwner:(id)inOwner;
- (IBAction)changePreference:(id)sender;

@end
