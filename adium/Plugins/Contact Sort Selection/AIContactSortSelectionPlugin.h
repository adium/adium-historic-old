//
//  AIContactSortSelectionPlugin.h
//  Adium
//
//  Created by Adam Iser on Sun Feb 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>
#import "AIAdium.h"

#define PREF_GROUP_CONTACT_SORTING		@"Sorting"
#define KEY_CURRENT_SORT_MODE_IDENTIFIER	@"Sort Mode"

@class AIContactSortPreferences;

@interface AIContactSortSelectionPlugin : AIPlugin {

    AIContactSortPreferences	*preferences;
    
}

@end
