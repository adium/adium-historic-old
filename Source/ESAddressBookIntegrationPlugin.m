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
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIMutableOwnerArray.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/OWAddressBookAdditions.h>
#import <AIUtilities/AIExceptionHandlingUtilities.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIService.h>

#define IMAGE_LOOKUP_INTERVAL   0.01
#define SHOW_IN_AB_CONTEXTUAL_MENU_TITLE AILocalizedString(@"Show In Address Book", "Show In Address Book Contextual Menu")
#define EDIT_IN_AB_CONTEXTUAL_MENU_TITLE AILocalizedString(@"Edit In Address Book", "Edit In Address Book Contextual Menu")
#define ADD_TO_AB_CONTEXTUAL_MENU_TITLE AILocalizedString(@"Add To Address Book", "Add To Address Book Contextual Menu")

#define CONTACT_ADDED_SUCCESS_TITLE		AILocalizedString(@"Success", "Title of a panel shown after adding successfully adding a contact to the address book.")
#define CONTACT_ADDED_SUCCESS_Message	AILocalizedString(@"%@ had been successfully added to the Address Book.\nWould you like to edit the card now?", nil)
#define CONTACT_ADDED_ERROR_TITLE		AILocalizedString(@"Error", nil)
#define CONTACT_ADDED_ERROR_Message		AILocalizedString(@"An error had occurred while adding %@ to the Address Book.", nil)

@interface ESAddressBookIntegrationPlugin(PRIVATE)
- (void)updateAllContacts;
- (void)updateSelfIncludingIcon:(BOOL)includeIcon;
- (void)preferencesChanged:(NSNotification *)notification;
- (NSString *)nameForPerson:(ABPerson *)person phonetic:(NSString **)phonetic;
- (ABPerson *)personForListObject:(AIListObject *)inObject;
- (ABPerson *)_searchForUID:(NSString *)UID serviceID:(NSString *)serviceID;
- (void)rebuildAddressBookDict;
- (void)queueDelayedFetchOfImageForPerson:(ABPerson *)person object:(AIListObject *)inObject;
- (void)showInAddressBook;
- (void)editInAddressBook;
- (void)addToAddressBookDict:(NSArray *)people;
- (void)removeFromAddressBookDict:(NSArray *)UIDs;
- (void)installAddressBookActions;
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
static	NSDictionary	*serviceDict = nil;

NSString* serviceIDForOscarUID(NSString *UID);
NSString* serviceIDForJabberUID(NSString *UID);

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
	
	//Create our contextual menus
	showInABContextualMenuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:SHOW_IN_AB_CONTEXTUAL_MENU_TITLE
																			   action:@selector(showInAddressBook)
																		keyEquivalent:@""] autorelease];
	[showInABContextualMenuItem setTarget:self];
	
	editInABContextualMenuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:EDIT_IN_AB_CONTEXTUAL_MENU_TITLE
																					   action:@selector(editInAddressBook)
																				keyEquivalent:@""] autorelease];
	[editInABContextualMenuItem setTarget:self];
	[editInABContextualMenuItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
	[editInABContextualMenuItem setAlternate:YES];
	
	addToABContexualMenuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ADD_TO_AB_CONTEXTUAL_MENU_TITLE
																					 action:@selector(addToAddressBook)
																			  keyEquivalent:@""] autorelease];
	[addToABContexualMenuItem setTarget:self];
	
	//Install our menues
	[[adium menuController] addContextualMenuItem:addToABContexualMenuItem toLocation:Context_Contact_Action];
	[[adium menuController] addContextualMenuItem:showInABContextualMenuItem toLocation:Context_Contact_Action];
	[[adium menuController] addContextualMenuItem:editInABContextualMenuItem toLocation:Context_Contact_Action];
	
	[self installAddressBookActions];
	
	//Wait for Adium to finish launching before we build the address book so the contact list will be ready
	[[adium notificationCenter] addObserver:self
								   selector:@selector(adiumFinishedLaunching:)
									   name:Adium_CompletedApplicationLoad
									 object:nil];
	[self updateSelfIncludingIcon:YES];
}

