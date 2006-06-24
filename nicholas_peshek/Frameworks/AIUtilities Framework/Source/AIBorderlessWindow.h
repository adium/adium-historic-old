//AIBorderlessWindow.h based largely off sample code in CustomWindow.m from Apple's "RoundTransparentWindow" sample project.

#import "AIDockingWindow.h"

#define BORDERLESS_WINDOW_DOCKING_DISTANCE 	12	//Distance in pixels before the window is snapped to an edge

@interface AIBorderlessWindow : NSWindow
{
    //This point is used in dragging to mark the initial click location
    NSPoint originalMouseLocation;

	NSRect	windowFrame;

	BOOL	docked;
	BOOL	inLeftMouseEvent;
	BOOL	moveable;
}

- (void)setMoveable:(BOOL)inMoveable;
- (BOOL)dockWindowFrame:(NSRect *)inWindowFrame toScreenFrame:(NSRect)inScreenFrame;

@end
