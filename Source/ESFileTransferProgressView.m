//
//  ESFileTransferProgressView.m
//  Adium
//
//  Created by Evan Schoenberg on 11/11/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "ESFileTransferProgressView.h"
#import "ESFileTransferProgressRow.h"

@interface ESFileTransferProgressView (PRIVATE)
- (void)updateHeaderLine;
@end

@implementation ESFileTransferProgressView

- (void)awakeFromNib
{
	if ([[self superclass] instancesRespondToSelector:@selector(awakeFromNib)]){
        [super awakeFromNib];
    }

	[progressIndicator setUsesThreadedAnimation:YES];
	[progressIndicator setIndeterminate:YES];
	showingDetails = NO;
	[view_details retain];

#warning Safari does something cool with this, reclaiming its space when it hides.
	//[progressIndicator setDisplayedWhenStopped:NO];
}

- (void)dealloc
{
	[view_details release];
	
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
	return [self retain];
}

#pragma mark Source and destination
- (void)setSourceName:(NSString *)inSourceName
{
	[textField_source setStringValue:(inSourceName ? inSourceName : @"")];
}
- (void)setSourceIcon:(NSImage *)inSourceIcon
{
	[imageView_source setImage:inSourceIcon];
}
- (void)setDestinationName:(NSString *)inDestinationName
{
	[textField_destination setStringValue:(inDestinationName ? inDestinationName : @"")];
}
- (void)setDestinationIcon:(NSImage *)inDestinationIcon
{
	[imageView_destination setImage:inDestinationIcon];
}

#pragma mark File and its icon
- (void)setFileName:(NSString *)inFileName
{
	[textField_fileName setStringValue:(inFileName ? 
									   inFileName : 
									   AILocalizedString(@"Initializing transfer...",nil))];
}
- (void)setIconImage:(NSImage *)inIconImage
{
	[button_icon setImage:inIconImage];
}

#pragma mark Progress
- (void)setProgressDoubleValue:(double)inPercent
{
	[progressIndicator setDoubleValue:inPercent];
}
- (void)setProgressIndeterminate:(BOOL)flag
{
	[progressIndicator setIndeterminate:flag];	
}
- (void)setProgressAnimation:(BOOL)flag
{
	if(flag){
		[progressIndicator startAnimation:self];
	}else{
		[progressIndicator stopAnimation:self];	
	}
}

- (void)setTransferBytesStatus:(NSString *)inTransferBytesStatus
			   remainingStatus:(NSString *)inTransferRemainingStatus
				   speedStatus:(NSString *)inTransferSpeedStatus
{
	NSString	*transferStatus;
	
	if(inTransferBytesStatus && inTransferRemainingStatus){
		transferStatus = [NSString stringWithFormat:@"%@ - %@",
			inTransferBytesStatus,
			inTransferRemainingStatus];
	}else if(inTransferBytesStatus){
		transferStatus = inTransferBytesStatus;
	}else if(inTransferRemainingStatus){
		transferStatus = inTransferRemainingStatus;		
	}else{
		transferStatus = @"";
	}
	
	[textField_transferStatus setStringValue:transferStatus];

	[textField_rate setStringValue:(inTransferSpeedStatus ? inTransferSpeedStatus : @"")];
}

#pragma mark Details
//Sent when the details twiddle is clicked
- (IBAction)toggleDetails:(id)sender
{
	NSRect	detailsFrame = [view_details frame];
	NSRect	primaryControlsFrame = [box_primaryControls frame];
	NSRect	oldFrame = [self frame];
	NSRect	newFrame = oldFrame;
	
	showingDetails = !showingDetails;

	if(showingDetails){
		//Increase our height to make space
		newFrame.size.height += detailsFrame.size.height;
		newFrame.origin.y -= detailsFrame.size.height;
		[self setFrame:newFrame];
		
		//Move the box with our primary controls up
		primaryControlsFrame.origin.y += detailsFrame.size.height;
		[box_primaryControls setFrame:primaryControlsFrame];
			
		//Add the details subview
		[self addSubview:view_details];
		
		//Line up the details frame with the twiddle which revealed it
		detailsFrame.origin.x = [twiddle_details frame].origin.x;
		detailsFrame.origin.y = 0;

		[view_details setFrame:detailsFrame];
	
		//Update the twiddle
		[twiddle_details setState:NSOnState];
	}else{
		newFrame.size.height -= detailsFrame.size.height;
		newFrame.origin.y += detailsFrame.size.height;

		[self setFrame:newFrame];
		
		//Move the box with our primary controls back down
		primaryControlsFrame.origin.y -= detailsFrame.size.height;
		[box_primaryControls setFrame:primaryControlsFrame];
		
		[view_details removeFromSuperview];
		
		//Update the twiddle
		[twiddle_details setState:NSOffState];
	}
	
	//Let the owner know our height changed so other rows can be adjusted accordingly
	[owner fileTransferProgressView:self
				  heightChangedFrom:oldFrame.size.height
								 to:newFrame.size.height];
}

#pragma mark Event handling
/*
- (void)keyDown:(NSEvent *)event
{
	NSLog(@"%@: keyDown: %@",self,event);
	
	[super keyDown:event];
}
*/
#pragma mark Selection
- (void)setIsHighlighted:(BOOL)flag
{
	if(isSelected != flag){
		isSelected = flag;
		
		NSColor	*newColor;
		NSColor	*transferStatusColor;
		
		if(isSelected){
			newColor = [NSColor whiteColor];
			transferStatusColor = newColor;
			
#warning Cache these
			[button_stopResume setImage:[NSImage imageNamed:@"FTProgressStop_Selected" forClass:[self class]]];
			[button_stopResume setAlternateImage:[NSImage imageNamed:@"FTProgressStopPressed_Selected" forClass:[self class]]];
			
			[button_reveal setImage:[NSImage imageNamed:@"FTProgressReveal_Selected" forClass:[self class]]];
			[button_reveal setAlternateImage:[NSImage imageNamed:@"FTProgressRevealPressed_Selected" forClass:[self class]]];
		}else{
			newColor = [NSColor controlTextColor];
			transferStatusColor = [NSColor disabledControlTextColor];

#warning Cache these
			[button_stopResume setImage:[NSImage imageNamed:@"FTProgressStop" forClass:[self class]]];
			[button_stopResume setAlternateImage:[NSImage imageNamed:@"FTProgressStopPressed" forClass:[self class]]];

			[button_reveal setImage:[NSImage imageNamed:@"FTProgressReveal" forClass:[self class]]];
			[button_reveal setAlternateImage:[NSImage imageNamed:@"FTProgressRevealPressed" forClass:[self class]]];
		}
		
		[textField_rate setTextColor:newColor];
		[textField_source setTextColor:newColor];
		[textField_destination setTextColor:newColor];		
		[textField_fileName setTextColor:newColor];
		
		[textField_transferStatus setTextColor:newColor];
	}
}

@end
