//
//  AICLPreferences.h
//  Adium
//
//  Created by Vinay Venkatesh on Wed Dec 18 2002.
//  Copyright (c) 2002 Vinay Venkatesh. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AICLPreferences : AIPlugin {
    id	prefView;
    
    id	fontPopUp;
    id	facePopUp;
    id	sizePopUp;

    id	enableGridSwitch;
    id	alternatingGridSwitch;
    id	opacitySlider;

    id	backgroundColorWell;
    id	alternatingColorWell;
}
- (void) initialize: (id) foo;

@end
