//
//  AIStatusOverlayPreferences.h
//  Adium
//
//  Created by Adam Iser on Mon Jun 23 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@interface AIStatusOverlayPreferences : AIPreferencePane {
    IBOutlet	NSButton	*checkBox_showStatusOverlays;
    IBOutlet	NSButton	*checkBox_showContentOverlays;
}

@end