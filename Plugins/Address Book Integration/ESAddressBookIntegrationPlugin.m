//
//  ESAddressBookIntegrationPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Nov 19 2003.
//

#import "ESAddressBookIntegrationPlugin.h"

#define IMAGE_LOOKUP_INTERVAL   0.01

@interface ESAddressBookIntegrationPlugin(PRIVATE)
- (void)updateAllContacts;
- (void)updateSelfIncludingIcon:(BOOL)includeIcon;
- (void)preferencesChanged:(NSNotification *)notification;
- (NSString *)nameForPerson:(ABPerson *)person;
- (ABPerson *)searchForObject:(AIListObject *)inObject;
- (ABPerson *)_searchForUID:(NSString *)UID serviceID:(NSString *)serviceID;
- (void)rebuildAddressBookDict;
- (void)queueDelayedFetchOfImageForPerson:(ABPerson *)person object:(AIListObject *)inObject;
@end

@implementation ESAddressBookIntegrationPlugin

static	ABAddressBook	*sharedAddressBook = nil;

- (void)installPlugin
{
    meTag = -1;
    addressBookDict = nil;
	listObjectArrayForImageData = nil;
	personArrayForImageData = nil;
	imageLookupTimer = nil;
	createMetaContacts = NO;

	//Tracking dictionary for asynchronous image loads
    trackingDict = [[NSMutableDictionary alloc] init];
    trackingDictPersonToTagNumber = [[NSMutableDictionary alloc] init];
    trackingDictTagNumberToPerson = [[NSMutableDictionary alloc] init];
	
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
	[trackingDictPersonToTagNumber release]; trackingDictPersonToTagNumber = nil;
	[trackingDictTagNumberToPerson release]; trackingDictTagNumberToPerson = nil;
	
	[sharedAddressBook release]; sharedAddressBook = nil;
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

			[self queueDelayedFetchOfImageForPerson:person object:inObject];

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
		if (displayFormat == FirstLast){
			displayName = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
		}else if (displayFormat == LastFirst){
			displayName = [NSString stringWithFormat:@"%@, %@",lastName,firstName]; 
		}else if (displayFormat == LastFirstNoComma){
			displayName = [NSString stringWithFormat:@"%@ %@",lastName,firstName]; 
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
		BOOL			oldCreateMetaContacts = createMetaContacts;
		
        //load new displayFormat
		enableImport = [[prefDict objectForKey:KEY_AB_ENABLE_IMPORT] boolValue];
        displayFormat = [[prefDict objectForKey:KEY_AB_DISPLAYFORMAT] intValue];
        automaticSync = [[prefDict objectForKey:KEY_AB_IMAGE_SYNC] boolValue];
        useNickName = [[prefDict objectForKey:KEY_AB_USE_NICKNAME] boolValue];
		preferAddressBookImages = [[prefDict objectForKey:KEY_AB_PREFER_ADDRESS_BOOK_IMAGES] boolValue];
		useABImages = [[prefDict objectForKey:KEY_AB_USE_IMAGES] boolValue];

		createMetaContacts = [[prefDict objectForKey:KEY_AB_CREATE_METACONTACTS] boolValue];
		
		if (notification == nil){
			//Build the address book dictionary, which will also trigger metacontact grouping as appropriate
			[self rebuildAddressBookDict];
			
			//Register ourself as a listObject observer, which will update all objects
			[[adium contactController] registerListObjectObserver:self];
			
			//Now update from our "me" card information
		    [self updateSelfIncludingIcon:YES];	
			
		}else{
			/* We have a notification (so this isn't the first time through): */

			//If we weren't creating meta contacts before but we are now
			if (!oldCreateMetaContacts && createMetaContacts){
				/*
				 Build the address book dictionary, which will also trigger metacontact grouping as appropriate
				 Delay to the next run loop to give better UI responsiveness
				 */
				[self performSelector:@selector(rebuildAddressBookDict)
						   withObject:nil
						   afterDelay:0.0001];
			}
			
			//Update all contacts, which will update objects and then our "me" card information
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
	if (tag == meTag){
		[[adium preferenceController] setPreference:inData
											 forKey:KEY_USER_ICON 
											  group:GROUP_ACCOUNT_STATUS];
		meTag = -1;
		
	}else if(useABImages){
		NSNumber		*tagNumber;
		NSImage			*image;
		AIListObject	*listObject;
		id				setOrObject;
		
		tagNumber = [NSNumber numberWithInt:tag];
		
		//Apply the image to the appropriate listObject
		image = (inData ? [[[NSImage alloc] initWithData:inData] autorelease] : nil);
		
		//Get the object from our tracking dictionary
		setOrObject = [trackingDict objectForKey:tagNumber];
		
		if ([setOrObject isKindOfClass:[AIListObject class]]){
			listObject = (AIListObject *)setOrObject;
			
			//Apply the image at the appropriate priority
			[listObject setDisplayUserIcon:image
								 withOwner:self
							 priorityLevel:(preferAddressBookImages ? High_Priority : Low_Priority)];

		}else /*if ([setOrObject isKindOfClass:[NSSet class]])*/{
			NSEnumerator	*enumerator;

			//Apply the image to each listObject at the appropriate priority
			enumerator = [(NSSet *)setOrObject objectEnumerator];
			while(listObject = [enumerator nextObject]){
				[listObject setDisplayUserIcon:image
									 withOwner:self
								 priorityLevel:(preferAddressBookImages ? High_Priority : Low_Priority)];
			}
		}
		
		//No further need for the dictionary entries
		[trackingDict removeObjectForKey:tagNumber];
		
		[trackingDictPersonToTagNumber removeObjectForKey:[trackingDictTagNumberToPerson objectForKey:tagNumber]];
		[trackingDictTagNumberToPerson removeObjectForKey:tagNumber];
	}
}

- (void)queueDelayedFetchOfImageForPerson:(ABPerson *)person object:(AIListObject *)inObject
{
	int				tag;
	NSNumber		*tagNumber;
	NSString		*uniqueId;
	
	uniqueId = [person uniqueId];
	
	//Check if we already have a tag for the loading of another object with the same
	//internalObjectID
	if (tagNumber = [trackingDictPersonToTagNumber objectForKey:uniqueId]){
		id				previousValue;
		NSMutableSet	*objectSet;
		
		previousValue = [trackingDict objectForKey:tagNumber];
		
		if ([previousValue isKindOfClass:[AIListObject class]]){
			//If the old value is just a listObject, create an array with the old object
			//and the new object
			objectSet = [NSMutableSet setWithObjects:previousValue,inObject,nil];
			
			//Store the array in the tracking dict
			[trackingDict setObject:objectSet forKey:tagNumber];
			
		}else /*if ([previousValue isKindOfClass:[NSMutableArray class]])*/{
			//Add the new object to the previously-created array
			[(NSMutableSet *)previousValue addObject:inObject];
		}
		
	}else{
		//Begin the image load
		tag = [person beginLoadingImageDataForClient:self];
		tagNumber = [NSNumber numberWithInt:tag];
		
		//We need to be able to take a tagNumber and retrieve the object
		[trackingDict setObject:inObject forKey:tagNumber];
		
		//We also want to take a person's uniqueID and potentially find an existing tag number
		[trackingDictPersonToTagNumber setObject:tagNumber forKey:uniqueId];
		[trackingDictTagNumberToPerson setObject:uniqueId forKey:tagNumber];
	}
}

#pragma mark Searching
- (ABPerson *)searchForObject:(AIListObject *)inObject
{
	ABPerson		*person = nil;
	if ([inObject isKindOfClass:[AIMetaContact class]]){
		NSEnumerator	*enumerator;
		AIListContact	*listContact;
		
		//Search for an ABPerson for each listContact within the metaContact; first one we find is
		//the lucky winner.
		enumerator = [[(AIMetaContact *)inObject listContacts] objectEnumerator];
		while((listContact = [enumerator nextObject]) && (person == nil)){
			person = [self searchForObject:listContact];
		}
		
	}else{
		NSString		*UID = [inObject UID];
		NSString		*serviceID = [[inObject service] serviceID];
		
		person = [self _searchForUID:UID serviceID:serviceID];
		
		//If we don't find anything yet and inObject is an AIM account, try again using the ICQ property; ICQ, try again using AIM
		if (!person){
			if ([serviceID isEqualToString:@"AIM"]){
				person = [self _searchForUID:UID serviceID:@"ICQ"];
			}else if ([serviceID isEqualToString:@"ICQ"]){
				person = [self _searchForUID:UID serviceID:@"AIM"];
			}
		}
	}
	return person;
}
- (ABPerson *)_searchForUID:(NSString *)UID serviceID:(NSString *)serviceID
{
	ABPerson		*person = nil;
	NSDictionary	*dict;
	
	if ([serviceID isEqualToString:@"Mac"]) {
		dict = [addressBookDict objectForKey:@"AIM"];
	} else {
		dict = [addressBookDict objectForKey:serviceID];
	} 
	
	if (dict){
		NSString *uniqueID = [dict objectForKey:[UID compactedString]];
		if (uniqueID){
			person = (ABPerson *)[sharedAddressBook recordForUniqueId:uniqueID];
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
        if (me = [sharedAddressBook me]) {
			
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
	NSEnumerator		*peopleEnumerator;
	NSArray				*allServiceKeys;
	ABPerson			*person;
	
	//Delay listObjectNotifications to speed up metaContact creation
	[[adium contactController] delayListObjectNotifications];

	[sharedAddressBook release]; sharedAddressBook = [[ABAddressBook sharedAddressBook] retain];
	[addressBookDict release]; addressBookDict = [[NSMutableDictionary alloc] init];
	
	allServiceKeys = [serviceDict allKeys];
	
	peopleEnumerator = [[sharedAddressBook people] objectEnumerator];
	while (person = [peopleEnumerator nextObject]){
		
		NSEnumerator		*servicesEnumerator = [allServiceKeys objectEnumerator];
		NSString			*serviceID;
		
		NSMutableArray		*UIDsArray = [NSMutableArray array];
		NSMutableArray		*servicesArray = [NSMutableArray array];
		
		while (serviceID = [servicesEnumerator nextObject]){
			NSMutableDictionary		*dict;
			NSString				*addressBookKey;
			ABMultiValue			*names;
			int						i, nameCount;
			BOOL					isOSCAR = ([serviceID isEqualToString:@"AIM"] || 
											   [serviceID isEqualToString:@"ICQ"]);
			
			if (!(dict = [addressBookDict objectForKey:serviceID])){
				dict = [[[NSMutableDictionary alloc] init] autorelease];
				[addressBookDict setObject:dict forKey:serviceID];
			}
			
			addressBookKey = [serviceDict objectForKey:serviceID];
			
			//An ABPerson may have multiple names; iterate through them
			names = [person valueForProperty:addressBookKey];
			nameCount = [names count];
				
			for (i=0 ; i < nameCount ; i++){
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
		
		if (([UIDsArray count] > 1) && createMetaContacts){
			/* Got a record with multiple names */
			[[adium contactController] groupUIDs:UIDsArray forServices:servicesArray];
		}
	}
	
	//Stop delaying list object notifications since we are done
	[[adium contactController] endListObjectNotificationsDelay];
}

@end