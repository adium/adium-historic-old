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
#define KEY_EVENT_BEZEL_ONLINE              @"Display if Online"
#define KEY_EVENT_BEZEL_OFFLINE             @"Display if Offline"
#define KEY_EVENT_BEZEL_AVAILABLE           @"Display if Available"
#define KEY_EVENT_BEZEL_AWAY                @"Display if Away"
#define KEY_EVENT_BEZEL_NO_IDLE             @"Display if no Longer Idle"
#define KEY_EVENT_BEZEL_IDLE                @"Display if Idle"
#define KEY_EVENT_BEZEL_FIRST_MESSAGE       @"Display if First Message"

@class JSCEventBezelPreferences;

@interface JSCEventBezelPlugin : AIPlugin {
    JSCEventBezelController     *ebc;
    JSCEventBezelPreferences    *preferences;
    
    NSMutableArray              *eventArray;
    BOOL                        showEventBezel;
    int                         buddyNameFormat;
    int                         eventBezelPosition;
}

- (NSString *)stringWithoutWhitespace:(NSString *)sourceString;

@end
