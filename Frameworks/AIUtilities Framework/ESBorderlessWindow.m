//ESBorderlessWindow.m based largely off sample code in CustomWindow.m from Apple's "RoundTransparentWindow" sample project.

#import "ESBorderlessWindow.h"

#define BORDERLESS_WINDOW_DOCKING_DISTANCE 	12	//Distance in pixels before the window is snapped to an edge

@interface ESBorderlessWindow (PRIVATE)
- (BOOL)dockWindowFrame:(NSRect *)inFrame toScreenFrame:(NSRect)screenFrame;
@end

@implementation ESBorderlessWindow

static	NSRect	windowFrame;
//In Interface Builder we set ESInvisibleWindow to be the class for our window, so our own initializer is called here.
- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {

    //Call NSWindow's version of this function, but pass in the all-important value of NSBorderlessWindowMask
    //for the styleMask so that the window doesn't have a title bar
    NSWindow *window = [super initWithContentRect:contentRect 
                                        styleMask:NSBorderlessWindowMask
                                          backing:NSBackingStoreBuffered 
                                            defer:flag];

    //Set the background color to clear so that we can see through the parts
    //of the window into which we're not drawing 
    [window setBackgroundColor:[NSColor clearColor]];
    //[window setOpaque:NO];
	
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
    
	if ([self delegate] && [[self delegate] respondsToSelector:@selector(windowShouldClose:)]){
        shouldClose = [(id)[self delegate] windowShouldClose:nil];
    } else if ([self respondsToSelector:@selector(windowShouldClose:)]){ 
        shouldClose = [(id)self windowShouldClose:nil];
	}
	
    if (shouldClose){
        [self close];
	}
}

//Once the user starts dragging the mouse with command held, we move the window with it. 
//We do this because the window has no title bar for the user to drag (so we have to implement dragging ourselves)
- (void)mouseDragged:(NSEvent *)theEvent
{
    if ([theEvent cmdKey]) {
        NSPoint		currentLocation;
		NSScreen	*currentScreen = [self screen];
        NSPoint		newOrigin = windowFrame.origin;
        NSRect		newWindowFrame = windowFrame;
		
        //Grab the current mouse location to compare with the location of the mouse when the drag started (stored in mouseDown:)
        currentLocation = [NSEvent mouseLocation];
        newOrigin.x += (currentLocation.x - previousLocation.x);
        newOrigin.y += currentLocation.y - previousLocation.y;
			
		//Keep the window from going under the menu bar (on the main screen)
		NSRect  screenFrame = [currentScreen visibleFrame];
		if (currentScreen == [[NSScreen screens] objectAtIndex:0]) {

			if((newOrigin.y+windowFrame.size.height) > (screenFrame.origin.y+screenFrame.size.height) ){
				
				newOrigin.y = screenFrame.origin.y + (screenFrame.size.height-windowFrame.size.height);
			}
		}
		
		// Keep the topmost part of the window on the screen (if it goes onto another screen in the process,
		// that screen should become [self screen] so this check shouldn't fire).
		if ((newOrigin.y+windowFrame.size.height) < 10 + screenFrame.origin.y ) {
            newOrigin.y = 10 + screenFrame.origin.y - windowFrame.size.height;
        }
  
		newWindowFrame.origin = newOrigin;

		//If the user is not pressing shift, attempt to dock this window the the visible frame first, and then to the screen frame
		if (![theEvent shiftKey]){
			[self dockWindowFrame:&newWindowFrame toScreenFrame:[currentScreen visibleFrame]];
			[self dockWindowFrame:&newWindowFrame toScreenFrame:[currentScreen frame]];
		}

		[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowWillMoveNotification object:self];
		[self setFrameOrigin:newWindowFrame.origin];
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
        previousLocation = [self convertBaseToScreen:[theEvent locationInWindow]];
		windowFrame = [self frame];
		
    } else {
        [super mouseDown:theEvent];
    }
}

//Dock the passed window frame if it's close enough to the screen edges
- (BOOL)dockWindowFrame:(NSRect *)windowFrame toScreenFrame:(NSRect)screenFrame
{
	BOOL	changed = NO;
	
	//Left
	if((abs(NSMinX((*windowFrame)) - NSMinX(screenFrame)) < BORDERLESS_WINDOW_DOCKING_DISTANCE)){
		(*windowFrame).origin.x = screenFrame.origin.x;
		changed = YES;
	}
	
	//Bottom
	if((abs(NSMinY(*windowFrame) - NSMinY(screenFrame)) < BORDERLESS_WINDOW_DOCKING_DISTANCE)){
		(*windowFrame).origin.y = screenFrame.origin.y;
		changed = YES;
	}
	
	//Right
	if((abs(NSMaxX(*windowFrame) - NSMaxX(screenFrame)) < BORDERLESS_WINDOW_DOCKING_DISTANCE)){
		(*windowFrame).origin.x -= NSMaxX(*windowFrame) - NSMaxX(screenFrame);
		changed = YES;
	}
	
	//Top
	if((abs(NSMaxY(*windowFrame) - NSMaxY(screenFrame)) < BORDERLESS_WINDOW_DOCKING_DISTANCE)){
		(*windowFrame).origin.y -= NSMaxY(*windowFrame) - NSMaxY(screenFrame);
		changed = YES;
	}
	
	return(changed);
}



@end
