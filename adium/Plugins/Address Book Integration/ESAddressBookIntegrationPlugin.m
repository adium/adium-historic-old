//
//  ESAddressBookIntegrationPlugin.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Wed Nov 19 2003.
//

#import "ESAddressBookIntegrationPlugin.h"

@interface ESAddressBookIntegrationPlugin(PRIVATE)
- (void)updateAllContacts;
- (void)updateSelf;
- (void)preferencesChanged:(NSNotification *)notification;
- (NSArray *)searchForObject:(AIListObject *)inObject;
- (NSArray *)_searchForScreenName:(NSString *)name withService:(NSString *)service;
@end

@implementation ESAddressBookIntegrationPlugin

- (void)installPlugin
{
    meTag = -1;
    
    //Register ourself as a handle observer
    [[adium contactController] registerListObjectObserver:self];
	
    //Configure our preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:AB_DISPLAYFORMAT_DEFAULT_PREFS forClass:[self class]]  forGroup:PREF_GROUP_ADDRESSBOOK];
    advancedPreferences = [[ESAddressBookIntegrationAdvancedPreferences preferencePane] retain];
	
    //Services dictionary
    propertyDict = [[NSDictionary dictionaryWithObjectsAndKeys:kABAIMInstantProperty,@"AIM",kABJabberInstantProperty,@"Jabber",kABMSNInstantProperty,@"MSN",kABYahooInstantProperty,@"Yahoo!",kABICQInstantProperty,@"ICQ",nil] retain];
    //Tracking dictionary for asynchronous image loads
    trackingDict = [[NSMutableDictionary alloc] init];
    
    //sharedAddressBook = [[ABAddressBook sharedAddressBook] retain];
	
    [self preferencesChanged:nil];
	
    //Observe preferences changes
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    //Observe external address book changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addressBookChanged:) name:kABDatabaseChangedExternallyNotification object:nil];
	
}

- (void)uninstallPlugin
{
    [[adium contactController] unregisterListObjectObserver:self];
    [[adium notificationCenter] removeObserver:self];
    
    [propertyDict release];
    [trackingDict release];
	//    [sharedAddressBook release];
}

//Called as contacts are created, load their address book information
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
	NSArray		*modifiedAttributes = nil;
	
    if(inModifiedKeys == nil){ //Only set on contact creation
                               //look up the property for this serviceID
        
        NSArray *results = [self searchForObject:inObject];
        
        if (results && [results count]) {
            ABPerson * person = [results objectAtIndex:0];
            
            if (person) {
                //Begin the image load if appropriate
                if (enableImages) {
                    int tag = [person beginLoadingImageDataForClient:self];
                    [trackingDict setObject:inObject forKey:[NSNumber numberWithInt:tag]];
                }
                
                //Load the name if appropriate
                if (displayFormat != None) {
                    NSString *firstName = [person valueForProperty:kABFirstNameProperty];
                    NSString *lastName = [person valueForProperty:kABLastNameProperty];
                    NSString *nickName;
                    NSString *displayName = nil;
                    
                    if (useNickName && (nickName = [person valueForProperty:kABNicknameProperty])) {
                        displayName = nickName;
                    } else if (!lastName || (displayFormat == First)) {  //If no last name is available, use the first name
                        displayName = firstName;
                    } else if (!firstName) {                    //If no first name is available, use the last name
                        displayName = lastName;
                    } else {                                    //Look to the preference setting
                        if (displayFormat == FirstLast) {
                            displayName = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
                        } else if (displayFormat == LastFirst) {
                            displayName = [NSString stringWithFormat:@"%@, %@",lastName,firstName]; 
                        }
                    }
                    
                    //Apply the values 
                    NSString *oldValue = [[inObject displayArrayForKey:@"Display Name"] objectWithOwner:self];
                    if (!oldValue || ![oldValue isEqualToString:displayName]) {
                        [[inObject displayArrayForKey:@"Display Name"] setObject:displayName withOwner:self];
						modifiedAttributes = [NSArray arrayWithObject:@"Display Name"];
                    } 
                } else {
                    //Clear any stored value
                    if ([[inObject displayArrayForKey:@"Display Name"] objectWithOwner:self]) {
                        [[inObject displayArrayForKey:@"Display Name"] setObject:nil withOwner:self];
						modifiedAttributes = [NSArray arrayWithObject:@"Display Name"];
                    }
                }
            }
        }
    } else if (automaticSync && [inModifiedKeys containsObject: @"UserIcon"]) {
        
        NSArray *results = [self searchForObject:inObject];
        
        if (results && [results count]){
            ABPerson * person;
            
            if (person = [results objectAtIndex:0]){
				AIMutableOwnerArray	*statusArray = [inObject statusArrayForKey:@"UserIcon"];
				
				if([statusArray count]){
                    [person setImageData: [[statusArray firstImage] TIFFRepresentation]];
                }
            }
        }
    }
    
    return(modifiedAttributes); //we don't change any keys
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_ADDRESSBOOK] == 0){
        NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_ADDRESSBOOK];
        //load new displayFormat
        displayFormat = [[prefDict objectForKey:KEY_AB_DISPLAYFORMAT] intValue];
        enableImages = [[prefDict objectForKey:KEY_AB_ENABLE_IMAGES] boolValue];
        automaticSync = [[prefDict objectForKey:KEY_AB_IMAGE_SYNC] boolValue];
        useNickName = [[prefDict objectForKey:KEY_AB_USE_NICKNAME] boolValue];
        [self updateAllContacts];
    }
}

