//
//  AIIconState.h
//  Adium
//
//  Created by Adam Iser on Wed Apr 23 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AIIconState : NSObject {
    BOOL	animated;
    BOOL	overlay;

    //Static
    NSImage	*image;

    //Animated
    NSArray	*imageArray;
    float	delay;
    BOOL 	looping;

}
- (id)initWithImages:(NSArray *)inImages delay:(float)inDelay looping:(BOOL)inLooping overlay:(BOOL)inOverlay;
- (id)initWithImage:(NSImage *)inImage overlay:(BOOL)inOverlay;
- (BOOL)animated;
- (float)animationDelay;
- (BOOL)looping;
- (BOOL)overlay;
- (NSArray *)imageArray;
- (NSImage *)image;
    
@end