- (void)installAddressBookActions
{
	NSNumber		*installedActions = [[NSUserDefaults standardUserDefaults] objectForKey:@"Adium:Installed Adress Book Actions"];
	
	if (!installedActions || ![installedActions boolValue]) {
		NSEnumerator  *enumerator = [[NSArray arrayWithObjects:@"AIM", @"MSN", @"Yahoo", @"ICQ", @"Jabber", @"SMS", nil] objectEnumerator];
		NSString	  *name;
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSArray		  *libraryDirectoryArray;
		NSString	  *libraryDirectory, *pluginDirectory;

		libraryDirectoryArray = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
		if ([libraryDirectoryArray count]) {
			libraryDirectory = [libraryDirectoryArray objectAtIndex:0];

		} else {
			//Ridiculous safety since everyone should have a Library folder...
			libraryDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Library"];
			[fileManager createDirectoryAtPath:libraryDirectory attributes:nil];
		}

		pluginDirectory = [[libraryDirectory stringByAppendingPathComponent:@"Address Book Plug-Ins"] stringByAppendingPathComponent:@"/"];
		[fileManager createDirectoryAtPath:pluginDirectory attributes:nil];
		
		while ((name = [enumerator nextObject])) {
			NSString *fullName = [NSString stringWithFormat:@"AdiumAddressBookAction_%@",name];
			NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:fullName ofType:@"scpt"];

			if (path) {
				[fileManager copyPath:path
							   toPath:[pluginDirectory stringByAppendingPathComponent:[fullName stringByAppendingPathExtension:@"scpt"]]
							  handler:NULL];
				
				//Remove the old xtra if installed
				[fileManager trashFileAtPath:[pluginDirectory stringByAppendingPathComponent:
					[NSString stringWithFormat:@"%@-Adium.scpt",name]]];
			} else {
				NSLog(@"%@: Could not find %@",self, fullName);
			}
		}

		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES]
												  forKey:@"Adium:Installed Adress Book Actions"];
	}
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
        ABPerson *person = [self personForListObject:inObject];
		
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
			ABPerson *person = [self personForListObject:inObject];
			
			if (person && (person != [sharedAddressBook me])) {
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
	NSString *firstName, *middleName, *lastName, *phoneticFirstName, *phoneticLastName;	
	NSString *nickName;
	NSString *displayName = nil;
	
	firstName = [person valueForProperty:kABFirstNameProperty];
	middleName = [person valueForProperty:kABMiddleNameProperty];
	lastName = [person valueForProperty:kABLastNameProperty];
	phoneticFirstName = [person valueForProperty:kABFirstNamePhoneticProperty];
	phoneticLastName = [person valueForProperty:kABLastNamePhoneticProperty];
	
	//
	if (useMiddleName && middleName)
		firstName = [NSString stringWithFormat:@"%@ %@", firstName, middleName];

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
		useMiddleName = [[prefDict objectForKey:KEY_AB_USE_MIDDLE] boolValue];
		preferAddressBookImages = [[prefDict objectForKey:KEY_AB_PREFER_ADDRESS_BOOK_IMAGES] boolValue];
		useABImages = [[prefDict objectForKey:KEY_AB_USE_IMAGES] boolValue];

		createMetaContacts = [[prefDict objectForKey:KEY_AB_CREATE_METACONTACTS] boolValue];
		
		if (firstTime) {
			//Build the address book dictionary, which will also trigger metacontact grouping as appropriate
			[self rebuildAddressBookDict];
			
			//Register ourself as a listObject observer, which will update all objects
			[[adium contactController] registerListObjectObserver:self];
			
			//Now update from our "me" card information to apply to the accounts which loaded
		    [self updateSelfIncludingIcon:NO];	
			
		} else {
			//This isn't the first time through

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
		ABPerson *person = [self personForListObject:object];
		
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

/*!
 * @brief Returns the appropriate service for the property.
 *
 * @param property - an ABPerson property.
 */
+ (AIService *)serviceFromProperty:(NSString *)property
{
	AIService	*result = nil;
	AIAccountController *accountController = [[AIObject sharedAdiumInstance] accountController];
	
	if ([property isEqualToString:kABAIMInstantProperty])
		result = [accountController firstServiceWithServiceID:@"AIM"];
	else if ([property isEqualToString:kABICQInstantProperty])
		result = [accountController firstServiceWithServiceID:@"ICQ"];
	else if ([property isEqualToString:kABMSNInstantProperty])
		result = [accountController firstServiceWithServiceID:@"MSN"];
	else if ([property isEqualToString:kABJabberInstantProperty])
		result = [accountController firstServiceWithServiceID:@"Jabber"];
	else if ([property isEqualToString:kABYahooInstantProperty])
		result = [accountController firstServiceWithServiceID:@"Yahoo!"];

	return result;
}

/*!
 * @brief Returns the appropriate property for the service.
 */
+ (NSString *)propertyFromService:(AIService *)inService
{
	NSString *result;
	NSString *serviceID = [inService serviceID];

	result = [serviceDict objectForKey:serviceID];

	//Check for some special cases
	if (!result) {
		if ([serviceID isEqualToString:@"GTalk"]) {
			result = kABJabberInstantProperty;
		} else if ([serviceID isEqualToString:@"Mac"]) {
			result = kABAIMInstantProperty;
		}
	}
	
	return result;
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
											 forKey:KEY_DEFAULT_USER_ICON 
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
- (ABPerson *)personForListObject:(AIListObject *)inObject
{
	ABPerson	*person = nil;
	NSString	*uniqueID = [inObject preferenceForKey:KEY_AB_UNIQUE_ID group:PREF_GROUP_ADDRESSBOOK];
	ABRecord	*record = nil;
	
	if (uniqueID)
		record = [sharedAddressBook recordForUniqueId:uniqueID];
	
	if (record && [record isKindOfClass:[ABPerson class]]) {
		person = (ABPerson *)record;
	} else {
		if ([inObject isKindOfClass:[AIMetaContact class]]) {
			NSEnumerator	*enumerator;
			AIListContact	*listContact;
			
			//Search for an ABPerson for each listContact within the metaContact; first one we find is
			//the lucky winner.
			enumerator = [[(AIMetaContact *)inObject listContacts] objectEnumerator];
			while ((listContact = [enumerator nextObject]) && (person == nil)) {
				person = [self personForListObject:listContact];
			}
			
		} else {
			NSString		*UID = [inObject UID];
			NSString		*serviceID = [[inObject service] serviceID];
			
			person = [self _searchForUID:UID serviceID:serviceID];
			
			/* If we don't find anything yet, look at alternative service possibilities, AIM <--> ICQ,
			 */
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

- (NSSet *)contactsForPerson:(ABPerson *)person
{
	NSArray			*allServiceKeys = [serviceDict allKeys];
	NSString		*serviceID;
	NSMutableSet	*contactSet = [NSMutableSet set];
	NSEnumerator	*servicesEnumerator;
	ABMultiValue	*emails;
	int				i, emailsCount;

	//An ABPerson may have multiple emails; iterate through them looking for @mac.com addresses
	{
		emails = [person valueForProperty:kABEmailProperty];
		emailsCount = [emails count];
		
		for (i = 0; i < emailsCount ; i++) {
			NSString	*email;
			
			email = [emails valueAtIndex:i];
			if ([email hasSuffix:@"@mac.com"]) {
				//Retrieve all appropriate contacts
				NSSet	*contacts = [[adium contactController] allContactsWithService:[[adium accountController] firstServiceWithServiceID:@"Mac"]
																				  UID:email
																		 existingOnly:YES];

				//Add them to our set
				[contactSet unionSet:contacts];
			}
		}
	}
	
	//Now go through the instant messaging keys
	servicesEnumerator = [allServiceKeys objectEnumerator];
	while ((serviceID = [servicesEnumerator nextObject])) {
		NSString		*addressBookKey = [serviceDict objectForKey:serviceID];
		ABMultiValue	*names;
		int				nameCount;

		//An ABPerson may have multiple names; iterate through them
		names = [person valueForProperty:addressBookKey];
		nameCount = [names count];
		
		//Continue to the next serviceID immediately if no names are found
		if (nameCount == 0) continue;
		
		BOOL					isOSCAR = ([serviceID isEqualToString:@"AIM"] || 
										   [serviceID isEqualToString:@"ICQ"]);
		BOOL					isJabber = [serviceID isEqualToString:@"Jabber"];
		
		for (i = 0 ; i < nameCount ; i++) {
			NSString	*UID = [[names valueAtIndex:i] compactedString];
			if ([UID length]) {
				if (isOSCAR) {
					serviceID = serviceIDForOscarUID(UID);
					
				} else if (isJabber) {
					serviceID = serviceIDForJabberUID(UID);
				}
				
				NSSet	*contacts = [[adium contactController] allContactsWithService:[[adium accountController] firstServiceWithServiceID:serviceID]
																				  UID:UID
																		 existingOnly:YES];
				
				//Add them to our set
				[contactSet unionSet:contacts];
			}
		}
	}

	return contactSet;
}

#pragma mark Address book changed
/*!
 * @brief Address book changed externally
 *
 * As a result we add/remove people to/from our address book dictionary cache and update all contacts based on it
 */
- (void)addressBookChanged:(NSNotification *)notification
{
	/* In case of a single person, these will be NSStrings.
	 * In case of more then one, they are will be NSArrays containing NSStrings.
	 */	
	id				addedPeopleUniqueIDs, modifiedPeopleUniqueIDs, deletedPeopleUniqueIDs;
	NSMutableSet	*allModifiedPeople = [[NSMutableSet alloc] init];
	ABPerson		*me = [sharedAddressBook me];
	BOOL			modifiedMe = NO;;

	//Delay listObjectNotifications to speed up metaContact creation
	[[adium contactController] delayListObjectNotifications];

	//Addition of new records
	if ((addedPeopleUniqueIDs = [[notification userInfo] objectForKey:kABInsertedRecords])) {
		NSArray	*peopleToAdd;

		if ([addedPeopleUniqueIDs isKindOfClass:[NSArray class]]) {
			//We are dealing with multiple records
			peopleToAdd = [sharedAddressBook peopleFromUniqueIDs:(NSArray *)addedPeopleUniqueIDs];
		} else {
			//We have only one record
			peopleToAdd = [NSArray arrayWithObject:(ABPerson *)[sharedAddressBook recordForUniqueId:addedPeopleUniqueIDs]];
		}

		[allModifiedPeople addObjectsFromArray:peopleToAdd];
		[self addToAddressBookDict:peopleToAdd];
	}
	
	//Modification of existing records
	if ((modifiedPeopleUniqueIDs = [[notification userInfo] objectForKey:kABUpdatedRecords])) {
		NSArray	*peopleToAdd;

		if ([modifiedPeopleUniqueIDs isKindOfClass:[NSArray class]]) {
			//We are dealing with multiple records
			[self removeFromAddressBookDict:modifiedPeopleUniqueIDs];
			peopleToAdd = [sharedAddressBook peopleFromUniqueIDs:modifiedPeopleUniqueIDs];
		} else {
			//We have only one record
			[self removeFromAddressBookDict:[NSArray arrayWithObject:modifiedPeopleUniqueIDs]];
			peopleToAdd = [NSArray arrayWithObject:(ABPerson *)[sharedAddressBook recordForUniqueId:modifiedPeopleUniqueIDs]];
		}
		
		[allModifiedPeople addObjectsFromArray:peopleToAdd];
		[self addToAddressBookDict:peopleToAdd];
	}
	
	//Deletion of existing records
	if ((deletedPeopleUniqueIDs = [[notification userInfo] objectForKey:kABDeletedRecords])) {
		if ([deletedPeopleUniqueIDs isKindOfClass:[NSArray class]]) {
			//We are dealing with multiple records
			[self removeFromAddressBookDict:deletedPeopleUniqueIDs];
		} else {
			//We have only one record
			[self removeFromAddressBookDict:[NSArray arrayWithObject:deletedPeopleUniqueIDs]];
		}
		
		//Note: We have no way of retrieving the records of people who were removed, so we really can't do much here.
	}
	
	NSEnumerator	*peopleEnumerator;
	ABPerson		*person;
	
	//Do appropriate updates for each updated ABPerson
	peopleEnumerator = [allModifiedPeople objectEnumerator];
	while ((person = [peopleEnumerator nextObject])) {
		if (person == me) {
			modifiedMe = YES;
		}

		//It's tempting to not do this if (person == me), but the 'me' contact may also be in the contact list
		[[adium contactController] updateContacts:[self contactsForPerson:person]
									  forObserver:self];
	}

	//Update us if appropriate
	if (modifiedMe) {
		[self updateSelfIncludingIcon:YES];
	}
	
	//Stop delaying list object notifications since we are done
	[[adium contactController] endListObjectNotificationsDelay];
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
				NSString		*myDisplayName, *myPhonetic = nil;
				
				myDisplayName = [self nameForPerson:me phonetic:&myPhonetic];
				
				NSEnumerator	*accountsArray = [[[adium accountController] accounts] objectEnumerator];
				AIAccount		*account;
				
				while ((account = [accountsArray nextObject])) {
					[[account displayArrayForKey:@"Display Name"] setObject:myDisplayName
																  withOwner:self
															  priorityLevel:Low_Priority];
					
					if (myPhonetic) {
						[[account displayArrayForKey:@"Phonetic Name"] setObject:myPhonetic
																	   withOwner:self
																   priorityLevel:Low_Priority];										
					}									
				}
				
				[[adium preferenceController] registerDefaults:[NSDictionary dictionaryWithObject:[[NSAttributedString stringWithString:myDisplayName] dataRepresentation]
																						   forKey:KEY_ACCOUNT_DISPLAY_NAME]
													  forGroup:GROUP_ACCOUNT_STATUS];
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


/*
 * @brief Service ID for an OSCAR UID
 *
 * If we are on an OSCAR service we need to resolve our serviceID into the appropriate string
 * because we may have a .Mac, an ICQ, or an AIM name in the field
 */
NSString* serviceIDForOscarUID(NSString *UID)
{
	NSString	*serviceID;

	const char	firstCharacter = [UID characterAtIndex:0];
	
	//Determine service based on UID
	if ([UID hasSuffix:@"@mac.com"]) {
		serviceID = @"Mac";
	} else if (firstCharacter >= '0' && firstCharacter <= '9') {
		serviceID = @"ICQ";
	} else {
		serviceID = @"AIM";
	}
	
	return serviceID;
}

/*!
 * @brief Service ID for a Jabber UID
 *
 * If we are on the Jabber server, we need to distinguish between Google Talk (GTalk) and the
 * rest of the Jabber world. serviceID is already Jabber, so we only need to change if we
 * have a GTalk UID.
 */
NSString* serviceIDForJabberUID(NSString *UID)
{
	NSString	*serviceID;

	if ([UID hasSuffix:@"@gmail.com"] ||
		[UID hasSuffix:@"@googlemail.com"]) {
		serviceID = @"GTalk";

	} else {
		serviceID = @"Jabber";
	}
	
	return serviceID;
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
	NSArray				*allServiceKeys = [serviceDict allKeys];
	ABPerson			*person;
	
	peopleEnumerator = [people objectEnumerator];
	while ((person = [peopleEnumerator nextObject])) {
		NSEnumerator		*servicesEnumerator;
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
		servicesEnumerator = [allServiceKeys objectEnumerator];
		while ((serviceID = [servicesEnumerator nextObject])) {
			NSString			*addressBookKey = [serviceDict objectForKey:serviceID];
			ABMultiValue		*names;
			int					nameCount;

			//An ABPerson may have multiple names; iterate through them
			names = [person valueForProperty:addressBookKey];
			nameCount = [names count];
			
			//Continue to the next serviceID immediately if no names are found
			if (nameCount == 0) continue;
			
			//One or more names were found, so we'll need a dictionary
			if (!(dict = [addressBookDict objectForKey:serviceID])) {
				dict = [[NSMutableDictionary alloc] init];
				[addressBookDict setObject:dict forKey:serviceID];
				[dict release];
			}

			BOOL					isOSCAR = ([serviceID isEqualToString:@"AIM"] || 
											   [serviceID isEqualToString:@"ICQ"]);
			BOOL					isJabber = [serviceID isEqualToString:@"Jabber"];

			for (i = 0 ; i < nameCount ; i++) {
				NSString	*UID = [[names valueAtIndex:i] compactedString];
				if ([UID length]) {
					[dict setObject:[person uniqueId] forKey:UID];
					
					[UIDsArray addObject:UID];
					
					if (isOSCAR) {
						serviceID = serviceIDForOscarUID(UID);
						
					} else if (isJabber) {
						serviceID = serviceIDForJabberUID(UID);
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
- (void)removeFromAddressBookDict:(NSArray *)uniqueIDs
{
	NSEnumerator		*enumerator;
	NSArray				*allServiceKeys = [serviceDict allKeys];
	NSString			*uniqueID;
	
	enumerator = [uniqueIDs objectEnumerator];
	while ((uniqueID = [enumerator nextObject])) {
		NSEnumerator		*servicesEnumerator;
		NSString			*serviceID;
		NSMutableDictionary	*dict;
		
		//The same person may have multiple services; iterate through them and remove each one.
		servicesEnumerator = [allServiceKeys objectEnumerator];
		while ((serviceID = [servicesEnumerator nextObject])) {
			NSEnumerator *keysEnumerator;
			NSString *key;
			
			dict = [addressBookDict objectForKey:serviceID];
			
			keysEnumerator = [[dict allKeysForObject:uniqueID] objectEnumerator];
			
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
	BOOL	hasABEntry = ([self personForListObject:[[adium menuController] currentContextMenuObject]] != nil);
	BOOL	result = NO;
	
	if ([menuItem isEqual:showInABContextualMenuItem] || [menuItem isEqual:editInABContextualMenuItem])
		result = hasABEntry;
	else if ([menuItem isEqual:addToABContexualMenuItem])
		result = !hasABEntry;
	
	return result;
}

/*!
 * @brief Shows the selected contact in Address Book
 */
- (void)showInAddressBook
{
	ABPerson *selectedPerson = [self personForListObject:[[adium menuController] currentContextMenuObject]];
	NSString *url = [NSString stringWithFormat:@"addressbook://%@", [selectedPerson uniqueId]];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

/*!
 * @brief Edits the selected contact in Address Book
 */
- (void)editInAddressBook
{
	ABPerson *selectedPerson = [self personForListObject:[[adium menuController] currentContextMenuObject]];
	NSString *url = [NSString stringWithFormat:@"addressbook://%@?edit", [selectedPerson uniqueId]];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

- (void)addToAddressBook
{
	AIListObject			*contact = [[adium menuController] currentContextMenuObject];
	NSString				*serviceProperty = [ESAddressBookIntegrationPlugin propertyFromService:[contact service]];
	
	if (serviceProperty) {
		ABPerson				*person = [[ABPerson alloc] init];
		ABMutableMultiValue		*multiValue = [[ABMutableMultiValue alloc] init];
		NSString				*UID = [contact formattedUID];
		
		//Set the name
		[person setValue:[contact displayName] forKey:kABFirstNameProperty];
		[person setValue:[contact phoneticName] forKey:kABFirstNamePhoneticProperty];
		
		//Set the IM property
		[multiValue addValue:UID withLabel:serviceProperty];
		[person setValue:multiValue forKey:serviceProperty];
		
		//Set the image
		[person setImageData:[contact userIconData]];
		
		//Set the notes
		[person setValue:[contact notes] forKey:kABNoteProperty];
		
		//Add our newly created person to the AB database
		if ([sharedAddressBook addRecord:person] && [sharedAddressBook save]) {
			//Save the uid of the new person
			[contact setPreference:[person uniqueId]
							forKey:KEY_AB_UNIQUE_ID
							 group:PREF_GROUP_ADDRESSBOOK];
			
			//Ask the user whether it would like to edit the new contact
			int result = NSRunAlertPanel(CONTACT_ADDED_SUCCESS_TITLE,
										 CONTACT_ADDED_SUCCESS_Message,
										 AILocalizedString(@"Yes", nil),
										 AILocalizedString(@"No", nil), nil, UID);
			
			if (result == NSOKButton) {
				NSString *url = [[NSString alloc] initWithFormat:@"addressbook://%@?edit", [person uniqueId]];
				[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
				[url release];
			}
		} else {
			NSRunAlertPanel(CONTACT_ADDED_ERROR_TITLE, CONTACT_ADDED_ERROR_Message, nil, nil, nil);
		}
		
		//Clean up
		[multiValue release];
		[person release];
	}
}

@end
