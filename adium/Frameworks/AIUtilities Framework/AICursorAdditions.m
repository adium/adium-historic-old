//
//  AICursorAdditions.m
//  Adium
//
//  Created by Adam Iser on Mon Apr 07 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AICursorAdditions.h"
#import "AIImageUtilities.h"

@implementation NSCursor (AICursorAdditions)

//I'm passing [AIImageUtilities class] to imageNamed:forClass so the image is loaded from the AIUtilities framework.  Since this class consists of additions to NSCursor, using [self class] will search for the image in NSCursor's framework's bundle, which is wrong.

+ (NSCursor *)openGrabHandCursor
{
    static NSCursor 	*openGrabHandCursor = nil;

    if(!openGrabHandCursor){
        openGrabHandCursor = [[NSCursor alloc] initWithImage:[AIImageUtilities imageNamed:@"OpenGrabHandCursor" forClass:[AIImageUtilities class]] hotSpot:NSMakePoint(8,8)];
    }

    return(openGrabHandCursor);
}

+ (NSCursor *)closedGrabHandCursor
{
    static NSCursor 	*closedGrabHandCursor = nil;

    if(!closedGrabHandCursor){
        closedGrabHandCursor = [[NSCursor alloc] initWithImage:[AIImageUtilities imageNamed:@"ClosedGrabHandCursor" forClass:[AIImageUtilities class]] hotSpot:NSMakePoint(8,8)];
    }

    return(closedGrabHandCursor);
}

+ (NSCursor *)handPointCursor
{
    static NSCursor 	*handPointCursor = nil;

    if(!handPointCursor){
        handPointCursor = [[NSCursor alloc] initWithImage:[AIImageUtilities imageNamed:@"HandPointCursor" forClass:[AIImageUtilities class]] hotSpot:NSMakePoint(5,0)];
    }

    return(handPointCursor);
}


@end
