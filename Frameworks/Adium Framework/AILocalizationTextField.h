//
//  AILocalizationTextField.h
//  Adium
//
//  Created by Evan Schoenberg on 11/29/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AILocalizationTextField : NSTextField {
	NSRect	originalFrame;
	
	IBOutlet	NSWindow	*window_anchorOnLeftSide;
	IBOutlet	NSView		*view_anchorToLeftSide;
	
	IBOutlet	NSView		*view_anchorToRightSide;
}

@end
