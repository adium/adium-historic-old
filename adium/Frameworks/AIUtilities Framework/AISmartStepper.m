//
//  AISmartStepper.m
//  Adium
//
//  Created by Adam Iser on Sat Jul 26 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AISmartStepper.h"


@implementation AISmartStepper

- (void)mouseDown:(NSEvent *)theEvent
{
    id	textField = [self target];

    //Update our value from the field
    [self setObjectValue:[textField objectValue]];

    //Mouse down
    [super mouseDown:theEvent];

    //Give focus to our field
    if([[self window] firstResponder] != textField){
        [[self window] makeFirstResponder:textField];
    }
}


@end
