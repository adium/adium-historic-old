//
//  ESFloater.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Wed Oct 08 2003.//

#import "ESFloater.h"
#import "AIEventAdditions.h"

#define WINDOW_FADE_FPS                         30.0
#define WINDOW_FADE_STEP                        0.4
#define WINDOW_FADE_SLOW_STEP                   0.1
#define WINDOW_FADE_MAX                         1.0
#define WINDOW_FADE_MIN                         0.0

@interface ESFloater (PRIVATE)
- (id)initWithImage:(NSImage *)inImage frame:(BOOL)frame;
@end

@implementation ESFloater

//
+ (id)floaterWithImage:(NSImage *)inImage frame:(BOOL)frame
{
    return([[self alloc] initWithImage:inImage frame:frame]);
}

//
- (id)initWithImage:(NSImage *)inImage frame:(BOOL)showFrame
{
    NSRect  frame;
    
    //Init
    [super init];
    windowIsVisible = NO;
    visibilityTimer = nil;
    maxOpacity = WINDOW_FADE_MAX;
    
    //Set up the panel
    frame = NSMakeRect(0, 0, [inImage size].width, [inImage size].height);    
    panel = [[NSPanel alloc] initWithContentRect:frame
                                       styleMask:((showFrame ? NSTitledWindowMask : NSBorderlessWindowMask) | NSTexturedBackgroundWindowMask)
                                         backing:NSBackingStoreBuffered
                                           defer:NO];
    [panel setHidesOnDeactivate:NO];
    [panel setIgnoresMouseEvents:YES];
    [panel setOpaque:NO];
    [panel setLevel:NSStatusWindowLevel];
    [panel setAlphaValue:WINDOW_FADE_MIN];
    [panel setHasShadow:NO];
    
    //Setup the static view
    staticView = [[ESStaticView alloc] initWithFrame:frame image:inImage];
    [staticView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [[panel contentView] addSubview:[staticView autorelease]];
    
    return(self);
}

//
- (void)moveFloaterToPoint:(NSPoint)inPoint
{
    [panel setFrameOrigin:inPoint];
    [panel orderFront:nil];
}

//
- (void)setImage:(NSImage *)inImage
{
    NSRect frame = [panel frame];
    frame.size = NSMakeSize([inImage size].width, [inImage size].height);
    [staticView setImage:inImage];
    [panel setFrame:frame display:YES animate:NO];
}

//
- (NSImage *)image
{
    return [staticView image];
}

//
- (void)endFloater
{
    [self close:nil];   
}

//
- (IBAction)close:(id)sender
{
    [visibilityTimer invalidate]; [visibilityTimer release]; visibilityTimer = nil;
    [panel orderOut:nil];
    [panel release]; panel = nil;

    [self release];
}

//
- (void)setMaxOpacity:(float)inMaxOpacity
{
    maxOpacity = inMaxOpacity;
    if(windowIsVisible) [panel setAlphaValue:maxOpacity];
}

//Window Visibility --------------------------------------------------------------------------------------------------
//Update the visibility of this window (Window is visible if there are any tabs present)
- (void)setVisible:(BOOL)inVisible animate:(BOOL)animate
{    
    if(inVisible != windowIsVisible){
        windowIsVisible = inVisible;
        
        if(animate){
            if(!visibilityTimer){
                visibilityTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0/WINDOW_FADE_FPS) target:self selector:@selector(_updateWindowVisiblityTimer:) userInfo:nil repeats:YES] retain];
            }
        }else{
            [panel setAlphaValue:(windowIsVisible ? maxOpacity : WINDOW_FADE_MIN)];
        }
    }
}

//Smoothly 
- (void)_updateWindowVisiblityTimer:(NSTimer *)inTimer
{
    float   alphaValue = [panel alphaValue];
    
    if(windowIsVisible){
        alphaValue += (maxOpacity - alphaValue) * ([NSEvent shiftKey] ? WINDOW_FADE_SLOW_STEP : WINDOW_FADE_STEP);
        if(alphaValue > maxOpacity) alphaValue = maxOpacity;
    }else{
        alphaValue -= (alphaValue - WINDOW_FADE_MIN) * ([NSEvent shiftKey] ? WINDOW_FADE_SLOW_STEP : WINDOW_FADE_STEP);
        if(alphaValue < WINDOW_FADE_MIN) alphaValue = WINDOW_FADE_MIN;
    }
    [panel setAlphaValue:alphaValue];
    
    //
    if(alphaValue == maxOpacity && alphaValue == WINDOW_FADE_MIN){
        [visibilityTimer invalidate]; [visibilityTimer release]; visibilityTimer = nil;
    }
}


@end



