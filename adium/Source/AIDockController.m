/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import <Adium/Adium.h>
#import "AIDockController.h"

@interface AIDockController (PRIVATE)
- (void)privBounce;
- (void)bounceWithTimer:(NSTimer *)timer;
- (void)bounceForeverWithTimer:(NSTimer *)timer;
- (void)setAppIcon:(NSImage *)newIcon;
@end

@implementation AIDockController
 
//init and close
- (void)initController
{
    NSString *familyPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Default Icon Family.adiumIconFamily"];
    currentTimer = nil;
    [self setIconFamily:[AIIconFamily iconFamilyFromFolder:familyPath]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillBecomeActive:) name:NSApplicationWillBecomeActiveNotification object:nil];
}

- (void)closeController
{

}

//icon family methods
- (AIIconFamily *)currentIconFamily
{
    return iconFamily;
}

- (void)setIconFamily:(AIIconFamily *)newIconFamily
{
    [self setIconFamily:newIconFamily initializingClosed:NO];
}

- (void)setIconFamily:(AIIconFamily *)newIconFamily initializingClosed:(BOOL)closed
{
    [iconFamily release];
    iconFamily = [newIconFamily retain];
    if (closed) {
        [self setAppIcon:[iconFamily closedImage]];
    } else {
        [self setAppIcon:[iconFamily openedImage]];
    }
}

- (void)alert
{
    [self setAppIcon:[iconFamily alertImage]];
    [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(resetAppIcon:) userInfo:nil repeats:NO];
}

- (void)setAppIcon:(NSImage *)newIcon
{
    [currentIcon release];
    currentIcon = [newIcon retain];

    [[owner notificationCenter] postNotification:[NSNotification notificationWithName:Dock_IconWillChange object:newIcon]];
    [[NSApplication sharedApplication] setApplicationIconImage:newIcon];
    [[owner notificationCenter] postNotification:[NSNotification notificationWithName:Dock_IconDidChange object:newIcon]];
}

//bouncing
- (void)bounce //for external use only.
{
    [self privBounce];
    [self alert];
}

- (void)bounceWithInterval:(double)delay times:(int)num
{       
    if(!currentTimer)
    {
        [self privBounce]; // do one right away
        [self alert];
    
        currentTimer = [NSTimer scheduledTimerWithTimeInterval:delay+1 target:self selector: @selector(bounceWithTimer:) userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:delay],@"delay",[NSNumber numberWithInt:num-1],@"num",nil] repeats:NO]; // delay+1 so we take into account the time it takes to bounce. num-1 to because we did one already.
    }
}

- (void)bounceForeverWithInterval:(double)delay
{
    if(!currentTimer && ![NSApp isActive])
    {
        [self privBounce]; // do one right away
        [self alert];

        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(startEternalTimer:) userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:delay], @"delay", nil] repeats:NO];
    }
}

- (void)stopBouncing
{
    if([currentTimer isValid])
    {
        [currentTimer invalidate];
        currentTimer = nil;
    }
    else if(currentTimer)
    {
        currentTimer = nil;
    }
}

//PRIVATE ========

- (void)privBounce
{
    if([NSApp respondsToSelector:@selector(requestUserAttention:)])
    {
        [NSApp requestUserAttention:NSInformationalRequest];
    }
}

- (void)startEternalTimer:(NSTimer *)timer
{
    double delay = [[[timer userInfo] objectForKey:@"delay"] doubleValue];
    currentTimer = [NSTimer scheduledTimerWithTimeInterval:delay+1 target:self selector: @selector(bounceForeverWithTimer:) userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:delay],@"delay",nil] repeats:YES]; // delay+1 so we take into account the time it takes to bounce.

    if ([timer isValid])
        [timer invalidate];
}

- (void)bounceWithTimer:(NSTimer *)timer
{
    [self privBounce];
    [self alert];
    
    if([[[timer userInfo] objectForKey:@"num"] intValue] > 1)
    {
        currentTimer = [NSTimer scheduledTimerWithTimeInterval:[[[timer userInfo] objectForKey:@"delay"] doubleValue] target:self selector:@selector(bounceWithTimer:) userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:[[[timer userInfo] objectForKey:@"num"] intValue]-1],@"num",[[timer userInfo] objectForKey:@"delay"],@"delay",nil] repeats:NO];
    }
    else
    {
        currentTimer = nil;
    }

}

- (void)bounceForeverWithTimer:(NSTimer *)timer
{
    if ([NSApp isActive])
    {
        [timer invalidate];
        currentTimer = nil;
    } else {
        [self privBounce];
        [self alert];
    }
}

- (void)resetAppIcon:(NSTimer *)timer
{
    [self setAppIcon:[iconFamily openedImage]];
}

- (void)appWillTerminate:(NSNotification *)notification
{
    [self setAppIcon:[iconFamily closedImage]];
}

- (void)appWillBecomeActive:(NSNotification *)notification
{
    if (currentIcon == [iconFamily alertImage])
        [self setAppIcon:[iconFamily openedImage]];
}

@end
