//Adapted from Colloquy  (www.colloquy.info)

#import "MVMenuButton.h"

@interface MVMenuButton (PRIVATE)
- (NSBezierPath *)popUpArrowPath;
@end

@implementation MVMenuButton

//
- (id)initWithFrame:(NSRect)frame
{
	[super initWithFrame:frame];

	//Default configure
	bigImage = nil;
	smallImage = nil;
	toolbarItem = nil;
	arrowPath = nil;
	drawsArrow = YES;
	controlSize = NSRegularControlSize;
	[self setBordered:NO];
	[self setButtonType:NSMomentaryChangeButton];

	return(self);
}

//
- (id)copyWithZone:(NSZone *)zone
{
	MVMenuButton	*newButton = [[[self class] allocWithZone:zone] initWithFrame:[self frame]];

	//Copy our config
	[newButton setControlSize:controlSize];
	[newButton setImage:bigImage];
	[newButton setSmallImage:smallImage];
	[newButton setDrawsArrow:drawsArrow];

	//Copy super's config
	[newButton setMenu:[[[self menu] copy] autorelease]];
	
	return(newButton);
}

//
- (void)dealloc
{
	[bigImage release];
	[smallImage release];
	[arrowPath release];
	
	[super dealloc];
}


//Configure ------------------------------------------------------------------------------------------------------------
#pragma mark Configure
//Control Size (Allows us to dynamically size for a small or big toolbar)
- (void)setControlSize:(NSControlSize)inSize
{
	controlSize = inSize;
	
	//Update our containing toolbar item's size so it will scale with us
	if(inSize == NSRegularControlSize){
		[toolbarItem setMinSize:NSMakeSize(32, 32)];
		[toolbarItem setMaxSize:NSMakeSize(32, 32)];
		[super setImage:bigImage];
		
	}else if(inSize == NSSmallControlSize){
		[toolbarItem setMinSize:NSMakeSize(24, 24)];
		[toolbarItem setMaxSize:NSMakeSize(24, 24)];
		[super setImage:smallImage];
		
	}
	
	//Reset the popup arrow path cache, we'll need to re-calculate it for the new size
	[arrowPath release]; arrowPath = nil;
}
- (NSControlSize)controlSize
{
	return(controlSize);
}

//Big Image (This is the one that should be called to configure this button)
- (void)setImage:(NSImage *)inImage
{
	[bigImage release];
	[smallImage release];
	bigImage = [inImage retain];
	
	//Generate a small version of this image
	smallImage = [[NSImage alloc] initWithSize:NSMakeSize(24, 24)];
	[smallImage lockFocus];
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	[[bigImage bestRepresentationForDevice:nil] drawInRect:NSMakeRect(0, 0, 24, 24)];
	[smallImage unlockFocus];
	
	//Update our control size and the displayed image
	[self setControlSize:controlSize];
}
- (NSImage *)image
{
	return(bigImage);
}

//Small Image (Used for copying)
- (void)setSmallImage:(NSImage *)image
{
	[smallImage release]; smallImage = [image retain];
}
- (NSImage *)smallImage
{
	return(smallImage);
}

//Containing toolbar Item
- (void)setToolbarItem:(NSToolbarItem *)item
{
	toolbarItem = item;
}
- (NSToolbarItem *)toolbarItem
{
	return(toolbarItem);
}

//Popup arrow Drawing
- (void)setDrawsArrow:(BOOL)inDraw
{
	drawsArrow = inDraw;
}
- (BOOL)drawsArrow
{
	return(drawsArrow);
}


//Drawing --------------------------------------------------------------------------------------------------------------
#pragma mark Drawing
- (void)drawRect:(NSRect)rect
{
	//Let super draw our image (Easier than drawing it on our own)
	[super drawRect:rect];

	//Draw the popup arrow
	if(drawsArrow){
		[[[NSColor blackColor] colorWithAlphaComponent:0.75] set];
		[[self popUpArrowPath] fill];
	}
}

//Path for the little popup arrow (Cached)
- (NSBezierPath *)popUpArrowPath
{
	if(!arrowPath){
		NSRect	frame = [self frame];
		
		arrowPath = [[NSBezierPath bezierPath] retain];
		
		if(controlSize == NSRegularControlSize){
			[arrowPath moveToPoint:NSMakePoint(NSWidth(frame)-6, NSHeight(frame)-3)];
			[arrowPath relativeLineToPoint:NSMakePoint( 6, 0)];
			[arrowPath relativeLineToPoint:NSMakePoint(-3, 3)];
		}else if(controlSize == NSSmallControlSize){
			[arrowPath moveToPoint:NSMakePoint(NSWidth(frame)-4, NSHeight(frame)-3)];
			[arrowPath relativeLineToPoint:NSMakePoint( 4, 0)];
			[arrowPath relativeLineToPoint:NSMakePoint(-2, 3)];
		}
		[arrowPath closePath];
	}

	return(arrowPath);
}


//Mouse Tracking -------------------------------------------------------------------------------------------------------
#pragma mark Mouse Tracking
//Custom mouse down tracking to display our menu and highlight
- (void)mouseDown:(NSEvent *)theEvent
{
	if(![self menu]){
		[super mouseDown:theEvent];
	}else{
		if([self isEnabled]){
			[self highlight:YES];

			NSPoint point = [self convertPoint:[self bounds].origin toView:nil];
			point.y -= NSHeight([self frame]) + 2;
			point.x -= 1;
			
			NSEvent *event = [NSEvent mouseEventWithType:[theEvent type]
												location:point
										   modifierFlags:[theEvent modifierFlags]
											   timestamp:[theEvent timestamp]
											windowNumber:[[theEvent window] windowNumber]
												 context:[theEvent context]
											 eventNumber:[theEvent eventNumber]
											  clickCount:[theEvent clickCount]
												pressure:[theEvent pressure]];
			[NSMenu popUpContextMenu:[self menu] withEvent:event forView:self];
			
			[self mouseUp:[[NSApplication sharedApplication] currentEvent]];
		}
	}
}

//Remove highlight on mouse up
- (void)mouseUp:(NSEvent *)theEvent
{
	[self highlight:NO];
	[super mouseUp:theEvent];
}

//Ignore dragging
- (void)mouseDragged:(NSEvent *)theEvent
{
	//Empty
}

@end
