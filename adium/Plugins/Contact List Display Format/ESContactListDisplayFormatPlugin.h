//
//  ESContactListDisplayFormat.h
//  Adium
//
//  Created by Evan Schoenberg on Mon Aug 11 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "AICustomFormatTextView.h"
#import "ESContactListDisplayFormatPreferences.h"

#define	PREF_GROUP_DISPLAYFORMAT		@"Display Format"		//Preference group to store aliases in
@class ESContactListDisplayFormatPlugin;


@interface ESContactListDisplayFormatPlugin : AIPlugin <AIListObjectObserver> {

    NSString					*displayFormat;
    unsigned int 					keyWordLocation[100];
    NSScanner					*theScanner;
    int						numberOfKeywords;
    
    ESContactListDisplayFormatPreferences	*prefs;

    AIListObject				*activeContactObject;
}

@end

