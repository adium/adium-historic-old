//
//  JSCEventBezelPlugin.m
//  Adium XCode
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//

#import "JSCEventBezelPlugin.h"
#import "JSCEventBezelPreferences.h"
#import "AIContactStatusEventsPlugin.h"


@interface JSCEventBezelPlugin (PRIVATE)
- (void)eventNotification:(NSNotification *)notification;
@end

@implementation JSCEventBezelPlugin

- (void)installPlugin
{
    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:EVENT_BEZEL_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_EVENT_BEZEL];

    //Our preference view
    preferences = [[JSCEventBezelPreferences preferencePaneWithOwner:owner] retain];
    
    ebc = [JSCEventBezelController eventBezelControllerForOwner:self];
    
    [[owner notificationCenter] addObserver:self
                                        selector:@selector(eventNotification:)
                                            name:CONTACT_STATUS_ONLINE_YES
                                          object:nil];
    [[owner notificationCenter] addObserver:self
                                        selector:@selector(eventNotification:)
                                            name:CONTACT_STATUS_ONLINE_NO
                                          object:nil];
    [[owner notificationCenter] addObserver:self
                                        selector:@selector(eventNotification:)
                                            name:CONTACT_STATUS_AWAY_YES
                                          object:nil];
    [[owner notificationCenter] addObserver:self
                                        selector:@selector(eventNotification:)
                                            name:CONTACT_STATUS_AWAY_NO
                                          object:nil];
    [[owner notificationCenter] addObserver:self
                                        selector:@selector(eventNotification:)
                                            name:CONTACT_STATUS_IDLE_YES
                                          object:nil];
    [[owner notificationCenter] addObserver:self
                                        selector:@selector(eventNotification:)
                                            name:CONTACT_STATUS_IDLE_NO
                                          object:nil];
}

- (void)uninstallPlugin
{
}

- (void)dealloc
{
    [ebc release];
    [preferences release];
    [super dealloc];
}

- (void)eventNotification:(NSNotification *)notification
{
    AIListContact   *contact = [notification object];
    NSEnumerator    *accountEnumerator;
    AIAccount       *account;
    NSDictionary    *preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_EVENT_BEZEL];
    
    if ([[preferenceDict objectForKey:KEY_SHOW_EVENT_BEZEL] boolValue]) {
        accountEnumerator = [[[owner accountController] accountArray] objectEnumerator];
        while ((account = [accountEnumerator nextObject])) {
            AIHandle    *contactHandle;
            if (contactHandle = [contact handleForAccount: account]) {
                [ebc showBezelWithContact: contact forEvent: [notification name] withMessage: nil];
            }
        }
    }
}

@end
