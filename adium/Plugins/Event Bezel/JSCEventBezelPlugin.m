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
- (void)eventNotification:(NSNotification *)notification;
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
    AIListContact   *contact;
    NSEnumerator    *accountEnumerator;
    AIAccount       *account;
    BOOL            isFirstMessage = NO;
    BOOL            showBezel = NO;
    NSDictionary    *preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_EVENT_BEZEL];
    
    if ([[preferenceDict objectForKey:KEY_SHOW_EVENT_BEZEL] boolValue]) {
        if ([[notification name] isEqualToString: Content_FirstContentRecieved]) {
            showBezel = [[preferenceDict objectForKey:KEY_EVENT_BEZEL_FIRST_MESSAGE] boolValue];
            contact = [[[notification object] participatingListObjects] objectAtIndex:0];
            isFirstMessage = YES;
        } else {
            if ([[notification name] isEqualToString: CONTACT_STATUS_ONLINE_YES]) {
                showBezel = [[preferenceDict objectForKey:KEY_EVENT_BEZEL_ONLINE] boolValue];
            } else if ([[notification name] isEqualToString: CONTACT_STATUS_ONLINE_NO]) {
                showBezel = [[preferenceDict objectForKey:KEY_EVENT_BEZEL_OFFLINE] boolValue];
            } else if ([[notification name] isEqualToString: CONTACT_STATUS_AWAY_YES]) {
                showBezel = [[preferenceDict objectForKey:KEY_EVENT_BEZEL_AWAY] boolValue];
            } else if ([[notification name] isEqualToString: CONTACT_STATUS_AWAY_NO]) {
                showBezel = [[preferenceDict objectForKey:KEY_EVENT_BEZEL_AVAILABLE] boolValue];
            } else if ([[notification name] isEqualToString: CONTACT_STATUS_IDLE_YES]) {
                showBezel = [[preferenceDict objectForKey:KEY_EVENT_BEZEL_IDLE] boolValue];
            } else if ([[notification name] isEqualToString: CONTACT_STATUS_IDLE_NO]) {
                showBezel = [[preferenceDict objectForKey:KEY_EVENT_BEZEL_NO_IDLE] boolValue];
            }
            contact = [notification object];
        }
    }
    
    if (showBezel) {
        accountEnumerator = [[[owner accountController] accountArray] objectEnumerator];
        while ((account = [accountEnumerator nextObject])) {
            AIHandle    *contactHandle;
            if (contactHandle = [contact handleForAccount: account]) {
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
                switch ([[preferenceDict objectForKey:KEY_EVENT_BEZEL_BUDDY_NAME_FORMAT] intValue]) {
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
                prefPosition = [[preferenceDict objectForKey:KEY_EVENT_BEZEL_POSITION] intValue];
                if (currentPosition != prefPosition) {
                    [ebc setBezelPosition: prefPosition];
                }
                
                [ebc showBezelWithContact: tempContactName
                                withImage: tempBuddyIcon
                                 forEvent: [notification name]
                              withMessage: statusMessage];
            }
        }
    }
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
