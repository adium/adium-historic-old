//
//  AILocalizationButtonCell.m
//  Adium
//
//  Created by Evan Schoenberg on 12/31/04.
//  Copyright 2004-2005 The Adium Team. All rights reserved.
//

#import "AILocalizationButtonCell.h"

#define	TARGET_CONTROL	(NSControl *)[self controlView]

@implementation AILocalizationButtonCell
//Set up our defaults
- (void)_initLocalizationControl
{
	rightAnchorMovementType = AILOCALIZATION_MOVE_ANCHOR;
}

- (void)setTitle:(NSString *)inTitle
{
	NSRect			oldFrame;
	
	//If the old frame is smaller than our original frame, treat the old frame as that original frame
	//for resizing and positioning purposes
	oldFrame  = [TARGET_CONTROL frame];
	if(oldFrame.size.width < originalFrame.size.width){
		oldFrame = originalFrame;
	}
	
	//Set to inStringValue, then sizeToFit
	[super setTitle:inTitle];
	
	[self _handleSizingWithOldFrame:oldFrame stringValue:inTitle];
}

#include "AILocalizationControl.m"

@end
