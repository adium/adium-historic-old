//
//  AIDualWindowPreferences.h
//  Adium
//
//  Created by Adam Iser on Sat Jul 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@interface AIDualWindowAdvancedPrefs : AIPreferencePane {
    IBOutlet	NSButton	*checkBox_autoResize;
    IBOutlet	NSButton	*checkBox_horizontalResize;
}

@end
