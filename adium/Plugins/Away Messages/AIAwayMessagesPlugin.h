//
//  AIAwayMessagesPlugin.h
//  Adium
//
//  Created by Adam Iser on Sun Jan 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@class AIAwayMessagePreferences;

@interface AIAwayMessagesPlugin : AIPlugin/*<AIPreferenceViewControllerDelegate>*/ {

    AIAwayMessagePreferences	*preferences;

}

@end
