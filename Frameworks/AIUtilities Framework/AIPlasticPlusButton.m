//
//  AIPlasticPlusButton.m
//  Adium
//
//  Created by Adam Iser on 8/9/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "AIPlasticPlusButton.h"


@implementation AIPlasticPlusButton

- (id)initWithFrame:(NSRect)frameRect
{
    [super initWithFrame:frameRect];
    [self setImage:[NSImage imageNamed:@"plus" forClass:[self class]]];
    return(self);    
}

@end
