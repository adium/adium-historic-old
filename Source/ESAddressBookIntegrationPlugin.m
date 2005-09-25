/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIAccountController.h"
#import "AIContactController.h"
#import "ESAddressBookIntegrationPlugin.h"
#import "AIMenuController.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIMutableOwnerArray.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/OWAddressBookAdditions.h>
#import <AIUtilities/AIExceptionHandlingUtilities.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIService.h>

#define IMAGE_LOOKUP_INTERVAL   0.01
#define SHOW_IN_AB_CONTEXTUAL_AB_MENU_TITLE AILocalizedString(@"Show In Address Book", "Show In Address Book Contextual Menu")
#define EDIT_IN_AB_CONTEXTUAL_AB_MENU_TITLE AILocalizedString(@"Edit In Address Book", "Edit In Address Book Contextual Menu")

@interface ESAddressBookIntegrationPlugin(PRIVATE)
- (void)updateAllContacts;
- (void)updateSelfIncludingIcon:(BOOL)includeIcon;
- (void)preferencesChanged:(NSNotification *)notification;
- (NSString *)nameForPerson:(ABPerson *)person phonetic:(NSString **)phonetic;
- (ABPerson *)searchForObject:(AIListObject *)inObject;
- (ABPerson *)_searchForUID:(NSString *)UID serviceID:(NSString *)serviceID;
- (void)rebuildAddressBookDict;
- (void)queueDelayedFetchOfImageForPerson:(ABPerson *)person object:(AIListObject *)inObject;
- (void)showInAddressBook;
- (void)editInAddressBook;
- (void)addToAddressBookDict:(NSArray *)people;
- (void)removeFromAddressBookDict:(NSArray *)UIDs;
@end

/*!
 * @class ESAddressBookIntegrationPlugin
 * @brief Provides Apple Address Book integration
 *
 * This class allows Adium to seamlessly interact with the Apple Address Book, pulling names and icons, storing icons
 * if desired, and generating metaContacts based on screen name grouping.  It relies upon cards having screen names listed
 * in the appropriate service fields in the address book.
 */
@implementation ESAddressBookIntegrationPlugin

static	ABAddressBook	*sharedAddressBook = nil;

/*!
 * @brief Install plugin
 *
 * This plugin finishes installing in adiumFinishedLaunching:
 */
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
	
	//Shared Address Book
	[sharedAddressBook release]; sharedAddressBook = [[ABAddressBook sharedAddressBook] retain];
	
	//Create our contextual menus and install them
	showInABContextualMenuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:SHOW_IN_AB_CONTEXTUAL_AB_MENU_TITLE
																			   action:@selector(showInAddressBook)
																		keyEquivalent:@""] autorelease];
	[showInABContextualMenuItem setTarget:self];
	
	editInABContextualMenuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:EDIT_IN_AB_CONTEXTUAL_AB_MENU_TITLE
																					   action:@selector(editInAddressBook)
																				keyEquivalent:@""] autorelease];
	[editInABContextualMenuItem setTarget:self];
	[editInABContextualMenuItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
	[editInABContextualMenuItem setAlternate:YES];
	
	[[adium menuController] addContextualMenuItem:showInABContextualMenuItem toLocation:Context_Contact_Action];
	[[adium menuController] addContextualMenuItem:editInABContextualMenuItem toLocation:Context_Contact_Action];
	
	//Wait for Adium to finish launching before we build the address book so the contact list will be ready
	[[adium notificationCenter] addObserver:self
								   selector:@selector(adiumFinishedLaunching:)
									   name:Adium_CompletedApplicationLoad
									 object:nil];
}

/*!
 * @brief Uninstall plugin
 */
- (void)uninstallPlugin
{
    [[adium contactController] unregisterListObjectObserver:self];
    [[adium notificationCenter] removeObserver:self];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
    [serviceDict release]; serviceDict = nil;
    [trackingDict release]; trackingDict = nil;
	[trackingDictPersonToTagNumber release]; trackingDictPersonToTagNumber = nil;
	[trackingDictTagNumberToPerson release]; trackingDictTagNumberToPerson = nil;

	[sharedAddressBook release]; sharedAddressBook = nil;

	[[adium preferenceController] unregisterPreferenceObserver:self];
	[[adium notificationCenter] removeObserver:self];

	[super dealloc];
}

