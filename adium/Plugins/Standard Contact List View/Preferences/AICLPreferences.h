//
//  AICLPreferences.h
//  Adium
//
//  Created by Vinay Venkatesh on Wed Dec 18 2002.
//  Copyright (c) 2002 Vinay Venkatesh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define CL_PREFERENCE_GROUP		@"Contact List Preferences"
#define CL_DEFAULT_FONT			@"Default Font"
#define CL_ENABLE_GRID			@"Enable Grid"
#define CL_ALTERNATING_GRID		@"Alternating Grid"
#define CL_BACKGROUND_COLOR		@"Background Color"
#define CL_GRID_COLOR			@"Grid Color"
#define CL_OPACITY				@"Opacity"

@interface AICLPreferences : AIPlugin {
    id	prefView;
    
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
}
- (void) initialize: (id) foo;

- (void) fontPopUps: (id) sender;
- (void) gridOptions: (id) sender;
- (void) colorAndOpacity: (id) sender;
@end
