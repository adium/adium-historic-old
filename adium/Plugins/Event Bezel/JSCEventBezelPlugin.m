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
#import "AIContactStatusColoringPlugin.h"
#import <AddressBook/AddressBook.h>

@interface JSCEventBezelPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (void)processBezelForNotification:(NSNotification *)notification;
@end

@implementation JSCEventBezelPlugin

- (void)installPlugin
{
    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:EVENT_BEZEL_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_EVENT_BEZEL];
    
    //Our preference view
    preferences = [[JSCEventBezelPreferences preferencePaneWithOwner:owner] retain];
    
    // Setup the controller
    ebc = [JSCEventBezelController eventBezelControllerForOwner:self];
    
    eventArray = [[NSMutableArray alloc] init];
    
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
    [[owner notificationCenter] addObserver:self
                                   selector:@selector(eventNotification:)
                                       name:Content_FirstContentRecieved
                                     object:nil];
    
    [[owner notificationCenter] addObserver:self
                                  selector:@selector(actionNotification:)
                                      name:@"Display Event Bezel"
                                    object:nil];
    
    //watch preference changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    //set up preferences initially
    [self preferencesChanged:nil];
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

//
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_EVENT_BEZEL] == 0){
        NSDictionary    *preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_EVENT_BEZEL];
        
        showEventBezel = [[preferenceDict objectForKey:KEY_SHOW_EVENT_BEZEL] boolValue];
        //prefsPosition = [[preferenceDict objectForKey:KEY_EVENT_BEZEL_POSITION] intValue];
        [ebc setBezelPosition: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_POSITION] intValue]];
        [ebc setImageBadges: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_IMAGE_BADGES] boolValue]];
        [ebc setUseBuddyIconLabel: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_COLOR_LABELS] boolValue]];
        [ebc setUseBuddyNameLabel: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_NAME_LABELS] boolValue]];
        [ebc setBezelDuration: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_DURATION] intValue]];
        
        [eventArray removeAllObjects];
        if ([[preferenceDict objectForKey:KEY_EVENT_BEZEL_FIRST_MESSAGE] boolValue])
            [eventArray addObject:Content_FirstContentRecieved];                
        if ([[preferenceDict objectForKey:KEY_EVENT_BEZEL_ONLINE] boolValue])
            [eventArray addObject:CONTACT_STATUS_ONLINE_YES];
        if ([[preferenceDict objectForKey:KEY_EVENT_BEZEL_OFFLINE] boolValue])
            [eventArray addObject:CONTACT_STATUS_ONLINE_NO];
        if ([[preferenceDict objectForKey:KEY_EVENT_BEZEL_AWAY] boolValue])
            [eventArray addObject:CONTACT_STATUS_AWAY_YES];
        if ([[preferenceDict objectForKey:KEY_EVENT_BEZEL_AVAILABLE] boolValue])
            [eventArray addObject:CONTACT_STATUS_AWAY_NO];
        if ([[preferenceDict objectForKey:KEY_EVENT_BEZEL_IDLE] boolValue])
            [eventArray addObject:CONTACT_STATUS_IDLE_YES];
        if ([[preferenceDict objectForKey:KEY_EVENT_BEZEL_NO_IDLE] boolValue])
            [eventArray addObject:CONTACT_STATUS_IDLE_NO];   
    }
}

- (void)actionNotification:(NSNotification *)notification
{
    if (!showEventBezel || (![eventArray containsObject:[notification object]])) {
        NSDictionary * info = [notification userInfo];
        
        //Retain to be on the safe side
        NSString * notificationName = [[notification object] retain];
        AIListContact * contact = [[info objectForKey:@"object"] retain];
        
        [self processBezelForNotification:[NSNotification notificationWithName:notificationName object:contact]];

        //Now release, having displayed the bezel
        [notificationName release]; [contact release];
    }
}

- (void)eventNotification:(NSNotification *)notification
{
    if (showEventBezel && [eventArray containsObject:[notification name]]) {
        [self processBezelForNotification:notification];
    }
}

