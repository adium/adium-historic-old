//
//  JSCEventBezelPlugin.h
//  Adium XCode
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//

#import "JSCEventBezelController.h"

#define KEY_EVENT_BEZEL_NOTIFICATION    @"Notification"

#define EVENT_BEZEL_DEFAULT_PREFS           @"EventBezelPrefs"
#define PREF_GROUP_EVENT_BEZEL              @"Event Bezel"
#define KEY_SHOW_EVENT_BEZEL                @"Show Event Bezel"
#define KEY_EVENT_BEZEL_POSITION            @"Event Bezel Position"
#define KEY_EVENT_BEZEL_BUDDY_NAME_FORMAT   @"Buddy Name Format"

@class JSCEventBezelPreferences;

@interface JSCEventBezelPlugin : AIPlugin {
    JSCEventBezelController *ebc;
    JSCEventBezelPreferences *preferences;
}

- (NSString *)stringWithoutWhitespace:(NSString *)sourceString;

@end
