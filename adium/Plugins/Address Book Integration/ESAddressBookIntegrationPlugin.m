//
//  ESAddressBookIntegrationPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Nov 19 2003.
//

#import "ESAddressBookIntegrationPlugin.h"

@interface ESAddressBookIntegrationPlugin(PRIVATE)
- (void)updateAllContacts;
- (void)updateSelf;
- (void)preferencesChanged:(NSNotification *)notification;
- (ABPerson *)searchForObject:(AIListObject *)inObject;
- (ABPerson *)_searchForUID:(NSString *)UID serviceID:(NSString *)serviceID;
- (void)rebuildAddressBookDict;
@end

@implementation ESAddressBookIntegrationPlugin

- (void)installPlugin
{
    meTag = -1;
    addressBookDict = nil;
	
    //Register ourself as a handle observer
    [[adium contactController] registerListObjectObserver:self];
	
    //Configure our preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:AB_DISPLAYFORMAT_DEFAULT_PREFS 
																		forClass:[self class]]  
										  forGroup:PREF_GROUP_ADDRESSBOOK];
    advancedPreferences = [[ESAddressBookIntegrationAdvancedPreferences preferencePane] retain];
	
    //Services dictionary
    serviceDict = [[NSDictionary dictionaryWithObjectsAndKeys:kABAIMInstantProperty,@"AIM",
								kABJabberInstantProperty,@"Jabber",
								kABMSNInstantProperty,@"MSN",
								kABYahooInstantProperty,@"Yahoo!",
								kABICQInstantProperty,@"ICQ",nil] retain];
	[self rebuildAddressBookDict];
	
    //Tracking dictionary for asynchronous image loads
    trackingDict = [[NSMutableDictionary alloc] init];
    
    //sharedAddressBook = [[ABAddressBook sharedAddressBook] retain];
	
    [self preferencesChanged:nil];
	
    //Observe preferences changes
    [[adium notificationCenter] addObserver:self 
								   selector:@selector(preferencesChanged:) 
									   name:Preference_GroupChanged 
									 object:nil];
    //Observe external address book changes
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(addressBookChanged:)
												 name:kABDatabaseChangedExternallyNotification
											   object:nil];
}

- (void)uninstallPlugin
{
    [[adium contactController] unregisterListObjectObserver:self];
    [[adium notificationCenter] removeObserver:self];
    
    [serviceDict release];
    [trackingDict release];
	//    [sharedAddressBook release];
}

//Called as contacts are created, load their address book information
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
	NSArray		*modifiedAttributes = nil;
	
    if(inModifiedKeys == nil){ //Only set on contact creation
                               //look up the property for this serviceID
        
        ABPerson *person = [self searchForObject:inObject];
		
		if (person) {
			//Begin the image load
			int tag = [person beginLoadingImageDataForClient:self];
			[trackingDict setObject:inObject forKey:[NSNumber numberWithInt:tag]];
			
			//Load the name if appropriate
			if (enableImport) {
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
		
    } else if (automaticSync && [inModifiedKeys containsObject: @"UserIcon"]) {
        
		//Find the person
        ABPerson *person = [self searchForObject:inObject];
        
        if (person){
			//Set the person's image to the inObject's serverside User Icon.
			NSImage	*image = [inObject statusObjectForKey:@"UserIcon"];
			if(image){
				[person setImageData:[image TIFFRepresentation]];
			}
		}
    }
    
    return(modifiedAttributes);
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_ADDRESSBOOK] == 0){
        NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_ADDRESSBOOK];
        //load new displayFormat
		enableImport = [[prefDict objectForKey:KEY_AB_ENABLE_IMPORT] boolValue];
        displayFormat = [[prefDict objectForKey:KEY_AB_DISPLAYFORMAT] intValue];
        automaticSync = [[prefDict objectForKey:KEY_AB_IMAGE_SYNC] boolValue];
        useNickName = [[prefDict objectForKey:KEY_AB_USE_NICKNAME] boolValue];
		preferAddressBookImages = [[prefDict objectForKey:KEY_AB_PREFER_ADDRESS_BOOK_IMAGES] boolValue];
		useABImages = [[prefDict objectForKey:KEY_AB_USE_IMAGES] boolValue];
		
        [self updateAllContacts];
    }
}

