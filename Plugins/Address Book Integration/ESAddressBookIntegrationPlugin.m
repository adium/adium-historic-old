//
//  ESAddressBookIntegrationPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Nov 19 2003.
//

#import "ESAddressBookIntegrationPlugin.h"

#define IMAGE_LOOKUP_INTERVAL   0.1

@interface ESAddressBookIntegrationPlugin(PRIVATE)
- (void)updateAllContacts;
- (void)updateSelfIncludingIcon:(BOOL)includeIcon;
- (void)preferencesChanged:(NSNotification *)notification;
- (NSString *)nameForPerson:(ABPerson *)person;
- (ABPerson *)searchForObject:(AIListObject *)inObject;
- (ABPerson *)_searchForUID:(NSString *)UID serviceID:(NSString *)serviceID;
- (void)rebuildAddressBookDict;
@end

@implementation ESAddressBookIntegrationPlugin

- (void)installPlugin
{
    meTag = -1;
    addressBookDict = nil;
	listObjectArrayForImageData = nil;
	personArrayForImageData = nil;
	imageLookupTimer = nil;

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
	
    //Tracking dictionary for asynchronous image loads
    trackingDict = [[NSMutableDictionary alloc] init];
    
    //sharedAddressBook = [[ABAddressBook sharedAddressBook] retain];
	
	//Wait for Adium to finish launching before we build the address book so the contact list will be ready
	[[adium notificationCenter] addObserver:self
								   selector:@selector(adiumFinishedLaunching:)
									   name:Adium_CompletedApplicationLoad
									 object:nil];
}

- (void)uninstallPlugin
{
    [[adium contactController] unregisterListObjectObserver:self];
    [[adium notificationCenter] removeObserver:self];
    
    [serviceDict release]; serviceDict = nil;
    [trackingDict release]; trackingDict = nil;
	//    [sharedAddressBook release];
}

//Adium is ready to receive our glory.
- (void)adiumFinishedLaunching:(NSNotification *)notification
{	
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

    //Observe account changes
    [[adium notificationCenter] addObserver:self
								   selector:@selector(accountListChanged:)
									   name:Account_ListChanged
									 object:nil];

    [self preferencesChanged:nil];
}

//Called as contacts are created, load their address book information
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
	//Just stop here if we don't have an address book dict to work with
	if (!addressBookDict){
		return nil;
	}
	
	NSArray		*modifiedAttributes = nil;
	
    if(inModifiedKeys == nil){ //Only perform this when updating for all list objects
        
        ABPerson *person = [self searchForObject:inObject];
		
		if (person) {
			//Delayed lookup of image data
			if (!listObjectArrayForImageData){
				listObjectArrayForImageData = [[NSMutableArray alloc] init];
				personArrayForImageData = [[NSMutableArray alloc] init];
			}
			
			[listObjectArrayForImageData addObject:inObject];
			[personArrayForImageData addObject:person];
			if (!imageLookupTimer){
				imageLookupTimer = [[NSTimer scheduledTimerWithTimeInterval:IMAGE_LOOKUP_INTERVAL
																	 target:self 
																   selector:@selector(imageFetchTimer:) 
																   userInfo:nil
																	repeats:YES] retain];				
			}
			
			//Load the name if appropriate
			AIMutableOwnerArray *displayNameArray = [inObject displayArrayForKey:@"Display Name"];
		
			if (enableImport) {
				NSString			*displayName = [self nameForPerson:person];
				
				//Apply the values 
				NSString *oldValue = [displayNameArray objectWithOwner:self];
				if (!oldValue || ![oldValue isEqualToString:displayName]) {
					[displayNameArray setObject:displayName withOwner:self];
					modifiedAttributes = [NSArray arrayWithObject:@"Display Name"];
				}
			} else {
				//Clear any stored value
				if ([displayNameArray objectWithOwner:self]) {
					[displayNameArray setObject:nil withOwner:self];
					modifiedAttributes = [NSArray arrayWithObject:@"Display Name"];
				}
			}
			
			//If we changed anything, request an update of the alias / long display name
			if (modifiedAttributes){
				[[adium notificationCenter] postNotificationName:Contact_ApplyDisplayName
														  object:inObject
														userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:silent]
																							 forKey:@"Notify"]];
			}
		}
		
    } else if (automaticSync && [inModifiedKeys containsObject:KEY_USER_ICON]) {
        
		//Only update when the serverside icon changes if there is no Adium preference overriding it
		if (![inObject preferenceForKey:KEY_USER_ICON group:PREF_GROUP_USERICONS ignoreInheritedValues:YES]){
			//Find the person
			ABPerson *person = [self searchForObject:inObject];
			
			if (person){
				//Set the person's image to the inObject's serverside User Icon.
				NSData  *userIconData = [inObject statusObjectForKey:@"UserIconData"];
				if(!userIconData){
					userIconData = [[inObject statusObjectForKey:KEY_USER_ICON] TIFFRepresentation];
				}
				
				[person setImageData:userIconData];
			}
		}
    }
    
    return(modifiedAttributes);
}