/*!
 * @brief Adium finished launching
 *
 * Register our observers for the address book changing externally and for the account list changing.
 * Register our preference observers. This will trigger initial building of the address book dictionary.
 */
- (void)adiumFinishedLaunching:(NSNotification *)notification
{	
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

    //Observe preferences changes
    AIPreferenceController *preferenceController = [adium preferenceController];
	[preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_ADDRESSBOOK];
	[preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_USERICONS];
}

/*!
 * @brief Used as contacts are created and icons are changed.
 *
 * When first created, load a contact's address book information from our dict.
 * When an icon as a status object changes, if desired, write the changed icon out to the appropriate AB card.
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	//Just stop here if we don't have an address book dict to work with
	if (!addressBookDict) {
		return nil;
	}
	
	NSSet		*modifiedAttributes = nil;
	
    if (inModifiedKeys == nil) { //Only perform this when updating for all list objects
        
        ABPerson *person = [self searchForObject:inObject];
		
		if (person) {

			[self queueDelayedFetchOfImageForPerson:person object:inObject];

			if (enableImport) {
				//Load the name if appropriate
				AIMutableOwnerArray *displayNameArray, *phoneticNameArray;
				NSString			*displayName, *phoneticName = nil;
				
				displayNameArray = [inObject displayArrayForKey:@"Display Name"];
				
				displayName = [self nameForPerson:person phonetic:&phoneticName];
				
				//Apply the values 
				NSString *oldValue = [displayNameArray objectWithOwner:self];
				if (!oldValue || ![oldValue isEqualToString:displayName]) {
					[displayNameArray setObject:displayName withOwner:self];
					modifiedAttributes = [NSSet setWithObject:@"Display Name"];
				}
				
				if (phoneticName) {
					phoneticNameArray = [inObject displayArrayForKey:@"Phonetic Name"];

					//Apply the values 
					oldValue = [phoneticNameArray objectWithOwner:self];
					if (!oldValue || ![oldValue isEqualToString:phoneticName]) {
						[phoneticNameArray setObject:phoneticName withOwner:self];
						modifiedAttributes = [NSSet setWithObjects:@"Display Name", @"Phonetic Name", nil];
					}
				} else {
					phoneticNameArray = [inObject displayArrayForKey:@"Phonetic Name"
															  create:NO];
					//Clear any stored value
					if ([phoneticNameArray objectWithOwner:self]) {
						[displayNameArray setObject:nil withOwner:self];
						modifiedAttributes = [NSSet setWithObjects:@"Display Name", @"Phonetic Name", nil];
					}					
				}

			} else {
				AIMutableOwnerArray *displayNameArray, *phoneticNameArray;
				
				displayNameArray = [inObject displayArrayForKey:@"Display Name"
														 create:NO];

				//Clear any stored value
				if ([displayNameArray objectWithOwner:self]) {
					[displayNameArray setObject:nil withOwner:self];
					modifiedAttributes = [NSSet setWithObject:@"Display Name"];
				}
				
				phoneticNameArray = [inObject displayArrayForKey:@"Phonetic Name"
														  create:NO];
				//Clear any stored value
				if ([phoneticNameArray objectWithOwner:self]) {
					[displayNameArray setObject:nil withOwner:self];
					modifiedAttributes = [NSSet setWithObjects:@"Display Name", @"Phonetic Name", nil];
				}					
				
			}

			//If we changed anything, request an update of the alias / long display name
			if (modifiedAttributes) {
				[[adium notificationCenter] postNotificationName:Contact_ApplyDisplayName
														  object:inObject
														userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:silent]
																							 forKey:@"Notify"]];
			}
		}
		
    } else if (automaticSync && [inModifiedKeys containsObject:KEY_USER_ICON]) {
        
		//Only update when the serverside icon changes if there is no Adium preference overriding it
		if (![inObject preferenceForKey:KEY_USER_ICON group:PREF_GROUP_USERICONS ignoreInheritedValues:YES]) {
			//Find the person
			ABPerson *person = [self searchForObject:inObject];
			
			if (person) {
				//Set the person's image to the inObject's serverside User Icon.
				NSData  *userIconData = [inObject statusObjectForKey:@"UserIconData"];
				if (!userIconData) {
					userIconData = [[inObject statusObjectForKey:KEY_USER_ICON] TIFFRepresentation];
				}
				
				[person setImageData:userIconData];
			}
		}
    }
    
    return modifiedAttributes;
}

/*!
 * @brief Return the name of an ABPerson in the way Adium should display it
 *
 * @param person An <tt>ABPerson</tt>
 * @param phonetic A pointer to an <tt>NSString</tt> which will be filled with the phonetic display name if available
 * @result A string based on the first name, last name, and/or nickname of the person, as specified via preferences.
 */
