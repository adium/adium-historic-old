//
//  ESAddressBookIntegrationPlugin.h
//  Adium XCode
//
//  Created by Evan Schoenberg on Wed Nov 19 2003.
//

#import <AddressBook/AddressBook.h>
#import "ESAddressBookIntegrationAdvancedPreferences.h"

#define PREF_GROUP_ADDRESSBOOK  @"Address Book"
#define KEY_AB_ENABLE_IMPORT	@"AB Enable Import"
#define KEY_AB_DISPLAYFORMAT    @"AB Display Format"
#define KEY_AB_IMAGE_SYNC       @"AB Image Sync"
#define KEY_AB_ENABLE_IMAGES    @"AB Enable Images"
#define KEY_AB_USE_NICKNAME     @"AB Use NickName"
#define AB_DISPLAYFORMAT_DEFAULT_PREFS @"AB Display Format Defaults"

typedef enum {
    None = 0,
    FirstLast,
    First,
    LastFirst,
} NameStyle;


@interface ESAddressBookIntegrationPlugin : AIPlugin <AIListObjectObserver, ABImageClient> {

    ESAddressBookIntegrationAdvancedPreferences *advancedPreferences;
    
    NSDictionary        *propertyDict;
    ABAddressBook       *sharedAddressBook;
    NSMutableDictionary *trackingDict;
    int                 meTag;
    
    int                 displayFormat;
	bool				enableImport;
    bool                useNickName;
    bool                automaticSync;
}

@end
