/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

//Implementation file for AILocalizationXXXX classes; this is imported by them and should not be used directly

- (id)initWithCoder:(NSCoder *)inCoder
{
	[super initWithCoder:inCoder];
	[self _initLocalizationControl];
	
	return(self);
}

- (id)initWithFrame:(NSRect)inFrame
{
	[(id)super initWithFrame:inFrame];
	
	originalFrame = inFrame;
	[self _initLocalizationControl];
	
	return(self);
}

- (void)awakeFromNib
{
    if ([[self superclass] instancesRespondToSelector:@selector(awakeFromNib)]){
        [super awakeFromNib];
    }

	originalFrame = [TARGET_CONTROL frame];
}

- (void)setRightAnchorMovementType:(AILocalizationAnchorMovementType)inType
{
	rightAnchorMovementType = inType;
}

- (void)setFrame:(NSRect)inFrame
{
	originalFrame = inFrame;
	
	[(id)super setFrame:inFrame];
}

- (void)_handleSizingWithOldFrame:(NSRect)oldFrame stringValue:(NSString *)inStringValue
{
	//Textfield uses 17, button uses 14.
	
	NSRect		newFrame;

	[TARGET_CONTROL sizeToFit];
	
	newFrame = [TARGET_CONTROL frame];
	//NSLog(@"%@: original %@ old %@ new %@",inStringValue,NSStringFromRect(originalFrame),NSStringFromRect(oldFrame),NSStringFromRect(newFrame));
	//Enforce a minimum width of the original frame width
	if(newFrame.size.width < originalFrame.size.width){
		newFrame.size.width = originalFrame.size.width;
	}
	
	//Only use integral widths to keep alignment correct;
	//round up as an extra pixel of whitespace never hurt anybody
	newFrame.size.width = round(newFrame.size.width + 0.5);
	
	switch([self alignment]){
		case NSRightTextAlignment:
			//Keep the right edge in the same place at all times if we are right aligned
			newFrame.origin.x = oldFrame.origin.x + oldFrame.size.width - newFrame.size.width;
			//NSLog(@"%@: shift left to %f",inStringValue,newFrame.origin.x);
			break;
		case NSCenterTextAlignment:
		{
			//Keep the center in the same place
			float windowMaxX = NSMaxX([[TARGET_CONTROL window] frame]);
			
			//NSLog(@"%@: CENTER: newFrame was %@, oldFrame was %@",inStringValue,NSStringFromRect(newFrame),NSStringFromRect(oldFrame));
			newFrame.origin.x = oldFrame.origin.x + (oldFrame.size.width - newFrame.size.width)/2;
			
			if(NSMaxX(newFrame) + 17 > windowMaxX){
				newFrame.origin.x -= ((NSMaxX(newFrame) + 17) - windowMaxX);
			}

			//Only use integral origins to keep alignment correct;
			//round up as an extra pixel of whitespace never hurt anybody
			newFrame.origin.x = round(newFrame.origin.x + 0.5);
			
			//NSLog(@"%@: CENTER: newFrame is now %@, oldFrame was %@",inStringValue,NSStringFromRect(newFrame),NSStringFromRect(oldFrame));
			break;
		}
		default:
			break;
	}
	
	//NSLog(@"%@: initial setFrame: %@",inStringValue,NSStringFromRect(newFrame));
	[TARGET_CONTROL setFrame:newFrame];
	[TARGET_CONTROL setNeedsDisplay:YES];
	
	//Resize the window to fit the contactNameLabel if the current size is not correct
	//NSLog(@"%@: %f != %f ?",inStringValue,newFrame.size.width,oldFrame.size.width);
	if(newFrame.size.width != oldFrame.size.width){
		
		//Too close on left; need to expand window left
		if(window_anchorOnLeftSide && newFrame.origin.x < 17){
			float		difference = 17 - newFrame.origin.x;
			
			//NSLog(@"%@: Move %@ left by %f",inStringValue,window_anchorOnLeftSide,difference);
			[self _resizeWindow:window_anchorOnLeftSide leftBy:difference];				
			
			//Fix the origin - autosizing will end up moving this into the proper location
			newFrame.origin.x = 17;
			//NSLog(@"%@: 1 initial setFrame: %@",inStringValue,NSStringFromRect(newFrame));

			[TARGET_CONTROL setFrame:newFrame];
			[TARGET_CONTROL setNeedsDisplay:YES];
		}
		
		//Too close on right; need to expand window right
		if(window_anchorOnRightSide && (NSMaxX(newFrame) > (NSMaxX([window_anchorOnRightSide frame]) - 17))){
			float		difference =  NSMaxX(newFrame) - (NSMaxX([window_anchorOnRightSide frame]) - 17);
			
			//NSLog(@"%@: Move %@ right by %f",inStringValue,window_anchorOnRightSide,difference);
			[self _resizeWindow:window_anchorOnRightSide rightBy:difference];
				
			newFrame.origin.x = NSMaxX([window_anchorOnRightSide frame]) - newFrame.size.width - 17;

			//NSLog(@"%@: 2 initial setFrame: %@",inStringValue,NSStringFromRect(newFrame));
			[TARGET_CONTROL setFrame:newFrame];
			[TARGET_CONTROL setNeedsDisplay:YES];			
		}
		
		if(newFrame.origin.x < oldFrame.origin.x){
			//Shifted further left than it used to be
			if(view_anchorToLeftSide){
				NSRect		leftAnchorFrame = [view_anchorToLeftSide frame];
				float		difference = (oldFrame.origin.x - newFrame.origin.x);
				
				leftAnchorFrame.origin.x -= difference;
				
				if(leftAnchorFrame.origin.x < 0){
					float	overshoot = -leftAnchorFrame.origin.x;
					leftAnchorFrame.origin.x = 0;
					
					//NSLog(@"%@: 3 origin is to the left, and less than zero: %@",NSStringFromRect(leftAnchorFrame));
					[view_anchorToLeftSide setFrame:leftAnchorFrame];
					[view_anchorToLeftSide setNeedsDisplay:YES];
					
					[self _resizeWindow:[TARGET_CONTROL window] leftBy:overshoot];
				}else{
					//NSLog(@"%@: 4 origin is to the left, not less than zero, moving to %@",inStringValue,NSStringFromRect(leftAnchorFrame));
					[view_anchorToLeftSide setFrame:leftAnchorFrame];
					[view_anchorToLeftSide setNeedsDisplay:YES];
				}
			}
		}else{
			/* newFrame.origin.x >= oldFrame.origin.x */
			if(view_anchorToRightSide){
				NSRect		rightAnchorFrame = [view_anchorToRightSide frame];

				if(rightAnchorMovementType == AILOCALIZATION_MOVE_ANCHOR){
					//Move our anchor with us
					float		difference = newFrame.size.width - oldFrame.size.width;
					rightAnchorFrame.origin.x += difference;
					
					//If this would put us outside the view, reduce the width of the anchored view
					//XXX could add a window_anchorOnRightSide and have a window expansion behavior instead.
					//XXX needs to be optional via a setting
					/*
					if((rightAnchorFrame.origin.x + rightAnchorFrame.size.width) > newFrame.size.width){
						rightAnchorFrame.size.width = newFrame.size.width - rightAnchorFrame.origin.x;
					}
					*/
					
					//NSLog(@"%@: 5 origin.x is >=, moving view_anchorToRightSide to %@",inStringValue,NSStringFromRect(rightAnchorFrame));
					[view_anchorToRightSide setFrame:rightAnchorFrame];
					[view_anchorToRightSide setNeedsDisplay:YES];
					
				}else{ /*rightAnchorMovementType == AILOCALIZATION_MOVE_SELF */
					
					//Move us left to keep our distance from our anchor view to the right
					newFrame.origin.x = rightAnchorFrame.origin.x - newFrame.size.width - 10;
					
					[TARGET_CONTROL setFrame:newFrame];
					[TARGET_CONTROL setNeedsDisplay:YES];
				}
				
				//Adjust window somehow if needed?
				/*
				 if(viewFrame.origin.x < 0){
					 float	overshoot = -viewFrame.origin.x;
					 viewFrame.origin.x = 0;
					 
					 [self _resizeWindow:[self window] leftBy:overshoot];
				 }
				 */
			}
			
			if(view_anchorToLeftSide){
				NSRect		leftAnchorFrame = [view_anchorToLeftSide frame];
				float		difference = (oldFrame.origin.x - newFrame.origin.x);
				
				leftAnchorFrame.origin.x -= difference;
				
				if(leftAnchorFrame.origin.x < 0){
					float	overshoot = -leftAnchorFrame.origin.x;
					leftAnchorFrame.origin.x = 0;

					//NSLog(@"%@: 6 origin.x is >=, leftAnchorFrame.origin.x < 0, moving view_anchorToLeftSide to %@",inStringValue,NSStringFromRect(leftAnchorFrame));

					[view_anchorToLeftSide setFrame:leftAnchorFrame];
					[view_anchorToLeftSide setNeedsDisplay:YES];
					
					[self _resizeWindow:[TARGET_CONTROL window] leftBy:overshoot];
				}else{
					
					//NSLog(@"%@: 7 origin.x is >=, moving view_anchorToLeftSide to %@",inStringValue,NSStringFromRect(leftAnchorFrame));

					[view_anchorToLeftSide setFrame:leftAnchorFrame];
					[view_anchorToLeftSide setNeedsDisplay:YES];
				}
			}
		}
		
		//After all this fun and games, check out anchors again, this time to move self if need be
		{
			if(view_anchorToRightSide){
				NSRect		rightAnchorFrame = [view_anchorToRightSide frame];

				//Ensure we are not now overlapping our right anchor; if so, shift left
				if(NSMaxX(newFrame) > NSMinX(rightAnchorFrame)){
					//+8 perhaps for textviews; 0 for buttons, which have weird frames.
					newFrame.origin.x -= ((NSMaxX(newFrame) - NSMinX(rightAnchorFrame))/* + 8 */);
					
					[TARGET_CONTROL setFrame:newFrame];
					[TARGET_CONTROL setNeedsDisplay:YES];
					
					//As we did initially, check to see if we now need to expand the window to the left
					if(window_anchorOnLeftSide && newFrame.origin.x < 17){
						float		difference = 17 - newFrame.origin.x;
						
						//NSLog(@"%@: Move %@ left by %f",inStringValue,window_anchorOnLeftSide,difference);
						[self _resizeWindow:window_anchorOnLeftSide leftBy:difference];				
						
						//Fix the origin - autosizing will end up moving this into the proper location
						newFrame.origin.x = 17;
						//NSLog(@"%@: 1 initial setFrame: %@",inStringValue,NSStringFromRect(newFrame));
						
						[TARGET_CONTROL setFrame:newFrame];
						[TARGET_CONTROL setNeedsDisplay:YES];
					}
				}
			}
		}
		
	} /* end of (newFrame.size.width != oldFrame.size.width) */
}

