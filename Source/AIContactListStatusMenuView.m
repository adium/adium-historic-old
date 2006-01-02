//
//  AIContactListStatusMenuView.m
//  Adium
//
//  Created by Evan Schoenberg on 12/16/05.
//

#import "AIContactListStatusMenuView.h"
#import "AIContactListStatusMenuCell.h"

@implementation AIContactListStatusMenuView

+ (void)initialize {
	[self setCellClass:[AIContactListStatusMenuCell class]];
}

- (void)configureTracking
{
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(frameDidChange:)
												 name:NSViewFrameDidChangeNotification
											   object:self];
	[self setPostsFrameChangedNotifications:YES];
	
	trackingTag = -1;
	[self resetCursorRects];			
}

- (id)initWithFrame:(NSRect)inFrame
{
	if ((self = [super initWithFrame:inFrame])) {
		[self configureTracking];
	}
	
	return self;
}

- (void)awakeFromNib
{
	if ([[self superclass] instancesRespondToSelector:@selector(awakeFromNib)]) {
        [super awakeFromNib];
	}
	
	[self configureTracking];
}

//
- (id)copyWithZone:(NSZone *)zone
{
	AIContactListStatusMenuView	*newButton = [[[self class] allocWithZone:zone] initWithFrame:[self frame]];
	
	[newButton setMenu:[[[self menu] copy] autorelease]];
	
	return newButton;
}

//silly NSControl...
- (void)setMenu:(NSMenu *)menu {
	[super setMenu:menu];
	[[self cell] setMenu:menu];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	if (trackingTag != -1) {
		[self removeTrackingRect:trackingTag];
		trackingTag = -1;
	}
	
	[super dealloc];
}

//Mouse Tracking -------------------------------------------------------------------------------------------------------
#pragma mark Mouse Tracking
//Custom mouse down tracking to display our menu and highlight
- (void)mouseDown:(NSEvent *)theEvent
{
	if (![self menu]) {
		[super mouseDown:theEvent];
	} else {
		if ([self isEnabled]) {
			[self highlight:YES];
			
			[self setNeedsDisplay:YES];

			//2 pt down, 1 pt to the left.
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

- (NSView *)hitTest:(NSPoint)aPoint
{
	NSRect	myFrame = [self frame];
	myFrame.size.width = [[self cell] trackingWidth];

	if (NSPointInRect(aPoint, myFrame)) {
		return [super hitTest:aPoint];
	} else {
		return nil;
	}
}

/*
 * @brief Set the title
 */
- (void)setTitle:(NSString *)inTitle
{
	[[self cell] setTitle:inTitle];
	[self setNeedsDisplay:YES];

	[self resetCursorRects];
}

- (void)setImage:(NSImage *)inImage
{
	[[self cell] setImage:inImage];
	[self setNeedsDisplay:YES];
	
	[self resetCursorRects];	
}

#pragma mark Tracking rects
//Remove old tracking rects when we change superviews
- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
	if (trackingTag != -1) {
		[self removeTrackingRect:trackingTag];
		trackingTag = -1;
	}
	
	[super viewWillMoveToSuperview:newSuperview];
}

- (void)viewDidMoveToSuperview
{
	[super viewDidMoveToSuperview];
	
	[self resetCursorRects];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	if (trackingTag != -1) {
		[self removeTrackingRect:trackingTag];
		trackingTag = -1;
	}
	
	[super viewWillMoveToWindow:newWindow];
}

- (void)viewDidMoveToWindow
{
	[super viewDidMoveToWindow];
	
	[self resetCursorRects];
}

- (void)frameDidChange:(NSNotification *)inNotification
{
	[self resetCursorRects];
}

//Reset our cursor tracking
- (void)resetCursorRects
{
	//Stop any existing tracking
	if (trackingTag != -1) {
		[self removeTrackingRect:trackingTag];
		trackingTag = -1;
	}
	
	//Add a tracking rect if our superview and window are ready
	if ([self superview] && [self window]) {
		NSRect	myFrame = [self frame];
		NSRect	trackRect = NSMakeRect(0, 0, [[self cell] trackingWidth], myFrame.size.height);
		
		if (trackRect.size.width > myFrame.size.width) {
			trackRect.size.width = myFrame.size.width;
		}

		NSPoint	localPoint = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]]
									   fromView:nil];
		BOOL	mouseInside = NSPointInRect(localPoint, trackRect);

		trackingTag = [self addTrackingRect:trackRect owner:self userData:nil assumeInside:mouseInside];
		if (mouseInside) [self mouseEntered:nil];
	}
}

//Cursor entered our view
- (void)mouseEntered:(NSEvent *)theEvent
{
	[[self cell] setHovered:YES];
	[self setNeedsDisplay:YES];

	[super mouseEntered:theEvent];
}


//Cursor left our view
- (void)mouseExited:(NSEvent *)theEvent
{
	[[self cell] setHovered:NO];
	[self setNeedsDisplay:YES];
	
	[super mouseExited:theEvent];
}

@end
