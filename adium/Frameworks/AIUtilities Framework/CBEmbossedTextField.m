//
//  CBEmbossedTextField.m
//  Adium
//
//  Created by Colin Barrett on Fri Jul 11 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "CBEmbossedTextField.h"


@implementation CBEmbossedTextField

- (void)drawRect:(NSRect)inRect
{
    NSFont			*font = [NSFont boldSystemFontOfSize:11];
    NSRect			bounds = [self bounds];
    NSDictionary		*attributes;
    NSColor			*textColor;

    textColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.4];
    attributes = [NSDictionary dictionaryWithObjectsAndKeys:
            textColor, NSForegroundColorAttributeName,
            font, NSFontAttributeName, nil];
            
    [[self stringValue] drawInRect:NSOffsetRect(bounds, +2, +1) withAttributes:attributes];

    
    textColor = [NSColor colorWithCalibratedWhite:0.16 alpha:1.0];
    attributes = [NSDictionary dictionaryWithObjectsAndKeys:
        textColor, NSForegroundColorAttributeName,
        font, NSFontAttributeName, nil];

    [[self stringValue] drawInRect:NSOffsetRect(bounds, +2, 0) withAttributes:attributes];

}

@end