- (void)processBezelForNotification:(NSNotification *)notification 
{
    AIListContact               *contact;
    BOOL                        isFirstMessage = NO;
    NSString                    *notificationName = [notification name];
    NSString                    *tempEvent = nil;
    AIMutableOwnerArray         *ownerArray =nil;
    NSImage                     *tempBuddyIcon = nil;
    NSString                    *statusMessage = nil;
    NSDictionary                *colorPreferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_STATUS_COLORING];
    
    if ([notificationName isEqualToString:Content_FirstContentRecieved]) {
        contact = [[[notification object] participatingListObjects] objectAtIndex:0];
        isFirstMessage = YES;
    } else {
        contact = [notification object];
    }
    
    ownerArray = [contact statusArrayForKey:@"BuddyImage"];
    if(ownerArray && [ownerArray count]) {
        tempBuddyIcon = [ownerArray objectAtIndex:0];
    }
    if (isFirstMessage) {
        AIContentMessage    *contentMessage = [[notification userInfo] objectForKey:@"Object"];
        statusMessage = [[contentMessage message] string];
    } else {
        // If it is a status change, show status message
        // Not working
        /*ownerArray = [contact statusArrayForKey: @"StatusMessage"];
        if (ownerArray && [ownerArray count]) {
            statusMessage = [ownerArray objectAtIndex: 0];
        }
        if (statusMessage) {
        } else {
        }*/
    }
    
    if ([notificationName isEqualToString: CONTACT_STATUS_ONLINE_YES]) {
        tempEvent = @"is now online";
        if ([ebc useBuddyIconLabel] || [ebc useBuddyNameLabel]) {
            [ebc setBuddyIconLabelColor: [[colorPreferenceDict objectForKey:KEY_LABEL_SIGNED_ON_COLOR] representedColor]];
            [ebc setBuddyNameLabelColor: [[colorPreferenceDict objectForKey:KEY_SIGNED_ON_COLOR] representedColor]];
        } else {
            [ebc setBuddyIconLabelColor: nil];
        }
    } else if ([notificationName isEqualToString: CONTACT_STATUS_ONLINE_NO]) {
        tempEvent = @"has gone offline";
        if ([ebc useBuddyIconLabel] || [ebc useBuddyNameLabel]) {
            [ebc setBuddyIconLabelColor: [[colorPreferenceDict objectForKey:KEY_LABEL_SIGNED_OFF_COLOR] representedColor]];
            [ebc setBuddyNameLabelColor: [[colorPreferenceDict objectForKey:KEY_SIGNED_ON_COLOR] representedColor]];
        } else {
            [ebc setBuddyIconLabelColor: nil];
        }
    } else if ([notificationName isEqualToString: CONTACT_STATUS_AWAY_YES]) {
        tempEvent = @"has gone away";
        if ([ebc useBuddyIconLabel] || [ebc useBuddyNameLabel]) {
            [ebc setBuddyIconLabelColor: [[colorPreferenceDict objectForKey:KEY_LABEL_AWAY_COLOR] representedColor]];
            [ebc setBuddyNameLabelColor: [[colorPreferenceDict objectForKey:KEY_AWAY_COLOR] representedColor]];
        } else {
            [ebc setBuddyIconLabelColor: nil];
        }
    } else if ([notificationName isEqualToString: CONTACT_STATUS_AWAY_NO]) {
        tempEvent = @"is available";
        if ([ebc useBuddyIconLabel] || [ebc useBuddyNameLabel]) {
            [ebc setBuddyIconLabelColor: [[colorPreferenceDict objectForKey:KEY_LABEL_ONLINE_COLOR] representedColor]];
            [ebc setBuddyNameLabelColor: [[colorPreferenceDict objectForKey:KEY_ONLINE_COLOR] representedColor]];
        } else {
            [ebc setBuddyIconLabelColor: nil];
        }
    } else if ([notificationName isEqualToString: CONTACT_STATUS_IDLE_YES]) {
        tempEvent = @"is idle";
        if ([ebc useBuddyIconLabel] || [ebc useBuddyNameLabel]) {
            [ebc setBuddyIconLabelColor: [[colorPreferenceDict objectForKey:KEY_LABEL_IDLE_COLOR] representedColor]];
            [ebc setBuddyNameLabelColor: [[colorPreferenceDict objectForKey:KEY_IDLE_COLOR] representedColor]];
        } else {
            [ebc setBuddyIconLabelColor: nil];
        }
    } else if ([notificationName isEqualToString: CONTACT_STATUS_IDLE_NO]) {
        tempEvent = @"is no longer idle";
        if ([ebc useBuddyIconLabel] || [ebc useBuddyNameLabel]) {
            [ebc setBuddyIconLabelColor: [[colorPreferenceDict objectForKey:KEY_LABEL_ONLINE_COLOR] representedColor]];
            [ebc setBuddyNameLabelColor: [[colorPreferenceDict objectForKey:KEY_ONLINE_COLOR] representedColor]];
        } else {
            [ebc setBuddyIconLabelColor: nil];
        }
    } else if ([notificationName isEqualToString: Content_FirstContentRecieved]) {
        tempEvent = @"says";
        if ([ebc useBuddyIconLabel] || [ebc useBuddyNameLabel]) {
            [ebc setBuddyIconLabelColor: [[colorPreferenceDict objectForKey:KEY_LABEL_UNVIEWED_COLOR] representedColor]];
            [ebc setBuddyNameLabelColor: [[colorPreferenceDict objectForKey:KEY_UNVIEWED_COLOR] representedColor]];
        } else {
            [ebc setBuddyIconLabelColor: nil];
        }
    }
    
    
    
    /*if ([ebc bezelPosition] != prefsPosition) {
        [ebc setBezelPosition: prefsPosition];
    }*/
    [ebc showBezelWithContact: [contact longDisplayName]
                    withImage: tempBuddyIcon
                     forEvent: tempEvent
                  withMessage: statusMessage];
}

@end