- (void)addressBookChanged:(NSNotification *)notification
{
    [self updateAllContacts];
}

//Update all existing contacts
- (void)updateAllContacts
{
	[[adium contactController] updateAllListObjectsForObserver:self];
    [self updateSelf];
}

//Called when the address book completes an asynchronous image lookup
- (void)consumeImageData:(NSData *)inData forTag:(int)tag
{
    if (inData) {
        //Check if we retrieved data from the 'me' address book card
        if (tag == meTag) {
	    [[adium preferenceController] setPreference:inData forKey:@"UserIcon" group:GROUP_ACCOUNT_STATUS];
            meTag = -1;
        }else{
            //Apply the image to the appropriate listObject
            NSImage                 *image= [[[NSImage alloc] initWithData:inData] autorelease];
            NSNumber                *tagNumber = [NSNumber numberWithInt:tag];
            
            //Get the object from our tracking dictionary
            AIListObject            *listObject = [trackingDict objectForKey:tagNumber];
            AIMutableOwnerArray     *statusArray = [listObject statusArrayForKey:@"UserIcon"];
			
            //apply the image
            if([statusArray count] == 0) {
#warning Anything we apply to the status array here is just ignored.  We need to apply our icons as a primary object of the display array.
                [statusArray setObject:image withOwner:self];
                [[adium contactController] listObjectStatusChanged:listObject
                                                modifiedStatusKeys:[NSArray arrayWithObject:@"UserIcon"]
                                                            silent:NO];
            }
            
            //No further need for the dictionary entry
            [trackingDict removeObjectForKey:tagNumber];
        }
    }
}

- (void)updateSelf
{
    NS_DURING 
        //Begin loading image data for the "me" address book entry, if one exists
        ABPerson *me;
        if (me = [[ABAddressBook sharedAddressBook] me]) {
            meTag = [me beginLoadingImageDataForClient:self];
        }
    NS_HANDLER
        NSLog(@"ABIntegration: Caught %@: %@", [localException name], [localException reason]);
    NS_ENDHANDLER
}

- (NSArray *)searchForObject:(AIListObject *)inObject
{
    NSArray             *results = nil;
    NSString            *property = [propertyDict objectForKey:[inObject serviceID]];
    if (property) {
        NSString *screenName = [inObject UID];
        
        //search for the screen name as we have it stored (case insensitive)
        results = [self _searchForScreenName:screenName withService:property];
        
        //If we don't find anything, try again using the compacted version of the screen name (case insensitive)
        if (!results || ![results count]) {
            results = [self _searchForScreenName:[screenName compactedString] withService:property];
        }
        
        //If we don't find anything yet and are an AIM account, try again using the ICQ property
        if ((!results || ![results count]) && [property isEqualToString:kABAIMInstantProperty]) {
            results = [self _searchForScreenName:screenName withService:kABICQInstantProperty];
        }
    }
    
    return results;
}

- (NSArray *)_searchForScreenName:(NSString *)name withService:(NSString *)service
{
    ABSearchElement * searchElement = [ABPerson searchElementForProperty:service 
                                                                   label:nil 
                                                                     key:nil 
                                                                   value:name 
                                                              comparison:kABEqualCaseInsensitive];
    return [[ABAddressBook sharedAddressBook] recordsMatchingSearchElement:searchElement];
}

@end