//
//  AITypingNotificationPlugin.h
//  Adium
//
//  Created by Adam Iser on Sun Jun 08 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@protocol AITextEntryFilter;

@interface AITypingNotificationPlugin : AIPlugin <AITextEntryFilter> {
    NSMutableDictionary		*typingDict;
}

@end