#pragma mark Image data

//Called when the address book completes an asynchronous image lookup
- (void)consumeImageData:(NSData *)inData forTag:(int)tag
{
    if (inData) {
        //Check if we retrieved data from the 'me' address book card
        if ((tag == meTag) && useABImages) {
			[[adium preferenceController] setPreference:inData forKey:@"UserIcon" group:GROUP_ACCOUNT_STATUS];
            meTag = -1;
        }else{
			NSNumber                *tagNumber = [NSNumber numberWithInt:tag];
			
			if( useABImages ) {
				//Apply the image to the appropriate listObject
				NSImage                 *image= [[[NSImage alloc] initWithData:inData] autorelease];
				
				//Get the object from our tracking dictionary
				AIListObject            *listObject = [trackingDict objectForKey:tagNumber];
				
				//Apply the image at lowest priority
				[[listObject displayArrayForKey:@"UserIcon"] setObject:image 
															 withOwner:self
														 priorityLevel:(preferAddressBookImages ? High_Priority : Low_Priority)];
				
				//Notify
				[[adium contactController] listObjectAttributesChanged:listObject
														  modifiedKeys:[NSArray arrayWithObject:@"UserIcon"]];	
				
			}
			//No further need for the dictionary entry
			[trackingDict removeObjectForKey:tagNumber];
		}
	}
}

#pragma mark Searching
- (ABPerson *)searchForObject:(AIListObject *)inObject
{
	ABPerson		*person = nil;
	NSString		*UID = [inObject UID];
	NSString		*serviceID = [inObject serviceID];
	
	person = [self _searchForUID:UID serviceID:serviceID];
	
	//If we don't find anything yet and inObject is an AIM account, try again using the ICQ property
	if (!person && [serviceID isEqualToString:@"AIM"]){
		person = [self _searchForUID:UID serviceID:@"ICQ"];
	}
	
	return person;
}
- (ABPerson *)_searchForUID:(NSString *)UID serviceID:(NSString *)serviceID
{
	ABPerson		*person = nil;
	NSDictionary *dict = [addressBookDict objectForKey:serviceID];
	
	if (dict){
		NSString *uniqueID = [dict objectForKey:[UID compactedString]];
		if (uniqueID){
			person = (ABPerson *)[[ABAddressBook sharedAddressBook] recordForUniqueId:uniqueID];
		}
	}
	
	return person;
}

#pragma mark Address book changed
- (void)addressBookChanged:(NSNotification *)notification
{
	[self rebuildAddressBookDict];
    [self updateAllContacts];
}

//Update all existing contacts
- (void)updateAllContacts
{
	[[adium contactController] updateAllListObjectsForObserver:self];
    [self updateSelf];
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

#pragma mark Address book caching
- (void)rebuildAddressBookDict
{
	[addressBookDict release];
	addressBookDict = [[NSMutableDictionary alloc] init];

	NSEnumerator	*peopleEnumerator = [[[ABAddressBook sharedAddressBook] people] objectEnumerator];
	ABPerson		*person;
	NSArray			*allServiceKeys = [serviceDict allKeys];
	
	while (person = [peopleEnumerator nextObject]){
		
		NSEnumerator	*servicesEnumerator = [allServiceKeys objectEnumerator];
		NSString		*serviceID;
		
		while (serviceID = [servicesEnumerator nextObject]){
			NSMutableDictionary  *dict = [addressBookDict objectForKey:serviceID];
			if (!dict){
				dict = [[[NSMutableDictionary alloc] init] autorelease];
				[addressBookDict setObject:dict forKey:serviceID];
			}
			
			NSString *addressBookKey = [serviceDict objectForKey:serviceID];
			
			//An ABPerson may have multiple names; iterate through them
			ABMultiValue	*names = [person valueForProperty:addressBookKey];
			int				nameCount = [names count];
			int				i;
			for (i=0 ; i<nameCount ; i++){
				[dict setObject:[person uniqueId] forKey:[[names valueAtIndex:i] compactedString]];
			}
			
			//Evan: Metacontact something here?
			if (nameCount > 1){
					//got a record with multiple names
			}
		}
	}
}

@end