//
//  AIDockingWindow.h
//  Adium
//
//  Created by Adam Iser on Sun May 02 2004.
//

@interface AIDockingWindow : NSWindow {
	NSRect			oldWindowFrame;
	unsigned int	resisted_XMotion;
	unsigned int	resisted_YMotion;
}

@end
