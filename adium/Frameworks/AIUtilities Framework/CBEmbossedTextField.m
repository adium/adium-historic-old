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
    NSAttributedString		*text;
    NSColor			*textColor;
    
    textColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.4];
    
    text = [[NSAttributedString alloc] initWithString:[self stringValue] 
        attributes:[NSDictionary dictionaryWithObjectsAndKeys:
            textColor, NSForegroundColorAttributeName,
            font, NSFontAttributeName, nil]];
            
    [text drawInRect:NSOffsetRect(inRect, 0, -1)];
    
    textColor = [NSColor colorWithCalibratedWhite:0.16 alpha:1.0];
    
    text = [[NSAttributedString alloc] initWithString:[self stringValue] 
    attributes:[NSDictionary dictionaryWithObjectsAndKeys:
        textColor, NSForegroundColorAttributeName,
        font, NSFontAttributeName, nil]];
        
    [text drawInRect:inRect];

}
@end
