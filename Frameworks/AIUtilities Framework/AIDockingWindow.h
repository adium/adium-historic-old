//
//  AIDockingWindow.h
//  Adium
//
//  Created by Adam Iser on Sun May 02 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

/*!
 * @class AIDockingWindow
 * @brief An NSWindow subclass which docks to screen edges
 *
 * An NSWindow subclass which docks to screen edges.
 */

@interface AIDockingWindow : NSWindow {
	NSRect			oldWindowFrame;
	unsigned int	resisted_XMotion;
	unsigned int	resisted_YMotion;
}

@end