- (NSString *)nameForPerson:(ABPerson *)person phonetic:(NSString **)phonetic
{
	NSString *firstName, *lastName, *phoneticFirstName, *phoneticLastName;	
	NSString *nickName;
	NSString *displayName = nil;
	
	firstName = [person valueForProperty:kABFirstNameProperty];
	lastName = [person valueForProperty:kABLastNameProperty];
	phoneticFirstName = [person valueForProperty:kABFirstNamePhoneticProperty];
	phoneticLastName = [person valueForProperty:kABLastNamePhoneticProperty];

	if (useNickName && (nickName = [person valueForProperty:kABNicknameProperty])) {
		displayName = nickName;

	} else if (!lastName || (displayFormat == First)) {  
		/* If no last name is available, use the first name */
		displayName = firstName;
		if (phonetic != NULL) *phonetic = phoneticFirstName;

	} else if (!firstName) {
		/* If no first name is available, use the last name */
		displayName = lastName;
		if (phonetic != NULL) *phonetic = phoneticLastName;

	} else {
		BOOL havePhonetic = ((phonetic != NULL) && (phoneticFirstName || phoneticLastName));

		/* Look to the preference setting */
		switch (displayFormat) {
			case FirstLast:
				displayName = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
				if (havePhonetic) {
					*phonetic = [NSString stringWithFormat:@"%@ %@",
						(phoneticFirstName ? phoneticFirstName : firstName),
						(phoneticLastName ? phoneticLastName : lastName)];
				}
				break;
			case LastFirst:
				displayName = [NSString stringWithFormat:@"%@, %@",lastName,firstName]; 
				if (havePhonetic) {
					*phonetic = [NSString stringWithFormat:@"%@, %@",
						(phoneticLastName ? phoneticLastName : lastName),
						(phoneticFirstName ? phoneticFirstName : firstName)];
				}
				break;
			case LastFirstNoComma:
				displayName = [NSString stringWithFormat:@"%@ %@",lastName,firstName]; 
				if (havePhonetic) {
					*phonetic = [NSString stringWithFormat:@"%@ %@",
						(phoneticLastName ? phoneticLastName : lastName),
						(phoneticFirstName ? phoneticFirstName : firstName)];
				}					
				break;
			case First:
				//No action; handled before we reach the switch statement
				break;
		}
	}

	return displayName;
}

/*!
 * @brief Observe preference changes
 *
 * On first call, this method builds the addressBookDict. Subsequently, it rebuilds the dict only if the "create metaContacts"
 * option is toggled, as metaContacts are created while building the dict.
 *
 * If the user set a new image as a preference for an object, write it out to the contact's AB card if desired.
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
    if ([group isEqualToString:PREF_GROUP_ADDRESSBOOK]) {
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
		
		if (firstTime) {
			//Build the address book dictionary, which will also trigger metacontact grouping as appropriate
			[self rebuildAddressBookDict];
			
			//Register ourself as a listObject observer, which will update all objects
			[[adium contactController] registerListObjectObserver:self];
			
			//Now update from our "me" card information
		    [self updateSelfIncludingIcon:YES];	
			
		} else {
			/* We have a notification (so this isn't the first time through): */

			//If we weren't creating meta contacts before but we are now
			if (!oldCreateMetaContacts && createMetaContacts) {
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

    } else if (automaticSync && ([group isEqualToString:PREF_GROUP_USERICONS]) && object) {
		//Find the person
		ABPerson *person = [self searchForObject:object];
		
		if (person) {
			//Set the person's image to the inObject's serverside User Icon.
			NSData	*imageData = [object preferenceForKey:KEY_USER_ICON
													group:PREF_GROUP_USERICONS
									ignoreInheritedValues:YES];
			
			//If the pref is now nil, we should restore the address book back to the serverside icon if possible
			if (!imageData) {
				imageData = [[object statusObjectForKey:KEY_USER_ICON] TIFFRepresentation];
			}
			
			[person setImageData:imageData];
		}
	}
}

