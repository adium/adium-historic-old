//
//  AIDockingWindow.h
//  Adium
//
//  Created by Adam Iser on Sun May 02 2004.
//

/*!
	@class AIDockingWindow
	@abstract An NSWindow subclass which docks to screen edges
	@discussion An NSWindow subclass which docks to screen edges.
*/

@interface AIDockingWindow : NSWindow {
	NSRect			oldWindowFrame;
	unsigned int	resisted_XMotion;
	unsigned int	resisted_YMotion;
}

@end
