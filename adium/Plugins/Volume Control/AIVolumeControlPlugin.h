//
//  AIVolumeControlPlugin.h
//  Adium
//
//  Created by Adam Iser on Wed Apr 16 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@class AIVolumeControlPreferences;

@interface AIVolumeControlPlugin : AIPlugin {

    AIVolumeControlPreferences	*preferences;

}

@end
