//
//  AISendingKeyPreferences.h
//  Adium
//
//  Created by Adam Iser on Sat Mar 01 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AISendingKeyPreferences : NSObject {
    IBOutlet	NSView		*view_prefView;
    IBOutlet	NSButton	*checkBox_sendOnEnter;
    IBOutlet	NSButton	*checkBox_sendOnReturn;

    AIAdium			*owner;
    NSDictionary		*preferenceDict;

}

+ (AISendingKeyPreferences *)sendingKeyPreferencesWithOwner:(id)inOwner;
- (IBAction)preferenceChanged:(id)sender;

@end
