//
//  AIVolumeControlPreferences.h
//  Adium
//
//  Created by Adam Iser on Wed Apr 16 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AIVolumeControlPreferences : NSObject {
    AIAdium				*owner;

    IBOutlet	NSView			*view_prefView;
    IBOutlet	NSSlider		*slider_volume;

    NSDictionary		*preferenceDict;
}

+ (AIVolumeControlPreferences *)volumeControlPreferencesWithOwner:(id)inOwner;
- (IBAction)selectVolume:(id)sender;

@end
