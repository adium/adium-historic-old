//
//  AIListGroupMockieCell.m
//  Adium
//
//  Created by Adam Iser on Fri Jul 30 2004.
//

#import "AIListGroupMockieCell.h"
#import "AIListOutlineView.h"

@implementation AIListGroupMockieCell

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	id newCell = [super copyWithZone:zone];
	return(newCell);
}

//
- (void)dealloc
{
	[self flushGradientCache];
	[super dealloc];
}

//Draw a regular mockie background for our cell if gradient background drawing is disabled
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	if(drawsBackground){
		[super drawBackgroundWithFrame:rect];
	}else{
		if(![self cellIsSelected]){
			[[self backgroundColor] set];
			if([controlView isItemExpanded:listObject]){
				[[NSBezierPath bezierPathWithRoundedTopCorners:rect radius:MOCKIE_RADIUS] fill];
			}else{
				[[NSBezierPath bezierPathWithRoundedRect:rect radius:MOCKIE_RADIUS] fill];
			}
		}
	}
}

//Draw a custom selection
- (void)drawSelectionWithFrame:(NSRect)cellFrame
{
	if([self cellIsSelected]){
		AIGradient	*gradient = [AIGradient selectedControlGradientWithDirection:AIVertical];
		if([controlView isItemExpanded:listObject]){
			[gradient drawInBezierPath:[NSBezierPath bezierPathWithRoundedTopCorners:cellFrame radius:MOCKIE_RADIUS]];
		}else{
			[gradient drawInBezierPath:[NSBezierPath bezierPathWithRoundedRect:cellFrame radius:MOCKIE_RADIUS]];
		}
	}
}

//Remake of the cachedGradient method in AIListGroupCell, except supporting 2 gradients depending on group state
- (NSImage *)cachedGradient:(NSSize)inSize
{
	AIGroupState state = ([controlView isItemExpanded:listObject] ? AIGroupExpanded : AIGroupCollapsed);

	if(!_mockieGradient[state] || !NSEqualSizes(inSize,_mockieGradientSize[state])){
		[_mockieGradient[state] release];
		_mockieGradient[state] = [[NSImage alloc] initWithSize:inSize];
		_mockieGradientSize[state] = inSize;
		
		[_mockieGradient[state] lockFocus];
		[self drawBackgroundGradientInRect:NSMakeRect(0,0,inSize.width,inSize.height)];
		[_mockieGradient[state] unlockFocus];
	}
	
	return(_mockieGradient[state]);
}

//Remake of flushGradientCache, supporting 2 gradients depending on group state
- (void)flushGradientCache
{
	int i;
	for(i = 0; i < NUMBER_OF_GROUP_STATES; i++){
		[_mockieGradient[i] release]; _mockieGradient[i] = nil;
		_mockieGradientSize[i] = NSMakeSize(0,0);
	}
}

//Draw our background gradient.  For collapsed groups we draw the caps rounded, for expanded groups we only round the
//upper corners so the group smoothly transitions to the contact below it.
- (void)drawBackgroundGradientInRect:(NSRect)rect
{
	if([controlView isItemExpanded:listObject]){
		[[self backgroundGradient] drawInBezierPath:[NSBezierPath bezierPathWithRoundedTopCorners:rect radius:MOCKIE_RADIUS]];
	}else{
		[[self backgroundGradient] drawInBezierPath:[NSBezierPath bezierPathWithRoundedRect:rect radius:MOCKIE_RADIUS]];
	}
}

//Because of the rounded corners, we cannot rely on the outline view to draw our grid.  Return NO here to let
//the outline view know we'll be drawing the grid ourself
- (BOOL)drawGridBehindCell
{
	return(NO);
}

@end
