//
//  AILocalizationTextField.m
//  Adium
//
//  Created by Evan Schoenberg on 11/29/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "AILocalizationTextField.h"

@interface AILocalizationTextField (PRIVATE)
- (void)_resizeWindow:(NSWindow *)inWindow leftBy:(float)difference;
@end

@implementation AILocalizationTextField

- (id)initWithFrame:(NSRect)inFrame
{
	[super initWithFrame:inFrame];
	
	originalFrame = inFrame;

	return(self);
}

- (void)setFrame:(NSRect)inFrame
{
	originalFrame = inFrame;

	[super setFrame:inFrame];
}

//This behavior only makes sense for ([self alignment] == NSRightTextAlignment) for now
- (void)setStringValue:(NSString *)inStringValue
{
	NSRect  newFrame, oldFrame;

	//If the old frame is smaller than our original frame, treat the old frame as that original frame
	//for resizing and positioning purposes
	oldFrame  = [self frame];
	if(oldFrame.size.width < originalFrame.size.width){
		oldFrame = originalFrame;
	}

	//Set to inStringValue, then sizeToFit
	[super setStringValue:inStringValue];
	[self sizeToFit];
	
	newFrame = [self frame];
	NSLog(@"original %@ old %@ new %@",NSStringFromRect(originalFrame),NSStringFromRect(oldFrame),NSStringFromRect(newFrame));
	//Enforce a minimum width of the original frame width
	if(newFrame.size.width < originalFrame.size.width){
		newFrame.size.width = originalFrame.size.width;
	}
	
	//Only use integral widths to keep alignment correct;
	//round up as an extra pixel of whitespace never hurt anybody
	newFrame.size.width = round(newFrame.size.width + 0.5);
	
	if([self alignment] == NSRightTextAlignment){
		//Keep the right edge in the same place at all times if we are right aligned
		newFrame.origin.x = oldFrame.origin.x + oldFrame.size.width - newFrame.size.width;
		NSLog(@"%@: shift left to %f",inStringValue,newFrame.origin.x);
	}/* NSCenterTextAlignment? */
	
	[super setFrame:newFrame];	
	[self setNeedsDisplay:YES];
	
	//Resize the window to fit the contactNameLabel if the current size is not correct
NSLog(@"%@: %f != %f ?",inStringValue,newFrame.size.width,oldFrame.size.width);
	if(newFrame.size.width != oldFrame.size.width){
		
		if(newFrame.origin.x < 17){
			//Shifted further left than it used to be - will only occur for right aligned text
			NSLog(@"Shifted left...");
			if(window_anchorOnLeftSide){
				float		difference = 17 - newFrame.origin.x;

				NSLog(@"Move %@ left by %f",window_anchorOnLeftSide,difference);
				[self _resizeWindow:window_anchorOnLeftSide leftBy:difference];				
				
				//Fix the origin - autosizing will end up moving this into the proper location
				newFrame.origin.x = 17;
				[super setFrame:newFrame];	
				[self setNeedsDisplay:YES];
			}
			
			if(view_anchorToLeftSide){
				NSRect		viewFrame = [view_anchorToLeftSide frame];
				float		difference = 17 - newFrame.origin.x /*newFrame.origin.x - oldFrame.origin.x*/;

				viewFrame.origin.x -= difference;
				
				if(viewFrame.origin.x < 0){
					float	overshoot = -viewFrame.origin.x;
					viewFrame.origin.x = 0;
				
					[view_anchorToLeftSide setFrame:viewFrame];
					[view_anchorToLeftSide setNeedsDisplay:YES];
					
					[self _resizeWindow:[self window] leftBy:overshoot];
				}else{
					[view_anchorToLeftSide setFrame:viewFrame];
					[view_anchorToLeftSide setNeedsDisplay:YES];
				}
			}
		}else{
			/* origin should be in the same place */
			if(view_anchorToRightSide){
				NSRect		viewFrame = [view_anchorToRightSide frame];
				float		difference = newFrame.size.width - oldFrame.size.width;
				
				viewFrame.origin.x += difference;
				
				//Adjust window somehow if needed?
				/*
				if(viewFrame.origin.x < 0){
					float	overshoot = -viewFrame.origin.x;
					viewFrame.origin.x = 0;
					
					[self _resizeWindow:[self window] leftBy:overshoot];
				}
				 */
				[view_anchorToRightSide setFrame:viewFrame];
				[view_anchorToRightSide setNeedsDisplay:YES];
			}
		}
	}
}

- (void)_resizeWindow:(NSWindow *)inWindow leftBy:(float)difference
{
	NSRect		windowFrame = [inWindow frame];
	NSRect		screenFrame = [[inWindow screen] frame];

	//Shift the origin
	windowFrame.origin.x -= difference;
	//But keep it on the screen
//	if(windowFrame.origin.x < screenFrame.origin.x) windowFrame.origin.x = screenFrame.origin.x;
				
	//Increase the width
	windowFrame.size.width += difference;
	//But keep it on the screen
//	if((windowFrame.origin.x + windowFrame.size.width) > (screenFrame.origin.x + screenFrame.size.width)){
//		windowFrame.origin.x -= (screenFrame.origin.x + screenFrame.size.width) - (windowFrame.origin.x + windowFrame.size.width);
//	}

	[inWindow setFrame:windowFrame display:NO];
}				

@end
