//
//  ESImageButton.h
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 10/16/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ESFloater;

/*!
 * @class ESImageButton
 * @brief Button which displays an image when clicked for use with an NSToolbarItem (<tt>MVMenuButton</tt> subclass)
 *
 * Button which displays an image when clicked for use as the custom view of an NSToolbarItem.  The image remains as long as the mouse button is held down; if it is an animating image, it will animate.  See <tt>MVMenuButton</tt> for the API.
 */
@interface ESImageButton : MVMenuButton {
	ESFloater	*imageFloater;
}

@end
