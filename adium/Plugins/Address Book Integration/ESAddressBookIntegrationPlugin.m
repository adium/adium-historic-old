//
//  ESAddressBookIntegrationPlugin.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Wed Nov 19 2003.
//

#import "ESAddressBookIntegrationPlugin.h"

#define AB_DISPLAYFORMAT_DEFAULT_PREFS @"AB Display Format Defaults"

@interface ESAddressBookIntegrationPlugin(PRIVATE)
- (void)updateAllContacts;
- (void)updateSelf;
- (void)preferencesChanged:(NSNotification *)notification;
- (NSArray *)searchScreenName:(NSString *)name withService:(NSString *)service;
@end

@implementation ESAddressBookIntegrationPlugin

- (void)installPlugin
{
    //Register ourself as a handle observer
    [[owner contactController] registerListObjectObserver:self];
    
    //register default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:AB_DISPLAYFORMAT_DEFAULT_PREFS forClass:[self class]]  forGroup:PREF_GROUP_ADDRESSBOOK];
       
    advancedPreferences = [[ESAddressBookIntegrationAdvancedPreferences preferencePaneWithOwner:owner] retain];
      
    //Observe preferences changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    //Observe external address book changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addressBookChanged:) name:kABDatabaseChangedExternallyNotification object:nil];
        
    propertyDict = [[NSDictionary dictionaryWithObjectsAndKeys:kABAIMInstantProperty,@"AIM",kABJabberInstantProperty,@"Jabber",kABMSNInstantProperty,@"MSN",kABYahooInstantProperty,@"Yahoo",kABICQInstantProperty,@"ICQ",nil] retain];
    trackingDict = [[NSMutableDictionary alloc] init];
    sharedAddressBook = [[ABAddressBook sharedAddressBook] retain];
    
    [self preferencesChanged:nil];
}

- (void)uninstallPlugin
{
    [[owner contactController] unregisterListObjectObserver:self];
    [[owner notificationCenter] removeObserver:self];
    
    [propertyDict release];
    [trackingDict release];
    [sharedAddressBook release];
}

//Called as contacts are created, load their address book information
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys delayed:(BOOL)delayed silent:(BOOL)silent
{
    if(inModifiedKeys == nil){ //Only set on contact creation
                               //look up the property for this serviceID
        NSString * property = [propertyDict objectForKey:[inObject serviceID]];
        if (property) {
            NSString *screenName = [inObject UID];
            
            //search for the screen name as we have it stored (case insensitive)
            NSArray * results = [self searchScreenName: screenName withService: property];
            
            //If we don't find anything, try again using the compacted version of the screen name (case insensitive)
            if (!results || ![results count]) {
                results = [self searchScreenName: [screenName compactedString] withService: property];
            }
            
            //If we don't find anything yet, try again using the ICQ property
            if ((!results || ![results count]) && [property isEqualToString:kABAIMInstantProperty]) {
                results = [self searchScreenName: screenName withService: kABICQInstantProperty];
            }
            
            if (results && [results count]) {
                ABPerson * person = [results objectAtIndex:0];
                
                if (person) {
                    //Begin the image load if appropriate
                    int tag = [person beginLoadingImageDataForClient:self];
                    [trackingDict setObject:inObject forKey:[NSNumber numberWithInt:tag]];
                    
                    //Load the name
                    NSString *firstName = [person valueForProperty:kABFirstNameProperty];
                    NSString *lastName = [person valueForProperty:kABLastNameProperty];
                    NSString *displayName = nil;
                    if (!lastName || displayFormat == ADDRESS_BOOK_FIRST) { //If no last name is available, use the first name
                        displayName = firstName;
                    } else if (!firstName) {        //If no first name is available, use the last name
                        displayName = lastName;
                    } else {                        //Look to the preference setting
                        if (displayFormat == ADDRESS_BOOK_FIRST_LAST) {
                            displayName = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
                        } else if (displayFormat == ADDRESS_BOOK_LAST_FIRST) {
                            displayName = [NSString stringWithFormat:@"%@, %@",lastName,firstName]; 
                        }
                    }
                    
                    //Apply the values 
                    AIMutableOwnerArray *displayArray = [inObject displayArrayForKey:@"Display Name"];
                    NSString *oldValue = [displayArray objectWithOwner:self];
                    if (!oldValue || ![oldValue isEqualToString:displayName]) {
                        [[inObject displayArrayForKey:@"Display Name"] setObject:displayName withOwner:self];
                        [[owner contactController] listObjectAttributesChanged:inObject modifiedKeys:[NSArray arrayWithObject:@"Display Name"] delayed:delayed];
                    }
                }
            }
            
        }
    } else if ((syncMethod == ADDRESS_BOOK_SYNC_AUTO) && [inModifiedKeys containsObject: @"BuddyImage"]) {
        NSString * property = [propertyDict objectForKey:[inObject serviceID]];
        if (property) {
            NSString * screenName = [[inObject UID] compactedString];
            
            ABSearchElement * searchElement = [ABPerson searchElementForProperty:property label:nil     key:nil value:screenName comparison:kABEqualCaseInsensitive];
            NSArray * results = [sharedAddressBook recordsMatchingSearchElement:searchElement];
            
            if (results && [results count]) {
                ABPerson * person = [results objectAtIndex:0];
                
                if (person) {
                    AIHandle * handle = [(AIListContact *)inObject handleForAccount:nil];
                    NSMutableDictionary *statusDict = [handle statusDictionary];
                    //apply the image
                    if ([statusDict objectForKey:@"BuddyImage"]) {
                        [person setImageData: [[statusDict objectForKey:@"BuddyImage"] TIFFRepresentation]];
                    }
                }
            }
        }
    }
    
    return(nil); //we don't change any keys
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_ADDRESSBOOK] == 0){
        //load new displayFormat
        displayFormat = [[[owner preferenceController] preferenceForKey:KEY_AB_DISPLAYFORMAT group:PREF_GROUP_ADDRESSBOOK object:nil] intValue];
        syncMethod = [[[owner preferenceController] preferenceForKey:KEY_AB_IMAGE_SYNC group:PREF_GROUP_ADDRESSBOOK object:nil] intValue];
        [self updateAllContacts];
    }
}

