//
//  AISendingKeyPreferencesPlugin.h
//  Adium
//
//  Created by Adam Iser on Sat Mar 01 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@class AISendingKeyPreferences;

@interface AISendingKeyPreferencesPlugin : AIPlugin {
    AISendingKeyPreferences	*preferences;
}

@end
