//
//  AIPlasticMinusButton.m
//  Adium
//
//  Created by Adam Iser on 8/9/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "AIPlasticMinusButton.h"


@implementation AIPlasticMinusButton

- (id)initWithFrame:(NSRect)frameRect
{
    [super initWithFrame:frameRect];
    [self setImage:[NSImage imageNamed:@"minus" forClass:[self class]]];
    return(self);    
}

@end
