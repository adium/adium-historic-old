//ESBorderlessWindow.m based largely off sample code in CustomWindow.m from Apple's "RoundTransparentWindow" sample project.

#import "ESBorderlessWindow.h"

#define BORDERLESS_WINDOW_DOCKING_DISTANCE 	20	//Distance in pixels before the window is snapped to an edge

@interface ESBorderlessWindow (PRIVATE)
- (BOOL)dockWindowFrame:(NSRect *)inFrame toScreenFrame:(NSRect)screenFrame movementX:(float)movementX movementY:(float)movementY;
@end

@implementation ESBorderlessWindow

//In Interface Builder we set ESInvisibleWindow to be the class for our window, so our own initializer is called here.
- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {

    //Call NSWindow's version of this function, but pass in the all-important value of NSBorderlessWindowMask
    //for the styleMask so that the window doesn't have a title bar
    NSWindow *window = [super initWithContentRect:contentRect 
                                        styleMask:NSBorderlessWindowMask /*NSTitledWindowMask*/
                                          backing:NSBackingStoreBuffered 
                                            defer:flag];

    //Set the background color to clear so that (along with the setOpaque call below) we can see through the parts
    //of the window that we're not drawing into
    [window setBackgroundColor:[NSColor clearColor]];
    
    return window;
}

// Custom windows that use the NSBorderlessWindowMask can't become key by default.  Therefore, controls in such windows
// won't ever be enabled by default.  Thus, we override this method to change that.
- (BOOL)canBecomeKeyWindow
{
    return YES;
}

- (BOOL)canBecomeMainWindow
{
    return YES;
}

- (void)performClose:(id)sender
{ 
    BOOL shouldClose = YES;
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(windowShouldClose:)])
        shouldClose = [(id)[self delegate] windowShouldClose:nil];
    else if ([self respondsToSelector:@selector(windowShouldClose:)])
        shouldClose = [(id)self windowShouldClose:nil];
    if (shouldClose)
        [self close];    
}

//Once the user starts dragging the mouse with command held, we move the window with it. 
//We do this because the window has no title bar for the user to drag (so we have to implement dragging ourselves)
- (void)mouseDragged:(NSEvent *)theEvent
{
    if ([theEvent cmdKey]) {
        NSPoint		currentLocation;

		NSScreen	*currentScreen = [self screen];
        NSRect		windowFrame = [self frame];
        NSPoint		newOrigin = windowFrame.origin;
        
        //grab the current global mouse location; we could just as easily get the mouse location 
        //in the same way as we do in -mouseDown:
        currentLocation = [self convertBaseToScreen:[self mouseLocationOutsideOfEventStream]];
//        NSLog(@"mouse was (%f,%f) now (%f,%f) move of (%f,%f) newOrigin will be (%f,%f)",previousLocation.x,previousLocation.y,currentLocation.x,currentLocation.y,currentLocation.x - previousLocation.x,currentLocation.y - previousLocation.y,newOrigin.x +(currentLocation.x - previousLocation.x),newOrigin.y+(currentLocation.y - previousLocation.y));
float movementX = currentLocation.x - previousLocation.x;
float movementY = currentLocation.y - previousLocation.y;
        newOrigin.x += movementX;
        newOrigin.y += movementY;
        previousLocation = currentLocation;
		
		//        NSLog(@"%f + %f > %f + %f",newOrigin.y,windowFrame.size.height,screenFrame.origin.y,screenFrame.size.height);
		
		//Keep the window from going under the menu bar (on the main screen)
		if (currentScreen == [[NSScreen screens] objectAtIndex:0]) {
			NSRect  screenFrame = [currentScreen visibleFrame];
			if( (newOrigin.y+windowFrame.size.height) > (screenFrame.origin.y+screenFrame.size.height) ){
				
				newOrigin.y = screenFrame.origin.y + (screenFrame.size.height-windowFrame.size.height);
			}
		}
		
		// Keep the topmost part of the window on the screen (if it goes onto another screen in the process,
		// that screen should become [self screen] so this check shouldn't fire).
		if ( (newOrigin.y+windowFrame.size.height) < 10 ) {
            newOrigin.y = 10 - windowFrame.size.height;
        }
  
//		NSLog(@"%f + %f = %f ; screenFrame width is %f",newOrigin.x,windowFrame.size.width,(newOrigin.x + windowFrame.size.width),screenFrame.size.width);

		/*
        if((newOrigin.x + windowFrame.size.width) < 1)
            newOrigin.x = 1 - windowFrame.size.width;
        */
		
		//Attempt to dock this window the the visible frame first, and then to the screen frame
		windowFrame.origin = newOrigin;
		
		[self dockWindowFrame:&windowFrame toScreenFrame:[currentScreen visibleFrame] movementX:movementX movementY:movementY];
		[self dockWindowFrame:&windowFrame toScreenFrame:[currentScreen frame] movementX:movementX movementY:movementY];

		[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowWillMoveNotification object:self];
		[self setFrameOrigin:windowFrame.origin];
		[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidMoveNotification object:self];
		
    } else {
        [super mouseDragged:theEvent];
    }
}

//We start tracking the a drag operation here when the user first clicks the mouse with command presed,
//to establish the initial location.
- (void)mouseDown:(NSEvent *)theEvent
{    
    if ([theEvent cmdKey]) {
        //grab the mouse location in global coordinates
        previousLocation = [self convertBaseToScreen:[self mouseLocationOutsideOfEventStream]];
		
    } else {
        [super mouseDown:theEvent];
    }
}

//Dock the passed window frame if it's close enough to the screen edges
- (BOOL)dockWindowFrame:(NSRect *)windowFrame toScreenFrame:(NSRect)screenFrame movementX:(float)movementX movementY:(float)movementY
{
	BOOL	changed = NO;
	//Left
	if((abs(NSMinX((*windowFrame)) - NSMinX(screenFrame)) < BORDERLESS_WINDOW_DOCKING_DISTANCE) && movementX < 0){
		(*windowFrame).origin.x = screenFrame.origin.x;
		changed = YES;
	}
	
	//Bottom
	if((abs(NSMinY(*windowFrame) - NSMinY(screenFrame)) < BORDERLESS_WINDOW_DOCKING_DISTANCE) && movementY < 0){
//	NSLog(@"%f %f (%i) versus %i setting %f to %f",NSMinY(windowFrame),NSMinY(screenFrame),(abs(NSMinY(windowFrame) - NSMinY(screenFrame))),BORDERLESS_WINDOW_DOCKING_DISTANCE,windowFrame.origin.y,screenFrame.origin.y);
		(*windowFrame).origin.y = screenFrame.origin.y;
		changed = YES;
	}
	
	//Right
	if((abs(NSMaxX(*windowFrame) - NSMaxX(screenFrame)) < BORDERLESS_WINDOW_DOCKING_DISTANCE) && movementX > 0){
		(*windowFrame).origin.x -= NSMaxX(*windowFrame) - NSMaxX(screenFrame);
		changed = YES;
	}
	
	//Top
	if((abs(NSMaxY(*windowFrame) - NSMaxY(screenFrame)) < BORDERLESS_WINDOW_DOCKING_DISTANCE) && movementY > 0){
		(*windowFrame).origin.y -= NSMaxY(*windowFrame) - NSMaxY(screenFrame);
		changed = YES;
	}
	
	return(changed);
}



@end
