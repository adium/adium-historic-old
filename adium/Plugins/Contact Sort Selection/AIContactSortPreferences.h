//
//  AIContactSortPreferences.h
//  Adium
//
//  Created by Adam Iser on Mon Feb 10 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium;

@interface AIContactSortPreferences : NSObject {
    IBOutlet	NSView			*view_prefView;
    IBOutlet	NSPopUpButton		*popUp_sortMode;
    IBOutlet	NSTextField		*textField_description;

    AIAdium			*owner;
    NSDictionary		*preferenceDict;
        
}

+ (AIContactSortPreferences *)contactSortPreferencesWithOwner:(id)inOwner;
- (IBAction)selectSortMode:(id)sender;

@end
