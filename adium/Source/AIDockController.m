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

@implementation AIDockController
 
//init and close
- (void)initController
{
    
}

- (void)closeController
{

}

//icon family methods
- (AIIconFamily *)currentIconFamily
{

}
- (void)setIconFamily:(AIIconFamily *)iconFamily
{

}

//bouncing
- (void)bounce
{
    if([NSApplication instancesRespondToSelector:@selector(requestUserAttention:)])
    {
        [NSApp requestUserAttention:NSInformationalRequest];
    }
}
- (void)bounceWithInterval:(float)delay times:(int)num // if num = 0, bounce forever
{    
    if(delay == 0 && num == 0) //bouncing is constant and forvever
    {
        if([NSApplication instancesRespondToSelector:@selector(requestUserAttention:)])
        {
            [NSApp requestUserAttention:NSCriticalRequest];
        }
        
    }
    else //there is some kind of interval, we want to bounce a certain # of times, or both
    {
        if(num == 0) // bounce forever!! hard to stop as of yet
        {
            [NSTimer scheduledTimerWithTimeInterval:(double)delay target:self selector: @selector(bounceWithTimer) userInfo:nil repeats:YES];
        }
        else // bounce num # of times
        {
            for(int i = 1; i <= num; i ++) //install a bunch of timers to go off. again hard to stop.
            {
                [NSTimer scheduledTimerWithTimeInterval:(double)(delay*num) target:self selector: @selector(bounceWithTimer) userInfo:nil repeats:NO];
            }
        }
    }
}

- (void)stopBouncing //Only problem here is that we dont cancel bouncing forever.
{
        if([NSApplication instancesRespondToSelector:@selector(cancelUserAttentionRequest:)])
        {
            [NSApp cancelUserAttentionRequest:0];
        }
}

//PRIVATE ========

- (void)bounceWithTimer:(NSTimer *)timer
{
    [self bounce];
}

@end