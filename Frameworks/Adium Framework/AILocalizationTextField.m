//
//  AILocalizationTextField.m
//  Adium
//
//  Created by Evan Schoenberg on 11/29/04.
//  Copyright 2004-2005 The Adium Team. All rights reserved.
//

#import "AILocalizationTextField.h"

@implementation AILocalizationTextField

//Set up our defaults
- (void)_initLocalizationControl
{
	rightAnchorMovementType = AILOCALIZATION_MOVE_ANCHOR;
}

- (void)setStringValue:(NSString *)inStringValue
{
	NSRect			oldFrame;
	
	//If the old frame is smaller than our original frame, treat the old frame as that original frame
	//for resizing and positioning purposes
	oldFrame  = [self frame];
	if(oldFrame.size.width < originalFrame.size.width){
		oldFrame = originalFrame;
	}
	
	//Set to inStringValue, then sizeToFit
	[super setStringValue:inStringValue];
	
	[self _handleSizingWithOldFrame:oldFrame stringValue:inStringValue];
}

- (NSControl *)viewForSizing
{
	return(self);
}

#include "AILocalizationControl.m"

@end