#pragma mark Image data

/*!
 * @brief Called when the address book completes an asynchronous image lookup
 *
 * @param inData NSData representing an NSImage
 * @param tag A tag indicating the lookup with which this call is associated. We use a tracking dictionary, trackingDict, to associate this int back to a usable object.
 */
- (void)consumeImageData:(NSData *)inData forTag:(int)tag
{
	if (tag == meTag) {
		[[adium preferenceController] setPreference:inData
											 forKey:KEY_USER_ICON 
											  group:GROUP_ACCOUNT_STATUS];
		meTag = -1;
		
	} else if (useABImages) {
		NSNumber		*tagNumber;
		NSImage			*image;
		AIListObject	*listObject;
//		AIListContact	*parentContact;
		NSString		*uniqueID;
		id				setOrObject;
		
		tagNumber = [NSNumber numberWithInt:tag];
		
		//Apply the image to the appropriate listObject
		image = (inData ? [[[NSImage alloc] initWithData:inData] autorelease] : nil);
		
		//Get the object from our tracking dictionary
		setOrObject = [trackingDict objectForKey:tagNumber];
		
		if ([setOrObject isKindOfClass:[AIListObject class]]) {
			listObject = (AIListObject *)setOrObject;
			
			//Apply the image at the appropriate priority
			[listObject setDisplayUserIcon:image
								 withOwner:self
							 priorityLevel:(preferAddressBookImages ? High_Priority : Low_Priority)];

			/*
			parentContact = [listObject parentContact];
			 */
			
		} else /*if ([setOrObject isKindOfClass:[NSSet class]])*/{
			NSEnumerator	*enumerator;
//			BOOL			checkedForMetaContact = NO;

			//Apply the image to each listObject at the appropriate priority
			enumerator = [(NSSet *)setOrObject objectEnumerator];
			while ((listObject = [enumerator nextObject])) {
				
				/*
				//These objects all have the same unique ID so will all also have the same meta contact; just check once
				if (!checkedForMetaContact) {
					parentContact = [listObject parentContact];
					if (parentContact == listObject) parentContact = nil;
					checkedForMetaContact = YES;
				}
				*/
				
				[listObject setDisplayUserIcon:image
									 withOwner:self
								 priorityLevel:(preferAddressBookImages ? High_Priority : Low_Priority)];
			}
		}
		
		/*
		if (parentContact) {
			[parentContact setDisplayUserIcon:image
									withOwner:self
								priorityLevel:(preferAddressBookImages ? High_Priority : Low_Priority)];			
		}
		*/
		
		//No further need for the dictionary entries
		[trackingDict removeObjectForKey:tagNumber];
		
		if ((uniqueID = [trackingDictTagNumberToPerson objectForKey:tagNumber])) {
			[trackingDictPersonToTagNumber removeObjectForKey:uniqueID];
			[trackingDictTagNumberToPerson removeObjectForKey:tagNumber];
		}
	}
}

/*!
 * @brief Queue an asynchronous image fetch for person associated with inObject
 *
 * Image lookups are done asynchronously.  This allows other processing to be done between image calls, improving the perceived
 * speed.  [Evan: I have seen one instance of this being problematic. My localhost loop was broken due to odd network problems,
 *			and the asynchronous lookup therefore hung the problem.  Submitted as radar 3977541.]
 *
 * We load from the same ABPerson for multiple AIListObjects, one for each service/UID combination times
 * the number of accounts on that service.  We therefore aggregate the lookups to lower the address book search
 * and image/data creation overhead.
 *
 * @param person The ABPerson to fetch the image from
 * @pram inObject The AIListObject with which to ultimately associate the image
 */
