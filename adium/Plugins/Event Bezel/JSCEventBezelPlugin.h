//
//  JSCEventBezelPlugin.h
//  Adium
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//

#import "JSCEventBezelController.h"

#define KEY_EVENT_BEZEL_NOTIFICATION    @"Notification"

#define EVENT_BEZEL_DEFAULT_PREFS           @"EventBezelPrefs"
#define PREF_GROUP_EVENT_BEZEL              @"Event Bezel"
#define KEY_SHOW_EVENT_BEZEL                @"Show Event Bezel"
#define KEY_EVENT_BEZEL_BUDDY_NAME_FORMAT   @"Buddy Name Format"
#define KEY_EVENT_BEZEL_ONLINE              @"Display if Online"
#define KEY_EVENT_BEZEL_OFFLINE             @"Display if Offline"
#define KEY_EVENT_BEZEL_AVAILABLE           @"Display if Available"
#define KEY_EVENT_BEZEL_AWAY                @"Display if Away"
#define KEY_EVENT_BEZEL_NO_IDLE             @"Display if no Longer Idle"
#define KEY_EVENT_BEZEL_IDLE                @"Display if Idle"
#define KEY_EVENT_BEZEL_FIRST_MESSAGE       @"Display if First Message"
#define KEY_EVENT_BEZEL_DURATION            @"Duration"
#define CONTACT_DISABLE_BEZEL               @"Disable Bezel For Contact"
#define KEY_EVENT_BEZEL_SHOW_HIDDEN         @"Show Hidden"
#define KEY_EVENT_BEZEL_SHOW_AWAY           @"Show While Away"
#define KEY_EVENT_BEZEL_INCLUDE_TEXT        @"Include Text"

#define BEZEL_CONTACT_ALERT_IDENTIFIER            @"Bezel"

@class JSCEventBezelPreferences;

@interface JSCEventBezelPlugin : AIPlugin <AIPreferenceViewControllerDelegate, AIActionHandler> {
    JSCEventBezelController     *ebc;
    JSCEventBezelPreferences    *preferences;
    
    NSMutableArray              *eventArray;
    BOOL                        showEventBezel;
    int                         prefsPosition;
    
    IBOutlet    NSView          *view_contactBezelInfoView;
    IBOutlet    NSButton        *checkBox_disableBezel;
    AIPreferenceViewController	*contactView;
    AIListObject                *activeListObject;
}

@end
