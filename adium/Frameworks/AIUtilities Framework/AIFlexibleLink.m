//
//  AIFlexibleLink.m
//  Adium
//
//  Created by Adam Iser on Mon Apr 07 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIFlexibleLink.h"


@implementation AIFlexibleLink

- (id)initWithTrackingRect:(NSRect)inTrackingRect url:(NSString *)inURL
{
    [super init];

    trackingRect = inTrackingRect;
    url = [inURL retain];

    return(self);
}

- (NSRect)trackingRect{
    return(trackingRect);
}

- (void)setTrackingTag:(NSTrackingRectTag)inTrackingTag
{
    trackingTag = inTrackingTag;
}

- (NSTrackingRectTag)trackingTag{
    return(trackingTag);
}

- (NSString *)url{
    return(url);
}

@end