- (void)addressBookChanged:(NSNotification *)notification
{
    [self updateAllContacts];
}

- (void)updateAllContacts
{
    //Update all existing contacts
    NSEnumerator * contactEnumerator = [[[owner contactController] allContactsInGroup:nil subgroups:YES] objectEnumerator];
    AIListObject * inObject;
    while (inObject = [contactEnumerator nextObject]){
        [self updateListObject:inObject
                          keys:nil
                       delayed:YES
                        silent:NO]; 
    }
    
    [self updateSelf];
}

//Called when the address book completes an asynchronous image lookup
- (void)consumeImageData:(NSData *)inData forTag:(int)tag
{
    if (inData) {
        NSImage *image = [[[NSImage alloc] initWithData:inData] autorelease];        
        NSNumber * tagNumber = [NSNumber numberWithInt:tag];
        
        //Get the object from our tracking dictionary
        AIHandle * handle = [(AIListContact *)[trackingDict objectForKey:tagNumber] handleForAccount:nil];
        NSMutableDictionary *statusDict = [handle statusDictionary];
        
        //apply the image
        if (![statusDict objectForKey:@"BuddyImage"]) {
            [[handle statusDictionary] setObject:image forKey:@"BuddyImage"];
            //tell the contact controller, silencing if necessary
            [[owner contactController] handleStatusChanged:handle
                                        modifiedStatusKeys:[NSArray arrayWithObject:@"BuddyImage"]
                                                   delayed:NO
                                                    silent:NO];
        }
        
        //No further need for the dictionary entry
        [trackingDict removeObjectForKey:tagNumber];
    }
}

- (void)updateSelf
{
    //Get the "me" address book entry, if one exists
    ABPerson *me = [sharedAddressBook me];
    
    //If one was found
    if (me) {
        NSData *myImage = [me imageData];
        if (myImage) {
            [[owner accountController] setDefaultUserIcon:[[[NSImage alloc] initWithData:myImage] autorelease]];
        }
    }
}

- (NSArray *)searchScreenName:(NSString *)name withService:(NSString *)service
{
    ABSearchElement * searchElement = [ABPerson searchElementForProperty:service 
                                                                   label:nil 
                                                                     key:nil 
                                                                   value:name 
                                                              comparison:kABEqualCaseInsensitive];
    return [sharedAddressBook recordsMatchingSearchElement:searchElement];
}
@end
