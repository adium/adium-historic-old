//
//  AITextProfilesPlugin.h
//  Adium
//
//  Created by Adam Iser on Tue Jan 07 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@class AITextProfilePreferences, AIPreferenceViewController;

@interface AITextProfilesPlugin : AIPlugin <AIPreferenceViewControllerDelegate> {
    IBOutlet	NSView		*view_contactProfileInfoView;
    IBOutlet	NSTextView	*textView_contactProfile;
    
    AITextProfilePreferences		*preferences;

    AIPreferenceViewController		*contactProfileView;
    AIContactHandle			*activeContactObject;
}

@end