- (void)_resizeWindow:(NSWindow *)inWindow leftBy:(float)difference
{
	NSRect		windowFrame = [inWindow frame];
	NSRect		screenFrame = [[inWindow screen] frame];
	
	//Shift the origin
	windowFrame.origin.x -= difference;
	//But keep it on the screen
	if(windowFrame.origin.x < screenFrame.origin.x) windowFrame.origin.x = screenFrame.origin.x;
				
	//Increase the width
	windowFrame.size.width += difference;
	//But keep it on the screen
	if((windowFrame.origin.x + windowFrame.size.width) > (screenFrame.origin.x + screenFrame.size.width)){
		windowFrame.origin.x -= (screenFrame.origin.x + screenFrame.size.width) - (windowFrame.origin.x + windowFrame.size.width);
	}
	
	[inWindow setFrame:windowFrame display:NO];
}				

- (void)_resizeWindow:(NSWindow *)inWindow rightBy:(float)difference
{
	NSRect		windowFrame = [inWindow frame];
	NSRect		screenFrame = [[inWindow screen] frame];
	
	//Increase the width
	windowFrame.size.width += difference;
	//But keep it on the screen
	if((windowFrame.origin.x + windowFrame.size.width) > (screenFrame.origin.x + screenFrame.size.width)){
		windowFrame.origin.x -= (screenFrame.origin.x + screenFrame.size.width) - (windowFrame.origin.x + windowFrame.size.width);
	}
	
	[inWindow setFrame:windowFrame display:NO];
}				

