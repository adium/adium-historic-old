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

#define CONTACT_BEZEL_NIB   @"ContactEventBezel"

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
    
    
    //Install the contact info view
    [NSBundle loadNibNamed:CONTACT_BEZEL_NIB owner:self];
    contactView = [[AIPreferenceViewController controllerWithName:@"Event Bezel" categoryName:@"None" view:view_contactBezelInfoView delegate:self] retain];
    [[owner contactController] addContactInfoView:contactView];
    
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
        
        switch ([[preferenceDict objectForKey:KEY_EVENT_BEZEL_SIZE] intValue]) {
            case SIZE_NORMAL:
                [ebc setBezelSize: NSMakeSize(211.0,206.0)];
            break;
            case SIZE_SMALL:
                [ebc setBezelSize: NSMakeSize(158.0,155.0)];
            break;
        }
        
        switch ([[preferenceDict objectForKey:KEY_EVENT_BEZEL_BACKGROUND] intValue]) {
            case BACKGROUND_NORMAL:
                [ebc setBackdropImage: [[NSImage alloc] initWithContentsOfFile:
                    [[NSBundle bundleForClass:[self class]] pathForResource:@"backdrop" ofType:@"png"]]];
            break;
            case BACKGROUND_DARK:
                [ebc setBackdropImage: [[NSImage alloc] initWithContentsOfFile:
                    [[NSBundle bundleForClass:[self class]] pathForResource:@"backdropDark" ofType:@"png"]]];
            break;
        }
        
        [ebc setBezelPosition: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_POSITION] intValue]];
        [ebc setImageBadges: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_IMAGE_BADGES] boolValue]];
        [ebc setUseBuddyIconLabel: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_COLOR_LABELS] boolValue]];
        [ebc setUseBuddyNameLabel: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_NAME_LABELS] boolValue]];
        [ebc setBezelDuration: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_DURATION] intValue]];
        [ebc setDoFadeIn: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_FADE_IN] boolValue]];
        [ebc setDoFadeOut: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_FADE_OUT] boolValue]];
        
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
    NSDictionary                *preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_EVENT_BEZEL];
    NSDictionary                *colorPreferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_STATUS_COLORING];
    
    if ([notificationName isEqualToString:Content_FirstContentRecieved]) {
        contact = [[[notification object] participatingListObjects] objectAtIndex:0];
        isFirstMessage = YES;
    } else {
        contact = [notification object];
    }
        
    //Check to be sure bezel for contact and for its group is enabled
    NSNumber *contactDisabledNumber = [[owner preferenceController] preferenceForKey:CONTACT_DISABLE_BEZEL group:PREF_GROUP_EVENT_BEZEL object:contact];
    NSNumber *groupDisabledNumber = [[owner preferenceController] preferenceForKey:CONTACT_DISABLE_BEZEL group:PREF_GROUP_EVENT_BEZEL object:[contact containingGroup]];
    BOOL contactEnabled = !contactDisabledNumber || (![contactDisabledNumber boolValue]);
    BOOL groupEnabled = !groupDisabledNumber || (![groupDisabledNumber boolValue]);
    // If Adium is hidden, check if we want it to show (and unhide Adium in the process)
    BOOL showIfHidden = ![NSApp isHidden] || ([NSApp isHidden] && [[preferenceDict objectForKey:KEY_EVENT_BEZEL_SHOW_HIDDEN] boolValue]);
    // If you are away, check if we want it to show
    BOOL showIfAway = ![[owner accountController] propertyForKey:@"AwayMessage" account:nil]
        || ([[owner accountController] propertyForKey:@"AwayMessage" account:nil] && [[preferenceDict objectForKey:KEY_EVENT_BEZEL_SHOW_AWAY] boolValue]);
    
    if (contactEnabled && groupEnabled && showIfHidden && showIfAway){
        BOOL wasHidden = NO;
        if ([NSApp isHidden]) {
            wasHidden = YES;
            [NSApp unhideWithoutActivation];
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
        
        
        [ebc showBezelWithContact: [contact longDisplayName]
                        withImage: tempBuddyIcon
                         forEvent: tempEvent
                      withMessage: statusMessage];
    }
}

- (void)configurePreferenceViewController:(AIPreferenceViewController *)inController forObject:(id)inObject
{
    NSNumber *contactDisableBezel;
    //Hold onto the object
    [activeListObject release]; activeListObject = nil;
    activeListObject = [inObject retain];
    
    contactDisableBezel = [[owner preferenceController] preferenceForKey:CONTACT_DISABLE_BEZEL group:PREF_GROUP_EVENT_BEZEL object:activeListObject];
    if (contactDisableBezel)
        [checkBox_disableBezel setState:[contactDisableBezel boolValue]];
    else
        [checkBox_disableBezel setState:NO];
}

- (IBAction)changedSetting:(id)sender
{
    if (sender == checkBox_disableBezel) {
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[checkBox_disableBezel state]] forKey:CONTACT_DISABLE_BEZEL group:PREF_GROUP_EVENT_BEZEL object:activeListObject];
    }
}
@end