- (NSString *)nameForPerson:(ABPerson *)person
{
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
	
	return displayName;
}

- (void)preferencesChanged:(NSNotification *)notification
{
	NSDictionary	*userInfo = [notification userInfo];
	NSString		*group = [userInfo objectForKey:@"Group"];
	
    if(notification == nil || [group isEqualToString:PREF_GROUP_ADDRESSBOOK]){
        NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_ADDRESSBOOK];
        //load new displayFormat
		enableImport = [[prefDict objectForKey:KEY_AB_ENABLE_IMPORT] boolValue];
        displayFormat = [[prefDict objectForKey:KEY_AB_DISPLAYFORMAT] intValue];
        automaticSync = [[prefDict objectForKey:KEY_AB_IMAGE_SYNC] boolValue];
        useNickName = [[prefDict objectForKey:KEY_AB_USE_NICKNAME] boolValue];
		preferAddressBookImages = [[prefDict objectForKey:KEY_AB_PREFER_ADDRESS_BOOK_IMAGES] boolValue];
		useABImages = [[prefDict objectForKey:KEY_AB_USE_IMAGES] boolValue];
		
		if (notification == nil){
			//Build the address book dictionary, which will also trigger metacontact grouping as appropriate
			[self rebuildAddressBookDict];
			
			//Register ourself as a listObject observer, which will update all objects
			[[adium contactController] registerListObjectObserver:self];
			
			//Now update from our "me" card information
		    [self updateSelfIncludingIcon:YES];	
			
		}else{
			//If we have a notification (so this isn't the first time through), update all contacts,
			//which will update objects and then our "me" card information
			[self updateAllContacts];
		}

    }else if (automaticSync && ([group isEqualToString:PREF_GROUP_USERICONS])){
		AIListObject	*inObject = [notification object];
		if (inObject){
			//Find the person
			ABPerson *person = [self searchForObject:inObject];
			
			if (person){
				//Set the person's image to the inObject's serverside User Icon.
				NSData	*imageData = [inObject preferenceForKey:KEY_USER_ICON
													  group:PREF_GROUP_USERICONS
										  ignoreInheritedValues:YES];
				
				//If the pref is now nil, we should restore the address book back to the serverside icon if possible
				if(!imageData){
					imageData = [[inObject statusObjectForKey:KEY_USER_ICON] TIFFRepresentation];
				}
				
				[person setImageData:imageData];
			}
		}
	}
}

#pragma mark Image data

//Called when the address book completes an asynchronous image lookup
- (void)consumeImageData:(NSData *)inData forTag:(int)tag
{
    if (inData) {
		if (tag == meTag){
			[[adium preferenceController] setPreference:inData
												 forKey:KEY_USER_ICON 
												  group:GROUP_ACCOUNT_STATUS];
			meTag = -1;
			
		}else if(useABImages){
			NSNumber                *tagNumber = [NSNumber numberWithInt:tag];
			
			//Apply the image to the appropriate listObject
			NSImage                 *image= [[[NSImage alloc] initWithData:inData] autorelease];
			
			//Get the object from our tracking dictionary
			AIListObject            *listObject = [trackingDict objectForKey:tagNumber];
			
			if (listObject){
				//Apply the image at lowest priority
				[listObject setDisplayUserIcon:image
									 withOwner:self
								 priorityLevel:(preferAddressBookImages ? High_Priority : Low_Priority)];
			}
			
			//No further need for the dictionary entry
			[trackingDict removeObjectForKey:tagNumber];
		}
	}
}

