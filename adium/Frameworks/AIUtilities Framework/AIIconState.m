//
//  AIIconState.m
//  Adium
//
//  Created by Adam Iser on Wed Apr 23 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIIconState.h"


@implementation AIIconState

- (id)initWithImages:(NSArray *)inImages delay:(float)inDelay looping:(BOOL)inLooping overlay:(BOOL)inOverlay
{
    [super init];

    image = nil;

    animated = YES;
    imageArray = [inImages retain];
    delay = inDelay;
    looping = inLooping;
    overlay = inOverlay;
        
    return(self);
}

- (id)initWithImage:(NSImage *)inImage overlay:(BOOL)inOverlay
{
    [super init];

    imageArray = nil;
    delay = 0;
    looping = NO;
    
    animated = NO;
    image = [inImage retain];
    overlay = inOverlay;

    return(self);
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
    return(image);
}

@end
