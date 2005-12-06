//
//  SetupWizardBackgroundView.h
//  Adium
//
//  Created by Evan Schoenberg on 12/4/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SetupWizardBackgroundView : NSView {
	NSRect transparentRect;
	NSImage	*backgroundImage;
}

- (void)setBackgroundImage:(NSImage *)inImage;
- (void)setTransparentRect:(NSRect)inTransparentRect;

@end
