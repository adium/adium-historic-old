//
//  AITextProfilesPlugin.h
//  Adium
//
//  Created by Adam Iser on Tue Jan 07 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@class AITextProfilePreferences;

@interface AITextProfilesPlugin : AIPlugin {
    AITextProfilePreferences		*preferences;
}

@end
