//
//  AITextColorPreviewView.h
//  Adium
//
//  Created by Adam Iser on 8/14/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//


@interface AITextColorPreviewView : NSView {
	IBOutlet	NSColorWell		*textColor;
	IBOutlet	NSColorWell		*textShadowColor;
	IBOutlet	NSColorWell		*backgroundColor;
	IBOutlet	NSColorWell		*backgroundGradientColor;
	
	NSColor		*backColorOverride;
}

- (void)setBackColorOverride:(NSColor *)inColor;

@end
