//
//  ESFloater.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Oct 08 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 * @class ESFloater
 * @brief A programtically movable, fadable <tt>NSImage</tt> display class
 *
 * <tt>ESFloater</tt> allows for the display of an <tt>NSImage</tt>, including an animating one, anywhere on the screen.  The image can be easily moved programatically and will fade into and out of view as requested. 
 */
@interface ESFloater : NSObject {
    NSImageView			*staticView;
    NSPanel				*panel;
    BOOL                windowIsVisible;
    NSTimer             *visibilityTimer;
    float               maxOpacity;
}

+ (id)floaterWithImage:(NSImage *)inImage styleMask:(unsigned int)styleMask;
- (void)moveFloaterToPoint:(NSPoint)inPoint;
- (IBAction)close:(id)sender;
- (void)endFloater;
- (void)setImage:(NSImage *)inImage;
- (NSImage *)image;
- (void)setVisible:(BOOL)inVisible animate:(BOOL)animate;
- (void)setMaxOpacity:(float)inMaxOpacity;

@end
