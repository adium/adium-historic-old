//
//  ESAddressBookIntegrationPlugin.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Nov 19 2003.
//

#import <AddressBook/AddressBook.h>
#import "ESAddressBookIntegrationAdvancedPreferences.h"

#define PREF_GROUP_ADDRESSBOOK				@"Address Book"
#define KEY_AB_ENABLE_IMPORT				@"AB Enable Import"
#define KEY_AB_DISPLAYFORMAT				@"AB Display Format"
#define KEY_AB_IMAGE_SYNC       			@"AB Image Sync"
#define KEY_AB_NOTE_SYNC                                @"AB Note Sync"
#define KEY_AB_USE_IMAGES                               @"AB Use AB Images"
#define KEY_AB_USE_NICKNAME                             @"AB Use NickName"
#define KEY_AB_PREFER_ADDRESS_BOOK_IMAGES               @"AB Prefer AB Images"

#define AB_DISPLAYFORMAT_DEFAULT_PREFS                  @"AB Display Format Defaults"

typedef enum {
    FirstLast,
    First,
    LastFirst,
} NameStyle;

@interface ESAddressBookIntegrationPlugin : AIPlugin <AIListObjectObserver, ABImageClient> {

    ESAddressBookIntegrationAdvancedPreferences *advancedPreferences;
    
    NSDictionary        *serviceDict;
	NSMutableDictionary *addressBookDict;
    NSMutableDictionary *trackingDict;
    int                 meTag;
    
    int                 displayFormat;
    bool                enableImport;
    bool                useNickName;
    bool                automaticSync;
    bool                preferAddressBookImages;
    bool                useABImages;
}

@end
