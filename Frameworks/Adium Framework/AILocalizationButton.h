//
//  AILocalizationButton.h
//  Adium
//
//  Created by Evan Schoenberg on 12/3/04.
//  Copyright 2004-2005 The Adium Team. All rights reserved.
//

@interface AILocalizationButton : NSButton {
	NSRect	originalFrame;
	
	IBOutlet	NSWindow	*window_anchorOnLeftSide;
	IBOutlet	NSWindow	*window_anchorOnRightSide;
	
	IBOutlet	NSView		*view_anchorToLeftSide;
	IBOutlet	NSView		*view_anchorToRightSide;
	
	AILocalizationAnchorMovementType	rightAnchorMovementType;
}

@end