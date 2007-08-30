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

#import "ESAddressBookIntegrationAdvancedPreferences.h"
#import <AddressBook/AddressBook.h>
#import <Adium/AIPlugin.h>
#import <Adium/AIContactControllerProtocol.h>

#define PREF_GROUP_ADDRESSBOOK					@"Address Book"
#define KEY_AB_ENABLE_IMPORT					@"AB Enable Import"
#define KEY_AB_DISPLAYFORMAT					@"AB Display Format"
#define KEY_AB_IMAGE_SYNC						@"AB Image Sync"
#define KEY_AB_NOTE_SYNC						@"AB Note Sync"
#define KEY_AB_USE_IMAGES						@"AB Use AB Images"
#define KEY_AB_USE_NICKNAME						@"AB Use NickName"
#define KEY_AB_USE_MIDDLE						@"AB Use Middle Name"
#define KEY_AB_PREFER_ADDRESS_BOOK_IMAGES		@"AB Prefer AB Images"
#define	KEY_AB_CREATE_METACONTACTS				@"AB Create MetaContacts"
#define KEY_AB_UNIQUE_ID						@"AB Unique ID"

#define AB_DISPLAYFORMAT_DEFAULT_PREFS			@"AB Display Format Defaults"

@class AIService;

typedef enum {
	FirstLast = 0,
    First,
	LastFirst,
	LastFirstNoComma
} NameStyle;

@interface ESAddressBookIntegrationPlugin : AIPlugin <AIListObjectObserver, ABImageClient> {

    ESAddressBookIntegrationAdvancedPreferences *advancedPreferences;
    
	NSMutableDictionary	*addressBookDict;
	
	NSMutableArray		*listObjectArrayForImageData;
	NSMutableArray		*personArrayForImageData;
	NSTimer				*imageLookupTimer;
    NSMutableDictionary *trackingDict;
	NSMutableDictionary *trackingDictPersonToTagNumber;
	NSMutableDictionary *trackingDictTagNumberToPerson;
	
	NSMenuItem			*showInABContextualMenuItem;
	NSMenuItem			*editInABContextualMenuItem;
	NSMenuItem			*addToABContexualMenuItem;

    int                 meTag;
    
    int                 displayFormat;
    BOOL                enableImport;
    BOOL                useNickName;
	BOOL				useMiddleName;
    BOOL                automaticSync;
    BOOL                preferAddressBookImages;
    BOOL                useABImages;
	BOOL				createMetaContacts;
}

+ (AIService *)serviceFromProperty:(NSString *)property;

+ (NSString *)propertyFromService:(AIService *)service;

@end