#pragma mark Searching
- (ABPerson *)searchForObject:(AIListObject *)inObject
{
	return([self _searchForUID:[inObject UID] serviceID:[[inObject service] serviceID]]);
	
//	ABPerson		*person = nil;
//	NSString		*UID = [inObject UID];
//	NSString		*serviceID = [inObject serviceID];
	
//	person = [self _searchForUID:UID serviceID:serviceID];
	
	//If we don't find anything yet and inObject is an AIM account, try again using the ICQ property
//	if (!person && [serviceID isEqualToString:@"AIM"]){
//		person = [self _searchForUID:UID serviceID:@"ICQ"];
//	}
	
//	return person;
}
- (ABPerson *)_searchForUID:(NSString *)UID serviceID:(NSString *)serviceID
{
	ABPerson		*person = nil;
	NSDictionary *dict;
	
	if ([serviceID isEqualToString:@"Mac"]) {
		dict = [addressBookDict objectForKey:@"AIM"];
	} else {
		dict = [addressBookDict objectForKey:serviceID];
	} 
	
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
    [self updateSelfIncludingIcon:YES];
}

- (void)accountListChanged:(NSNotification *)notification
{
	[self updateSelfIncludingIcon:NO];
}

- (void)updateSelfIncludingIcon:(BOOL)includeIcon
{
	NS_DURING 
        //Begin loading image data for the "me" address book entry, if one exists
        ABPerson *me;
        if (me = [[ABAddressBook sharedAddressBook] me]) {
			
			//Default buddy icon
			if (includeIcon){
				//Begin the image load
				meTag = [me beginLoadingImageDataForClient:self];
			}
			
			//Set account display names
			if (enableImport){
				NSEnumerator	*servicesEnumerator = [[serviceDict allKeys] objectEnumerator];
				NSString		*serviceID;
				NSString		*myDisplayName = [self nameForPerson:me];
				
				//Check for each service the address book supports
				while(serviceID = [servicesEnumerator nextObject]){
					NSString		*addressBookKey = [serviceDict objectForKey:serviceID];
					ABMultiValue	*names = [me valueForProperty:addressBookKey];
					
					if ([serviceID isEqualToString:@"AIM"] || [serviceID isEqualToString:@"ICQ"]){
						serviceID = @"AIM-compatible";
					}

					NSEnumerator	*serviceEnumerator = [[[adium accountController] servicesWithServiceClass:serviceID] objectEnumerator];
					AIService		*service;
					while (service = [serviceEnumerator nextObject]){
						
						NSEnumerator	*accountsArray = [[[adium accountController] accountsWithService:service] objectEnumerator];
						AIAccount		*account;
						
						//Look at each account on this service, searching for one a matching UID
						while (account = [accountsArray nextObject]){
							//An ABPerson may have multiple names on a given service; iterate through them
							NSString		*accountUID = [[account UID] compactedString];
							int				nameCount = [names count];
							int				i;
							
							for (i=0 ; i<nameCount ; i++){
								if ([accountUID isEqualToString:[[names valueAtIndex:i] compactedString]]){
									[[account displayArrayForKey:@"Display Name"] setObject:myDisplayName
																				  withOwner:self
																			  priorityLevel:Low_Priority];
									
								}
							}
						}
					}
				}
			}
        }
	NS_HANDLER
		NSLog(@"ABIntegration: Caught %@: %@", [localException name], [localException reason]);
	NS_ENDHANDLER
}

