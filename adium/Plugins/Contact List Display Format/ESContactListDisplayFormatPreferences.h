//
//  ESContactListDisplayFormatPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on Tue Aug 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "AICustomFormatTextView.h"

@interface ESContactListDisplayFormatPreferences : NSObject {
    IBOutlet 	AICustomFormatTextView		*textField_displayFormat;
    IBOutlet	NSView				*view_prefView;
        AIAdium					*owner;
        NSString				*displayFormat;

        AIListObject				*activeContactObject;
    
}
+ (ESContactListDisplayFormatPreferences *)contactListDisplayFormatPreferencesWithOwner:(id)inOwner;


@end