- (void)queueDelayedFetchOfImageForPerson:(ABPerson *)person object:(AIListObject *)inObject
{
	int				tag;
	NSNumber		*tagNumber;
	NSString		*uniqueId;
	
	uniqueId = [person uniqueId];
	
	//Check if we already have a tag for the loading of another object with the same
	//internalObjectID
	if ((tagNumber = [trackingDictPersonToTagNumber objectForKey:uniqueId])) {
		id				previousValue;
		NSMutableSet	*objectSet;
		
		previousValue = [trackingDict objectForKey:tagNumber];
		
		if ([previousValue isKindOfClass:[AIListObject class]]) {
			//If the old value is just a listObject, create an array with the old object
			//and the new object
			objectSet = [NSMutableSet setWithObjects:previousValue,inObject,nil];
			
			//Store the array in the tracking dict
			[trackingDict setObject:objectSet forKey:tagNumber];
			
		} else /*if ([previousValue isKindOfClass:[NSMutableArray class]])*/{
			//Add the new object to the previously-created array
			[(NSMutableSet *)previousValue addObject:inObject];
		}
		
	} else {
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
/*!
 * @brief Find an ABPerson corresponding to an AIListObject
 *
 * @param inObject The object for which it search
 * @result An ABPerson is one is found, or nil if none is found
 */
- (ABPerson *)searchForObject:(AIListObject *)inObject
{
	ABPerson	*person = nil;
	NSString	*uniqueID = [inObject preferenceForKey:KEY_AB_UNIQUE_ID group:PREF_GROUP_ADDRESSBOOK];
	ABRecord	*record = nil;
	
	if (uniqueID)
		record = [sharedAddressBook recordForUniqueId:uniqueID];
	
	if (record) {
		person = (ABPerson *)record;
	} else {
		if ([inObject isKindOfClass:[AIMetaContact class]]) {
			NSEnumerator	*enumerator;
			AIListContact	*listContact;
			
			//Search for an ABPerson for each listContact within the metaContact; first one we find is
			//the lucky winner.
			enumerator = [[(AIMetaContact *)inObject listContacts] objectEnumerator];
			while ((listContact = [enumerator nextObject]) && (person == nil)) {
				person = [self searchForObject:listContact];
			}
			
		} else {
			NSString		*UID = [inObject UID];
			NSString		*serviceID = [[inObject service] serviceID];
			
			person = [self _searchForUID:UID serviceID:serviceID];
			
			//If we don't find anything yet and inObject is an AIM account, try again using the ICQ property; ICQ, try again using AIM
			if (!person) {
				if ([serviceID isEqualToString:@"AIM"]) {
					person = [self _searchForUID:UID serviceID:@"ICQ"];
				} else if ([serviceID isEqualToString:@"ICQ"]) {
					person = [self _searchForUID:UID serviceID:@"AIM"];
				}
			}
		}
	}
	return person;
}

/*!
 * @brief Find an ABPerson for a given UID and serviceID combination
 * 
 * Uses our addressBookDict cache created in rebuildAddressBook.
 *
 * @param UID The UID for the contact
 * @param serviceID The serviceID for the contact
 * @result A corresponding <tt>ABPerson</tt>
 */
- (ABPerson *)_searchForUID:(NSString *)UID serviceID:(NSString *)serviceID
{
	ABPerson		*person = nil;
	NSDictionary	*dict;
	
	if ([serviceID isEqualToString:@"Mac"]) {
		dict = [addressBookDict objectForKey:@"AIM"];

	} else if ([serviceID isEqualToString:@"GTalk"]) {
		dict = [addressBookDict objectForKey:@"Jabber"];

	} else {
		dict = [addressBookDict objectForKey:serviceID];
	} 
	
	if (dict) {
		NSString *uniqueID = [dict objectForKey:[UID compactedString]];
		if (uniqueID) {
			person = (ABPerson *)[sharedAddressBook recordForUniqueId:uniqueID];
		}
	}
	
	return person;
}

#pragma mark Address book changed
/*!
 * @brief Address book changed externally
 *
 * As a result we add/remove people to/from our address book dictionary cache and update all contacts based on it
 */
- (void)addressBookChanged:(NSNotification *)notification
{
	id addedPeopleUIDs = nil;
	id modifiedPeopleUIDs = nil;
	id deletedPeopleUIDs = nil;
	
	//Delay listObjectNotifications to speed up metaContact creation
	[[adium contactController] delayListObjectNotifications];
	
	//In case of a single person, these are NSStrings, and in case of more then one, they are
	//Arrays containing NSStrings.
	addedPeopleUIDs = [[notification userInfo] objectForKey:kABInsertedRecords];
	modifiedPeopleUIDs = [[notification userInfo] objectForKey:kABUpdatedRecords];
	deletedPeopleUIDs = [[notification userInfo] objectForKey:kABDeletedRecords];
	
	if (addedPeopleUIDs) {
		if ([addedPeopleUIDs isKindOfClass:[NSArray class]])
			//We are dealing with multiple records
			[self addToAddressBookDict:[sharedAddressBook peopleFromUniqueIDs:addedPeopleUIDs]];
		else
			//We have only one record
			[self addToAddressBookDict:[NSArray arrayWithObject:(ABPerson *)[sharedAddressBook recordForUniqueId:addedPeopleUIDs]]];
	}
	
	if (modifiedPeopleUIDs) {
		if ([modifiedPeopleUIDs isKindOfClass:[NSArray class]]) {
			//We are dealing with multiple records
			[self removeFromAddressBookDict:modifiedPeopleUIDs];
			[self addToAddressBookDict:[sharedAddressBook peopleFromUniqueIDs:modifiedPeopleUIDs]];
		} else {
			//We have only one record
			[self removeFromAddressBookDict:[NSArray arrayWithObject:modifiedPeopleUIDs]];
			[self addToAddressBookDict:[NSArray arrayWithObject:(ABPerson *)[sharedAddressBook recordForUniqueId:modifiedPeopleUIDs]]];
		}
	}
	
	if (deletedPeopleUIDs) {
		if ([deletedPeopleUIDs isKindOfClass:[NSArray class]])
			//We are dealing with multiple records
			[self removeFromAddressBookDict:deletedPeopleUIDs];
		else
			//We have only one record
			[self removeFromAddressBookDict:[NSArray arrayWithObject:deletedPeopleUIDs]];
	}
	
	//Stop delaying list object notifications since we are done
	[[adium contactController] endListObjectNotificationsDelay];
	
    [self updateAllContacts];
}

/*!
 * @brief Update all existing contacts and accounts
 */
- (void)updateAllContacts
{
	[[adium contactController] updateAllListObjectsForObserver:self];
    [self updateSelfIncludingIcon:YES];
}

/*!
 * @brief Account list changed: Update all existing accounts
 */
- (void)accountListChanged:(NSNotification *)notification
{
	[self updateSelfIncludingIcon:NO];
}

/*!
 * @brief Update all existing accounts
 *
 * We use the "me" card to determine the default icon and account display name
 */
- (void)updateSelfIncludingIcon:(BOOL)includeIcon
{
	AI_DURING 
        //Begin loading image data for the "me" address book entry, if one exists
        ABPerson *me;
        if ((me = [sharedAddressBook me])) {
			
			//Default buddy icon
			if (includeIcon) {
				//Begin the image load
				meTag = [me beginLoadingImageDataForClient:self];
			}
			
			//Set account display names
			if (enableImport) {
				NSEnumerator	*servicesEnumerator = [[serviceDict allKeys] objectEnumerator];
				NSString		*serviceID;
				NSString		*myDisplayName, *myPhonetic = nil;
				
				myDisplayName = [self nameForPerson:me phonetic:&myPhonetic];
				
				//Check for each service the address book supports
				while ((serviceID = [servicesEnumerator nextObject])) {
					NSString		*addressBookKey = [serviceDict objectForKey:serviceID];
					ABMultiValue	*names = [me valueForProperty:addressBookKey];
					
					if ([serviceID isEqualToString:@"AIM"] || [serviceID isEqualToString:@"ICQ"]) {
						serviceID = @"AIM-compatible";
					}
					
					NSEnumerator	*accountsArray = [[[adium accountController] accounts] objectEnumerator];
					AIAccount		*account;
					
					//Look at each account on this service, searching for one a matching UID
					while ((account = [accountsArray nextObject])) {
						
						if ([[[account service] serviceClass] isEqualToString:serviceID]) {
							//An ABPerson may have multiple names on a given service; iterate through them
							NSString		*accountUID = [[account UID] compactedString];
							int				nameCount = [names count];
							int				i;
							
							for (i=0 ; i<nameCount ; i++) {
								if ([accountUID isEqualToString:[[names valueAtIndex:i] compactedString]]) {
									[[account displayArrayForKey:@"Display Name"] setObject:myDisplayName
																				  withOwner:self
																			  priorityLevel:Low_Priority];
									
									if (myPhonetic) {
										[[account displayArrayForKey:@"Phonetic Name"] setObject:myPhonetic
																					   withOwner:self
																				   priorityLevel:Low_Priority];										
									}									
								}
							}
						}
					}
				}
			}
        }
	AI_HANDLER
		NSLog(@"ABIntegration: Caught %@: %@", [localException name], [localException reason]);
	AI_ENDHANDLER
}

#pragma mark Address book caching
/*!
 * @brief rebuild our address book lookup dictionary
 */
- (void)rebuildAddressBookDict
{
	//Delay listObjectNotifications to speed up metaContact creation
	[[adium contactController] delayListObjectNotifications];
	
	[addressBookDict release]; addressBookDict = [[NSMutableDictionary alloc] init];
	
	[self addToAddressBookDict:[sharedAddressBook people]];

	//Stop delaying list object notifications since we are done
	[[adium contactController] endListObjectNotificationsDelay];
}

/*!
 * @brief add people to our address book lookup dictionary
 *
 * Rather than continually searching the address book, a lookup dictionary addressBookDict provides an quick and easy
 * way to look up a unique record ID for an ABPerson based on the service and UID of a contact. addressBookDict contains
 * NSDictionary objects keyed by service ID. Each of these NSDictionary objects contains unique record IDs keyed by compacted
 * (that is, no spaces and no all lowercase) UID. This means we can search while ignoring spaces, which normal AB searching
 * does not allow.
 *
 * In the process of building we look for cards which have multiple screen names listed and, if desired, automatically
 * create metaContacts baesd on this information.
 */
- (void)addToAddressBookDict:(NSArray *)people
{
	NSEnumerator		*peopleEnumerator;
	NSArray				*allServiceKeys;
	ABPerson			*person;
	
	allServiceKeys = [serviceDict allKeys];
	
	peopleEnumerator = [people objectEnumerator];
	while ((person = [peopleEnumerator nextObject])) {
		
		NSEnumerator		*servicesEnumerator = [allServiceKeys objectEnumerator];
		NSString			*serviceID;
		
		NSMutableArray		*UIDsArray = [NSMutableArray array];
		NSMutableArray		*servicesArray = [NSMutableArray array];
		
		NSMutableDictionary	*dict;
		ABMultiValue		*emails;
		int					i, emailsCount;
		
		//An ABPerson may have multiple emails; iterate through them looking for @mac.com addresses
		{
			emails = [person valueForProperty:kABEmailProperty];
			emailsCount = [emails count];
			
			for (i = 0; i < emailsCount ; i++) {
				NSString	*email;
				
				email = [emails valueAtIndex:i];
				if ([email hasSuffix:@"@mac.com"]) {
					
					//@mac.com UIDs go into the AIM dictionary
					if (!(dict = [addressBookDict objectForKey:@"AIM"])) {
						dict = [[[NSMutableDictionary alloc] init] autorelease];
						[addressBookDict setObject:dict forKey:@"AIM"];
					}
					
					[dict setObject:[person uniqueId] forKey:email];
					
					//Internally we distinguish them as .Mac addresses (for metaContact purposes below)
					[UIDsArray addObject:email];
					[servicesArray addObject:@"Mac"];
				}
			}
		}
		
		//Now go through the instant messaging keys
		while ((serviceID = [servicesEnumerator nextObject])) {
			NSString				*addressBookKey;
			ABMultiValue			*names;
			int						nameCount;
			
			BOOL					isOSCAR = ([serviceID isEqualToString:@"AIM"] || 
											   [serviceID isEqualToString:@"ICQ"]);
			BOOL					isJabber = [serviceID isEqualToString:@"Jabber"];

			if (!(dict = [addressBookDict objectForKey:serviceID])) {
				dict = [[[NSMutableDictionary alloc] init] autorelease];
				[addressBookDict setObject:dict forKey:serviceID];
			}
			
			addressBookKey = [serviceDict objectForKey:serviceID];
			
			//An ABPerson may have multiple names; iterate through them
			names = [person valueForProperty:addressBookKey];
			nameCount = [names count];
			
			for (i = 0 ; i < nameCount ; i++) {
				NSString	*UID = [[names valueAtIndex:i] compactedString];
				if ([UID length]) {
					[dict setObject:[person uniqueId] forKey:UID];
					
					[UIDsArray addObject:UID];
					
					if (isOSCAR) {
						/* If we are on an OSCAR service we need to resolve our serviceID into the appropriate string
						 * because we may have a .Mac, an ICQ, or an AIM name in the field
						 */
						const char	firstCharacter = [UID characterAtIndex:0];
						
						//Determine service based on UID
						if ([UID hasSuffix:@"@mac.com"]) {
							serviceID = @"Mac";
						} else if (firstCharacter >= '0' && firstCharacter <= '9') {
							serviceID = @"ICQ";
						} else {
							serviceID = @"AIM";
						}
					} else if (isJabber) {
						/* If we are on the Jabber server, we need to distinguish between Google Talk (GTalk) and the
						 * rest of the Jabber world. serviceID is already Jabber, so we only need to change if we
						 * have a GTalk UID.
						 */
						if ([UID hasSuffix:@"@gmail.com"] ||
							[UID hasSuffix:@"@googlemail.com"]) {
							serviceID = @"GTalk";
						}
					}
					
					[servicesArray addObject:serviceID];
				}
			}
		}
		
		if (([UIDsArray count] > 1) && createMetaContacts) {
			/* Got a record with multiple names. Group the names together, adding them to the meta contact. */
			[[adium contactController] groupUIDs:UIDsArray 
									 forServices:servicesArray];
		}
	}
}

/*!
 * @brief remove people from our address book lookup dictionary
 */
- (void)removeFromAddressBookDict:(NSArray *)UIDs
{
	NSEnumerator		*UIDsEnumerator;
	NSArray				*allServiceKeys;
	NSString			*UID;
	
	allServiceKeys = [serviceDict allKeys];
	
	UIDsEnumerator = [UIDs objectEnumerator];
	while ((UID = [UIDsEnumerator nextObject])) {
		
		NSEnumerator		*servicesEnumerator = [allServiceKeys objectEnumerator];
		NSString			*serviceID;
		NSMutableDictionary	*dict;
		
		//The same person may have multiple services; iterate through them and remove each one.
		while ((serviceID = [servicesEnumerator nextObject])) {
			NSEnumerator *keysEnumerator;
			NSString *key;
			
			dict = [addressBookDict objectForKey:serviceID];
			
			keysEnumerator = [[dict allKeysForObject:UID] objectEnumerator];
			
			//The same person may have multiple accounts from the same service; we should remove them all.
			while ((key = [keysEnumerator nextObject])) {
				[dict removeObjectForKey:key];
			}
		}
	}	
}

#pragma mark AB contextual menu
/*!
 * @brief Validate menu item
 */
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	if ([self searchForObject:[[adium menuController] currentContextMenuObject]])
		return YES;
	else
		return NO;
}

/*!
 * @brief Shows the selected contact in Address Book
 */
- (void)showInAddressBook
{
	ABPerson *selectedPerson = [self searchForObject:[[adium menuController] currentContextMenuObject]];
	NSString *url = [NSString stringWithFormat:@"addressbook://%@", [selectedPerson uniqueId]];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

/*!
 * @brief Edits the selected contact in Address Book
 */
- (void)editInAddressBook
{
	ABPerson *selectedPerson = [self searchForObject:[[adium menuController] currentContextMenuObject]];
	NSString *url = [NSString stringWithFormat:@"addressbook://%@?edit", [selectedPerson uniqueId]];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

@end
