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
    currentTimer = nil;
}

- (void)closeController
{

}

//icon family methods
- (AIIconFamily *)currentIconFamily
{
    return nil;
}
- (void)setIconFamily:(AIIconFamily *)iconFamily
{

}

//bouncing
- (void)bounce //for external use only.
{
    [self privBounce];
}

- (void)bounceWithInterval:(double)delay times:(int)num
{       
    if(!currentTimer)
    {
        [self privBounce]; // do one right away
    
        currentTimer = [NSTimer scheduledTimerWithTimeInterval:delay+1 target:self selector: @selector(bounceWithTimer:) userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:delay],@"delay",[NSNumber numberWithInt:num-1],@"num",nil] repeats:NO]; // delay+1 so we take into account the time it takes to bounce. num-1 to because we did one already.
    }
}

- (void)bounceForeverWithInterval:(double)delay
{
    if(!currentTimer && ![NSApp isActive])
    {
        [self privBounce]; // do one right away

        currentTimer = [NSTimer scheduledTimerWithTimeInterval:delay+1 target:self selector: @selector(bounceForeverWithTimer:) userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:delay],@"delay",nil] repeats:YES]; // delay+1 so we take into account the time it takes to bounce. num-1 to because we did one already.
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

- (void)bounceWithTimer:(NSTimer *)timer
{
    [self privBounce];
    
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
    }
}

- (void)setAppIcon:(NSImage *)newIcon
{
    [[NSApplication sharedApplication] setApplicationIconImage:newIcon];
}

@end
