//
//  AITooltipUtilities.m
//  Adium
//
//  Created by Adam Iser on Thu Apr 10 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AITooltipUtilities.h"


@interface AITooltipUtilities (PRIVATE)
+ (void)_createTooltip;
+ (void)_closeTooltip;
+ (void)_positionAndSizeTooltip;
@end

@implementation AITooltipUtilities

static	NSPanel		*tooltipWindow;
static	NSTextField	*textField_tooltip;
static	NSString	*tooltipString;
static	NSPoint		tooltipPoint;

//Tooltips
+ (void)showTooltipWithString:(NSString *)inString onWindow:(NSWindow *)inWindow atPoint:(NSPoint)inPoint
{    
    if(inString){ //If passed a string
        if(!tooltipString){
            [self _createTooltip];

            tooltipPoint = inPoint;
            [tooltipString release]; tooltipString = [inString retain];
            [textField_tooltip setStringValue:tooltipString];

            [self _positionAndSizeTooltip];

        }else{
            //Update the existing tooltip's string and or position
            if([inString compare:tooltipString] != 0){
                [tooltipString release]; tooltipString = [inString retain];
                [textField_tooltip setStringValue:tooltipString];
                [self _positionAndSizeTooltip];
            }
            if(!NSEqualPoints(inPoint,tooltipPoint)){
                tooltipPoint = inPoint;
                [self _positionAndSizeTooltip];
            }
        }

    }else{ //If passed a nil string, hide any existing tooltip
        if(tooltipString){
            [self _closeTooltip];
        }

    }

}

//Create the tooltip
+ (void)_createTooltip
{
    //Create the window
    tooltipWindow = [[NSPanel alloc] initWithContentRect:NSMakeRect(0,0,0,0) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    [tooltipWindow setFloatingPanel:YES];
    [tooltipWindow setHidesOnDeactivate:NO];
    [tooltipWindow setBackgroundColor:[NSColor colorWithCalibratedRed:1.000 green:1.000 blue:0.800 alpha:1.0]];
    [tooltipWindow setAlphaValue:0.9];
    [tooltipWindow setHasShadow:YES];

    //Add a text field
    textField_tooltip = [[NSTextField alloc] initWithFrame:NSMakeRect(0,0,0,0)];
    [textField_tooltip setFont:[NSFont labelFontOfSize:11]];
    [textField_tooltip setBordered:NO];
    [textField_tooltip setBezeled:NO];
    [textField_tooltip setSelectable:NO];
    [textField_tooltip setDrawsBackground:NO];
    [[tooltipWindow contentView] addSubview:textField_tooltip];
}

+ (void)_closeTooltip
{
    [tooltipWindow orderOut:nil];
    [textField_tooltip release]; textField_tooltip = nil;
    [tooltipWindow release]; tooltipWindow = nil;
    [tooltipString release]; tooltipString = nil;
    tooltipPoint = NSMakePoint(0,0);
}

+ (void)_positionAndSizeTooltip
{
#warning use tooltip/window screen, not main screen
    NSRect	screenRect = [[NSScreen mainScreen] visibleFrame];
    NSRect	tooltipRect;

    //Set up the tooltip's bounds
    [textField_tooltip sizeToFit];
    tooltipRect.size.width = [textField_tooltip bounds].size.width;
    tooltipRect.size.height = [textField_tooltip bounds].size.height;

    //Adjust the tooltip so it fits completely on the screen
    if(tooltipPoint.x > (screenRect.origin.x + screenRect.size.width - tooltipRect.size.width)){
        tooltipRect.origin.x = tooltipPoint.x - 2 - tooltipRect.size.width;
    }else{
        tooltipRect.origin.x = tooltipPoint.x + 10;
    }

    if(tooltipPoint.y < (screenRect.origin.y + tooltipRect.size.height)){
        tooltipRect.origin.y = tooltipPoint.y + 2;
    }else{
        tooltipRect.origin.y = tooltipPoint.y - 2 - tooltipRect.size.height;
    }

    //Apply the frame change and ensure the tip is visible
    [tooltipWindow setFrame:tooltipRect display:YES];
    if(![tooltipWindow isVisible]){
        [tooltipWindow makeKeyAndOrderFront:nil];
    }
}

@end
