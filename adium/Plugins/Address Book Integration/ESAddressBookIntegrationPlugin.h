//
//  ESAddressBookIntegrationPlugin.h
//  Adium XCode
//
//  Created by Evan Schoenberg on Wed Nov 19 2003.
//

#import <AddressBook/AddressBook.h>
#import "ESAddressBookIntegrationAdvancedPreferences.h"

#define PREF_GROUP_ADDRESSBOOK  @"Address Book"
#define KEY_AB_DISPLAYFORMAT    @"AB Display Format"
#define KEY_AB_IMAGE_SYNC       @"AB Image Sync"
#define KEY_AB_ENABLE_IMAGES    @"AB Enable Images"
#define KEY_AB_USE_NICKNAME     @"AB Use NickName"

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
    bool                useNickName;
    bool                enableImages;
    bool                automaticSync;
}

@end
