//
//  AIIconState.m
//  Adium
//
//  Created by Adam Iser on Wed Apr 23 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIIconState.h"


@implementation AIIconState

//
- (id)initWithImages:(NSArray *)inImages delay:(float)inDelay looping:(BOOL)inLooping overlay:(BOOL)inOverlay
{
    [super init];

    image = nil;

    animated = YES;
    imageArray = [inImages retain];
    delay = inDelay;
    looping = inLooping;
    overlay = inOverlay;
    currentFrame = 0;
        
    return(self);
}

- (id)initWithImage:(NSImage *)inImage overlay:(BOOL)inOverlay
{
    [super init];

    imageArray = nil;
    delay = 0;
    looping = NO;
    currentFrame = 0;
    
    animated = NO;
    image = [inImage retain];
    overlay = inOverlay;

    return(self);
}

//Create a new icon state by combining/compositing others
- (id)initByCompositingStates:(NSArray *)iconStates
{
    NSEnumerator	*enumerator;
    AIIconState		*animatingState;
    AIIconState		*baseState;

    //Common setup
    [super init];
    imageArray = nil;
    image = nil;
    looping = NO;
    overlay = NO;
    currentFrame = 0;

    //Setup the base image (The image of the top-most non-overlay state)
    enumerator = [iconStates reverseObjectEnumerator];
    while((baseState = [enumerator nextObject]) && [baseState overlay]);
    if(baseState){ //Skip if no base-image
        //Setup the animation (Determined by the top-most animating state)
        enumerator = [iconStates reverseObjectEnumerator];
        while((animatingState = [enumerator nextObject]) && ![animatingState animated]);

        //Composite the images
        if(!animatingState){ //Static icon
                             //init
            delay = 0;
            animated = NO;

            //Create the image
            image = [[self _compositeStates:iconStates withBaseState:baseState animatingState:animatingState forFrame:0] retain];

        }else{ //Animating icon
            NSMutableArray	*mutableImageArray = [[NSMutableArray alloc] init];
            int			frames = [[animatingState imageArray] count];
            int			drawFrame;

            //init
            delay = [animatingState animationDelay];
            animated = YES;

            //Create the images
            for(drawFrame = 0; drawFrame < frames; drawFrame++){ //Create an image for each stage in animation
                [mutableImageArray addObject:[self _compositeStates:iconStates withBaseState:baseState animatingState:animatingState forFrame:drawFrame]];
            }
            imageArray = mutableImageArray;

        }
    }

    return(self);
}

- (NSImage *)_compositeStates:(NSArray *)iconStateArray withBaseState:(AIIconState *)baseState animatingState:(AIIconState *)animatingState forFrame:(int)frame
{
    NSEnumerator	*enumerator;
    NSImage		*workingImage;
    AIIconState		*iconState;
    
    //Use the base image as our starting point
    if([baseState animated]){
        if(baseState == animatingState){ //Only one state animates at a time
            workingImage = [[[baseState imageArray] objectAtIndex:frame] copy];
        }else{
            workingImage = [[[baseState imageArray] objectAtIndex:0] copy];
        }
    }else{
        workingImage = [[baseState image] copy];
    }

    //Draw on the images of all overlayed states
    enumerator = [iconStateArray objectEnumerator];
    while((iconState = [enumerator nextObject])){
        if([iconState overlay]){
            NSImage	*overlayImage;

            //Get the overlay image
            if([iconState animated]){
                if(iconState == animatingState){ //Only one state animates at a time
                    overlayImage = [[iconState imageArray] objectAtIndex:frame];
                }else{
                    overlayImage = [[iconState imageArray] objectAtIndex:0];
                }
            }else{
                overlayImage = [iconState image];
            }

            //Layer it ontop our working image
            [workingImage lockFocus];
            [overlayImage compositeToPoint:NSMakePoint(0,0) operation:NSCompositeSourceOver];
            [workingImage unlockFocus];
        }
    }

    return([workingImage autorelease]);    
}

- (int)currentFrame
{
    return(currentFrame);
}

- (void)nextFrame
{
    currentFrame++;
    if(currentFrame >= [imageArray
        count]){
        currentFrame = 0;
    }
}


- (BOOL)animated{
    return(animated);
}

- (float)animationDelay{
    return(delay);
}

- (BOOL)looping{
    return(looping);
}

- (BOOL)overlay{
    return(overlay);
}

- (NSArray *)imageArray{
    return(imageArray);
}

- (NSImage *)image{
    if(!animated){
        return(image);
    }else{
        return([imageArray objectAtIndex:currentFrame]);
    }
}

@end
