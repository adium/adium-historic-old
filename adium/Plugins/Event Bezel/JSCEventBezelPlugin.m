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
        buddyNameFormat = [[preferenceDict objectForKey:KEY_EVENT_BEZEL_BUDDY_NAME_FORMAT] intValue];
        eventBezelPosition = [[preferenceDict objectForKey:KEY_EVENT_BEZEL_POSITION] intValue];
        
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
    if (!showEventBezel || (![eventArray containsObject:[notification name]])) {
        [self processBezelForNotification:notification];
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
    AIListContact   *contact;
    BOOL            isFirstMessage = NO;
    
    NSString        *notificationName = [notification name];
    
    if ([notificationName isEqualToString:Content_FirstContentRecieved]) {
        contact = [[[notification object] participatingListObjects] objectAtIndex:0];
        isFirstMessage = YES;
    } else {
        contact = [notification object];
    }
    
    AIMutableOwnerArray         *ownerArray;
    NSImage                     *tempBuddyIcon = nil;
    NSString                    *tempContactName = nil;
    NSString                    *statusMessage = nil;
    int                         currentPosition, prefPosition;
    
    ownerArray = [contact statusArrayForKey:@"BuddyImage"];
    if(ownerArray && [ownerArray count]) {
        tempBuddyIcon = [ownerArray objectAtIndex:0];
    }
    
    // Buddy Name Format
    switch (buddyNameFormat) {
        // Alias
        case 0:
            tempContactName = [contact displayName];
            break;
            // Alias (Screen Name)
        case 1:
            if ([[contact displayName] isEqualToString: [contact serverDisplayName]]) {
                tempContactName = [contact displayName];
            } else {
                tempContactName = [NSString stringWithFormat: @"%@ (%@)",
                    [contact displayName],
                    [contact serverDisplayName]];
            }
            break;
            // Screen Name (Alias)
        case 2:
            if ([[contact displayName] isEqualToString: [contact serverDisplayName]]) {
                tempContactName = [contact displayName];
            } else {
                tempContactName = [NSString stringWithFormat: @"%@ (%@)",
                    [contact serverDisplayName],
                    [contact displayName]];
            }
            break;
            // Screen Name
        case 3:
            tempContactName = [contact serverDisplayName];
            break;
            // Address Book Entry: [First Name] [Last Name]
        case 4: {
            NSArray *contacts;
            uint numberOfContacts;
            uint currentContactIndex;
            
            contacts = [[ABAddressBook sharedAddressBook] people];
            
            numberOfContacts = [contacts count];
            
            // Fall-back
            tempContactName = [contact displayName];
            
            for (currentContactIndex = 0;
                 currentContactIndex < numberOfContacts;
                 currentContactIndex++) {
                ABPerson *currentContact = [contacts objectAtIndex: currentContactIndex];
                NSString *currentContactFirstName = [currentContact valueForProperty: kABFirstNameProperty];
                NSString *currentContactLastName = [currentContact valueForProperty: kABLastNameProperty];
                ABMultiValue *currentContactAIMScreenNames = [currentContact valueForProperty:kABAIMInstantProperty];
                uint numberOfScreenNamesForContact = 0;
                uint currentScreenNameForContactIndex = 0;
                
                numberOfScreenNamesForContact = [currentContactAIMScreenNames count];
                
                for (currentScreenNameForContactIndex = 0;
                     currentScreenNameForContactIndex < numberOfScreenNamesForContact;
                     currentScreenNameForContactIndex++) {
                    NSString *screenName;
                    NSString *currentScreenNameForContact =
                        [currentContactAIMScreenNames valueAtIndex: currentScreenNameForContactIndex];
                    
                    screenName = [self stringWithoutWhitespace: [contact serverDisplayName]];
                    currentScreenNameForContact = [self stringWithoutWhitespace: currentScreenNameForContact];
                    
                    if ([screenName caseInsensitiveCompare: currentScreenNameForContact] == NSOrderedSame) {
                        if (currentContactFirstName != nil && currentContactLastName != nil) {
                            tempContactName = [NSString stringWithFormat: @"%@ %@",
                                currentContactFirstName,
                                currentContactLastName];
                        } else if (currentContactFirstName != nil && currentContactLastName == nil) {
                            tempContactName = currentContactFirstName;
                        } else if (currentContactFirstName == nil && currentContactLastName != nil) {
                            tempContactName = currentContactLastName;
                        } //fall-back
                    }
                }
            }
            break;
        }
            // Address Book Entry: [First Name]
        case 5: {
            NSArray *contacts;
            uint numberOfContacts;
            uint currentContactIndex;
            
            contacts = [[ABAddressBook sharedAddressBook] people];
            
            numberOfContacts = [contacts count];
            
            // Fall-back
            tempContactName = [contact displayName];
            
            for (currentContactIndex = 0;
                 currentContactIndex < numberOfContacts;
                 currentContactIndex++) {
                ABPerson *currentContact = [contacts objectAtIndex: currentContactIndex];
                NSString *currentContactFirstName = [currentContact valueForProperty: kABFirstNameProperty];
                ABMultiValue *currentContactAIMScreenNames = [currentContact valueForProperty:kABAIMInstantProperty];
                uint numberOfScreenNamesForContact = 0;
                uint currentScreenNameForContactIndex = 0;
                
                numberOfScreenNamesForContact = [currentContactAIMScreenNames count];
                
                for (currentScreenNameForContactIndex = 0;
                     currentScreenNameForContactIndex < numberOfScreenNamesForContact;
                     currentScreenNameForContactIndex++) {
                    NSString *screenName;
                    NSString *currentScreenNameForContact =
                        [currentContactAIMScreenNames valueAtIndex: currentScreenNameForContactIndex];
                    
                    screenName = [self stringWithoutWhitespace: [contact serverDisplayName]];
                    currentScreenNameForContact = [self stringWithoutWhitespace: currentScreenNameForContact];
                    
                    if ([screenName caseInsensitiveCompare: currentScreenNameForContact] == NSOrderedSame) {
                        if (currentContactFirstName != nil) {
                            tempContactName = currentContactFirstName;
                        } //fall-back
                    }
                }
            }
            break;
        }
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
    
    // Realculate bezel position, if needed
    currentPosition = [ebc bezelPosition];
    if (currentPosition != eventBezelPosition) {
        [ebc setBezelPosition: prefPosition];
    }
    
    [ebc showBezelWithContact: tempContactName
                    withImage: tempBuddyIcon
                     forEvent: notificationName
                  withMessage: statusMessage];
}

- ( NSString* )stringWithoutWhitespace:( NSString* )sourceString
{
    NSMutableString* newString = [ [ NSMutableString alloc ] init ];
    uint lengthOfSourceString;
    uint currentCharInSourceStringIndex;
    
    lengthOfSourceString = [ sourceString length ];
    
    for ( currentCharInSourceStringIndex = 0;
          currentCharInSourceStringIndex < lengthOfSourceString;
          currentCharInSourceStringIndex++ )
    {
        if ( [ sourceString compare:@" "
                            options:NSCaseInsensitiveSearch
                              range:NSMakeRange( currentCharInSourceStringIndex, 1 ) ] != NSOrderedSame )
        {
            [ newString appendString:[ sourceString substringWithRange:NSMakeRange( currentCharInSourceStringIndex, 1 ) ] ];
        }
    }
    
    return [ newString autorelease ];
}

@end
