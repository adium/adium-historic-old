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
    int		currentFrame;

}
- (id)initWithImages:(NSArray *)inImages delay:(float)inDelay looping:(BOOL)inLooping overlay:(BOOL)inOverlay;
- (id)initWithImage:(NSImage *)inImage overlay:(BOOL)inOverlay;
- (id)initByCompositingStates:(NSArray *)iconStates;
- (BOOL)animated;
- (float)animationDelay;
- (BOOL)looping;
- (BOOL)overlay;
- (NSArray *)imageArray;
- (NSImage *)image;
- (NSImage *)_compositeStates:(NSArray *)iconStateArray withBaseState:(AIIconState *)baseState animatingState:(AIIconState *)animatingState forFrame:(int)frame;
- (int)currentFrame;
- (void)nextFrame;

@end

