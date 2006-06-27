//
//  ESSourceListResizer.m
//  Adium
//
//  Created by Evan Schoenberg on 6/26/06.
//

#import "ESSourceListResizer.h"
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIParagraphStyleAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>

#define RESIZE_CONTROL_MARGIN	2
#define	BORDER_MARGIN	4

#define RESIZE_CONTROL_WIDTH	7
#define RESIZE_CONTROL_X_SPACE	3; /* 1 4 7 */
#define RESIZE_CONTROL_HEIGHT	10

@implementation ESSourceListResizer

- (void)_initSourceListResizer
{
	[self resetCursorRects];
	[self setNeedsDisplay:YES];
}

- (id)initWithCoder:(NSCoder *)inCoder
{
	if ((self = [super initWithCoder:inCoder])) {
		[self _initSourceListResizer];
	}
	
	return self;
}

- (id)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		[self _initSourceListResizer];
	}
	
	return self;
}

- (void)dealloc
{
	[stringValue release];
	[attributedStringValue release];

	[super dealloc];
}

- (NSRect)resizeControlRect
{
	NSRect	myFrame = [self frame];

	return NSMakeRect(myFrame.size.width - RESIZE_CONTROL_WIDTH - (RESIZE_CONTROL_MARGIN * 2) - BORDER_MARGIN,
					  (myFrame.size.height - RESIZE_CONTROL_HEIGHT) / 2,
					  RESIZE_CONTROL_WIDTH + RESIZE_CONTROL_MARGIN * 2,
					  RESIZE_CONTROL_HEIGHT);
}

- (void)resetCursorRects
{
	[self addCursorRect:[self resizeControlRect]
				 cursor:[NSCursor resizeLeftRightCursor]];

	[super resetCursorRects];
}
#pragma mark Status string
- (void)setStringValue:(NSString *)inString
{
	if (![inString isEqualToString:stringValue]) {
		[stringValue release];
		stringValue = [inString copy];
		
		[attributedStringValue release];
		if (stringValue) {
			NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSParagraphStyle styleWithAlignment:NSLeftTextAlignment
									   lineBreakMode:NSLineBreakByTruncatingTail], NSParagraphStyleAttributeName,
				[NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName, 
				nil];
			
			stringHeight = [NSAttributedString stringHeightForAttributes:attributes];
			attributedStringValue = [[NSAttributedString alloc] initWithString:stringValue
																	attributes:attributes];
		} else {
			attributedStringValue = nil;
		}
		[self setNeedsDisplay:YES];
	}
}

#pragma mark Drawing

- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];

	NSRect	frame = [self frame];
	NSRect	resizeControlRect = [self resizeControlRect];

	//Draw the string
	if (attributedStringValue) {
		NSRect textRect = NSMakeRect(6, (frame.size.height - stringHeight)/2, NSMinX(resizeControlRect) - 8, stringHeight);

		[attributedStringValue drawInRect:textRect];
	}

	//Now draw the resize indicator
	NSRect *lineRects = (NSRect *)malloc(sizeof(NSRect) * 3);
	lineRects[0] = NSMakeRect(resizeControlRect.origin.x, resizeControlRect.origin.y,
							  1, resizeControlRect.size.height);
	lineRects[1] = NSMakeRect(resizeControlRect.origin.x + 3, resizeControlRect.origin.y,
							  1, resizeControlRect.size.height);
	lineRects[2] = NSMakeRect(resizeControlRect.origin.x + 6, resizeControlRect.origin.y,
							  1, resizeControlRect.size.height);
	
	[[NSColor grayColor] set];
	NSRectFillListUsingOperation(lineRects, 3, NSCompositeSourceOver);
	free(lineRects);

	[[NSColor lightGrayColor] set];
	NSRectFillUsingOperation(NSMakeRect(NSMaxX(frame) - 1, 0, 2, NSHeight(frame)), NSCompositeSourceOver);
}

#pragma mark Delegate
- (void)setDelegate:(id)inDelegate
{
	delegate = inDelegate;
}

- (id)delegate
{
	return delegate;
}

#pragma mark Dragging
/*
 * @brief Mouse dragged
 */
- (void)mouseDragged:(NSEvent *)theEvent
{
	if (draggingDivider) {
		NSPoint		currentLocation;

		currentLocation = [NSEvent mouseLocation];
		
		float deltaX = currentLocation.x - originalMouseLocation.x;
		
		originalMouseLocation = currentLocation;
		
		[[self delegate] draggedDividerRightBy:deltaX];
	}
}

/*
 * @brief Mouse down
 *
 * We start tracking the a drag operation here when the user first clicks the mouse without command presed
 * to establish the initial location.
 */
- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint locationInWindow = [theEvent locationInWindow];
	if (NSPointInRect([self convertPoint:locationInWindow fromView:nil], [self resizeControlRect])) {
		NSWindow	*window = [self window];

		//grab the mouse location in global coordinates
		originalMouseLocation = [window convertBaseToScreen:locationInWindow];
		draggingDivider = YES;
	}
}

/*!
 * @brief Mouse up
 */
- (void)mouseUp:(NSEvent *)theEvent
{
	draggingDivider = NO;
}

/*!
 * @brief Hide mouse down events from our subviews
 */
- (NSView *)hitTest:(NSPoint)aPoint
{
	return self;
}

@end
