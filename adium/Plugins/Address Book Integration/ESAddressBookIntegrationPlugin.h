//
//  ESAddressBookIntegrationPlugin.h
//  Adium XCode
//
//  Created by Evan Schoenberg on Wed Nov 19 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import "ESAddressBookIntegrationAdvancedPreferences.h"

#define PREF_GROUP_ADDRESSBOOK  @"Address Book"
#define KEY_AB_DISPLAYFORMAT    @"AB Display Format"
#define KEY_AB_IMAGE_SYNC       @"AB Image Sync"
#define KEY_AB_ENABLE_IMAGES    @"AB Enable Images"

typedef enum {
    None = 0,
    FirstLast,
    First,
    LastFirst
} NameStyle;


@interface ESAddressBookIntegrationPlugin : AIPlugin <AIListObjectObserver, ABImageClient> {

    ESAddressBookIntegrationAdvancedPreferences *advancedPreferences;
    
    NSDictionary        *propertyDict;
    ABAddressBook       *sharedAddressBook;
    NSMutableDictionary *trackingDict;
    
    int                 displayFormat;
    bool                enableImages;
    bool                automaticSync;
}

@end
