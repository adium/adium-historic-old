//
//  AITooltipUtilities.m
//  Adium
//
//  Created by Adam Iser on Thu Apr 10 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AITooltipUtilities.h"
#import "AIAttributedStringAdditions.h"

#define TOOLTIP_MAX_WIDTH	250

@interface AITooltipUtilities (PRIVATE)
+ (void)_createTooltip;
+ (void)_closeTooltip;
+ (void)_sizeTooltip;
+ (NSPoint)_tooltipFrameOrigin;
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

            [self _sizeTooltip];

        }else{
            //Update the existing tooltip's string and or position
            if([inString compare:tooltipString] != 0){
                tooltipPoint = inPoint;
                [tooltipString release]; tooltipString = [inString retain];
                [textField_tooltip setStringValue:tooltipString];
                [self _sizeTooltip];
            }
            if(!NSEqualPoints(inPoint,tooltipPoint)){
                tooltipPoint = inPoint;
                [tooltipWindow setFrameOrigin:[self _tooltipFrameOrigin]];
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

+ (void)_sizeTooltip
{
    NSRect	tooltipRect;
    NSPoint	origin;

    //Set up the tooltip's bounds
    [textField_tooltip sizeToFit];
    tooltipRect = [textField_tooltip bounds];
    
    if(tooltipRect.size.width > TOOLTIP_MAX_WIDTH){
        NSAttributedString	*attrString = [[[NSAttributedString alloc] initWithString:tooltipString] autorelease];

        tooltipRect.size.width = TOOLTIP_MAX_WIDTH;
        tooltipRect.size.height = [attrString heightWithWidth:TOOLTIP_MAX_WIDTH];

        [textField_tooltip setFrameSize:tooltipRect.size];
    }

    //Set the origin
    origin = [self _tooltipFrameOrigin];
    tooltipRect.origin.x = origin.x;
    tooltipRect.origin.y = origin.y;
    
    //Apply the frame change and ensure the tip is visible
    [tooltipWindow setFrame:tooltipRect display:YES];
    if(![tooltipWindow isVisible]){
        [tooltipWindow makeKeyAndOrderFront:nil];
    }
}

+ (NSPoint)_tooltipFrameOrigin
{
    NSRect	screenRect = [[NSScreen mainScreen] visibleFrame]; //use tooltip/window screen, not main screen!
    NSRect	tooltipRect = [textField_tooltip bounds];

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

    return(tooltipRect.origin);
}

@end
