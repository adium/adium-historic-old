//
//  AICLPreferences.h
//  Adium
//
//  Created by Vinay Venkatesh on Wed Dec 18 2002.
//  Copyright (c) 2002 Vinay Venkatesh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AICLPreferences : AIPlugin {
    IBOutlet	NSView			*view_prefView;

    IBOutlet	NSTextField		*textField_fontName;
    IBOutlet	NSButton		*checkBox_alternatingGrid;

    NSDictionary		*preferenceDict;
    
/*
    id	fontPopUp;
    id	facePopUp;
    id	sizePopUp;

    id	enableGridSwitch;
    id	alternatingGridSwitch;

    
    id	opacitySlider;
    id	opacityPercentLabel;

    id	backgroundColorWell;
    id	gridColorWell;
    id	gridColorLabel;

    AIPreferenceController*     preferenceController;
    AIPlugin	*parentPlugin;*/
}

+ (AICLPreferences *)contactListPreferencesWithOwner:(id)inOwner;
- (IBAction)setContactListFont:(id)sender;
- (IBAction)toggleAlternatingGrid:(id)sender;

    /*

- (void) initialize: (id) foo;

- (void) fontPopUps: (id) sender;
- (void) gridOptions: (id) sender;
- (void) colorAndOpacity: (id) sender;

- (void) setCLController: (id) foo;*/
@end
