//
//  AIViewGridView.m
//  Adium
//
//  Created by Adam Iser on 12/10/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "AIViewGridView.h"

@interface AIViewGridView (PRIVATE)
- (NSSize)_sizeOfLargestView;
- (void)_updateGrid;
- (void)_updateGridForNewFrame:(NSRect)newFrame;
- (void)_positionViewsOnGrid;
@end

#define MIN_PADDING 2

@implementation AIViewGridView

- (id)initWithFrame:(NSRect)frameRect
{
	[super initWithFrame:frameRect];
		
	return(self);
}

- (void)dealloc
{
	[super dealloc];
}

//Configure -------------------------------------------------------------------------------------------
- (void)addView:(NSView *)inView
{
	[self addSubview:inView];
	[self _updateGrid];
}

//Set the frame of our view
- (void)setFrame:(NSRect)frameRect
{
	[self _updateGridForNewFrame:frameRect];
}

//- (void)drawRect:(NSRect)rect
//{
//	[[NSColor blueColor] set];
//	[NSBezierPath fillRect:rect];
//	
//	[super drawRect:rect];
//}

//Drawing & Sizing -------------------------------------------------------------------------------------
//This view is flipped since we intend for it to be within a scrollview
- (BOOL)isFlipped
{
	return(YES);
}

//Update our frame height, number of columns, and padding
- (void)_updateGrid{
	[self _updateGridForNewFrame:[self frame]];
}
- (void)_updateGridForNewFrame:(NSRect)newFrame
{
	NSScrollView	*scrollView = [self enclosingScrollView];
	
	//
	largest = [self _sizeOfLargestView];

	//calc number of columns
	columns = newFrame.size.width / (largest.width + MIN_PADDING);
	
	//Increase padding to stretch the columns to the full width of our view
	if(columns > 1){ //1 column would cause a divide by zero in this logic
		padding.width = (newFrame.size.width - (columns * largest.width)) / (columns - 1);
	}else{
		padding.width = 0;
	}
	padding.height = 8;//padding.width;
	
	//Resize our view so it's tall enuogh to display enough rows and that it always
	//covers the entire visible area in our scroll view.
	int rows = ceil((double)[[self subviews] count] / (double)columns);
	newFrame.size.height = rows * (largest.height + padding.height);
	if(scrollView && [scrollView contentSize].height > newFrame.size.height){
		newFrame.size.height = [scrollView contentSize].height;
	}
	[super setFrame:newFrame];

	//Position all subviews on this grid
	[self _positionViewsOnGrid];
	
	[self setNeedsDisplay:YES];
}
- (void)_positionViewsOnGrid
{
	int		x, y, c;

	x = 0;
	y = 0;
	c = columns;
	
	NSEnumerator	*enumerator = [[self subviews] objectEnumerator];
	NSView			*view;
	
	while(view = [enumerator nextObject]){
		[view setFrame:NSMakeRect(x, y, largest.width, largest.height)];
		
		if(--c == 0){
			c = columns;
			y += largest.height + padding.height;
			x = 0;
		}else{
			x += largest.width + padding.width;
		}
	}
}




//
//
//- (void)_positionViews
//{
//	NSSize	largest = [self _sizeOfLargestView];
//	NSRect	frame = [self frame];
//	int		x, y, c;
//	
//	//calc number of columns
//	int columns = frame.size.width / largest.width /*+ minPadding*/;
//
//	//Increase padding to stretch the columns to the full width of our view
//	padding.width = (newFrame.size.width - (columns * imageSize.width)) / (columns + 1);
//	padding.height = padding.width;
//	
//	
//	
//	
//	//Position
//	x = 0;
//	y = 0;
//	c = columns;
//	
//	NSEnumerator	*enumerator = [[self subviews] objectEnumerator];
//	NSView			*view;
//	
//	while(view = [enumerator nextObject]){
//		[view setFrame:NSMakeRect(x, y, largest.width, largest.height)];
//		
//		if(--c == 0){
//			c = columns;
//			y += largest.height;
//			x = 0;
//		}else{
//			x += largest.width;
//		}
//	}
//	
//}

- (NSSize)_sizeOfLargestView
{
	NSEnumerator	*enumerator = [[self subviews] objectEnumerator];
	NSView			*view;
	NSSize			largestSize = NSMakeSize(0,0);
	
	while(view = [enumerator nextObject]){
		NSSize	viewSize = [view frame].size;

		if(viewSize.height > largestSize.height) largestSize.height = viewSize.height;
		if(viewSize.width > largestSize.width) largestSize.width = viewSize.width;
	}

	return(largestSize);
}

@end