#pragma mark Address book caching
- (void)rebuildAddressBookDict
{
	NSMutableDictionary *mutableAddressBookDict = [[NSMutableDictionary alloc] init];

	NSEnumerator		*peopleEnumerator = [[[ABAddressBook sharedAddressBook] people] objectEnumerator];
	NSArray				*allServiceKeys = [serviceDict allKeys];
	ABPerson			*person;
	
	while (person = [peopleEnumerator nextObject]){
		
		NSEnumerator		*servicesEnumerator = [allServiceKeys objectEnumerator];
		NSString			*serviceID;
		
		NSMutableArray		*UIDsArray = [NSMutableArray array];
		NSMutableArray		*servicesArray = [NSMutableArray array];
		
		while (serviceID = [servicesEnumerator nextObject]){
			NSMutableDictionary  *dict = [mutableAddressBookDict objectForKey:serviceID];
			if (!dict){
				dict = [[[NSMutableDictionary alloc] init] autorelease];
				[mutableAddressBookDict setObject:dict forKey:serviceID];
			}
			
			NSString *addressBookKey = [serviceDict objectForKey:serviceID];
			
			//An ABPerson may have multiple names; iterate through them
			ABMultiValue	*names = [person valueForProperty:addressBookKey];
			int				nameCount = [names count];
			int				i;
			BOOL			isOSCAR = ([serviceID isEqualToString:@"AIM"] || 
									   [serviceID isEqualToString:@"ICQ"]);
				
			for (i=0 ; i<nameCount ; i++){
				NSString	*UID = [[names valueAtIndex:i] compactedString];
				[dict setObject:[person uniqueId] forKey:UID];
				
				[UIDsArray addObject:UID];
				
				//If we are on an OSCAR service we need to resolve our serviceID into the appropriate string
				if (isOSCAR){
					const char	firstCharacter = [UID characterAtIndex:0];
					
					//Determine service based on UID
					if([UID hasSuffix:@"@mac.com"]){
						serviceID = @"Mac";
					}else if(firstCharacter >= '0' && firstCharacter <= '9'){
						serviceID = @"ICQ";
					}else{
						serviceID = @"AIM";
					}
				}
				
				[servicesArray addObject:serviceID];
			}
		}
		
		if ([UIDsArray count] > 1){
			//Got a record with multiple names
			AIMetaContact	*metaContact = [[adium contactController] groupUIDs:UIDsArray forServices:servicesArray];
			
			//Load the name if appropriate
			AIMutableOwnerArray *displayNameArray = [metaContact displayArrayForKey:@"Display Name"];
			
			NSString			*displayName = [self nameForPerson:person];

			//Apply the values 
			NSString *oldValue = [displayNameArray objectWithOwner:self];
			if (!oldValue || ![oldValue isEqualToString:displayName]) {
				[displayNameArray setObject:displayName withOwner:self];
				
				[[adium notificationCenter] postNotificationName:Contact_ApplyDisplayName
														  object:metaContact
														userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
																							 forKey:@"Notify"]];				
			}
		}
	}
	
	//After this point we only need immutable access, so make a copy and keep that around, for efficiency
	[addressBookDict release]; addressBookDict = [mutableAddressBookDict copy];
	[mutableAddressBookDict release];
}

- (void)imageFetchTimer:(NSTimer *)inTimer
{
	if ([listObjectArrayForImageData count]){
		AIListObject	*inObject = [listObjectArrayForImageData objectAtIndex:0];
		ABPerson		*person = [personArrayForImageData objectAtIndex:0];
		
		//Begin the image load
		int tag = [person beginLoadingImageDataForClient:self];
		[trackingDict setObject:inObject forKey:[NSNumber numberWithInt:tag]];
		
		[listObjectArrayForImageData removeObjectAtIndex:0];
		[personArrayForImageData removeObjectAtIndex:0];
	}else{
		[listObjectArrayForImageData release]; listObjectArrayForImageData = nil;
		[personArrayForImageData release]; personArrayForImageData = nil;
		[imageLookupTimer invalidate]; [imageLookupTimer release]; imageLookupTimer = nil;
	}
}

@end