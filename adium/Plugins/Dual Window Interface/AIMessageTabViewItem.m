//
//  AIMessageTabViewItem.m
//  Adium
//
//  Created by Adam Iser on Sun Jan 05 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIMessageTabViewItem.h"


@implementation AIMessageTabViewItem

- (void)drawLabel:(BOOL)shouldTruncateLabel inRect:(NSRect)labelRect
{
    [[self label] drawInRect:labelRect withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
}

- (NSSize)sizeOfLabel:(BOOL)computeMin
{
    return([[self label] sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:nil]]);
}

@end
