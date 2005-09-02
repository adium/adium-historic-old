//AIBorderlessWindow.h based largely off sample code in CustomWindow.m from Apple's "RoundTransparentWindow" sample project.

#import "AIDockingWindow.h"

@interface AIBorderlessWindow : NSWindow
{
	BOOL	docked;
	
    //This point is used in dragging to mark the initial click location
    NSPoint originalMouseLocation;
	BOOL	inLeftMouseEvent;
}

@end
