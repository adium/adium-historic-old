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
#define ADDRESS_BOOK_FIRST_LAST 1
#define ADDRESS_BOOK_FIRST      2
#define ADDRESS_BOOK_LAST_FIRST 3
#define KEY_AB_IMAGE_SYNC       @"AB Image Sync"
#define ADDRESS_BOOK_SYNC_NO    0
#define ADDRESS_BOOK_SYNC_AUTO  1

@interface ESAddressBookIntegrationPlugin : AIPlugin <AIListObjectObserver, ABImageClient> {

    ESAddressBookIntegrationAdvancedPreferences *advancedPreferences;
    
    NSDictionary        *propertyDict;
    ABAddressBook       *sharedAddressBook;
    NSMutableDictionary *trackingDict;
    
    int                 displayFormat;
    int                 syncMethod;
}

@end
