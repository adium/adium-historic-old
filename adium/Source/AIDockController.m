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
    return nil;
}
- (void)setIconFamily:(AIIconFamily *)iconFamily
{

}

//bouncing
- (void)bounce
{
    if([NSApp respondsToSelector:@selector(requestUserAttention:)])
    {
        int temp = [NSApp requestUserAttention:NSInformationalRequest];
        NSTimer *waitTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(cancelBouncingForTimer:) userInfo:[NSNumber numberWithInt:temp] repeats:NO];
    }
}

- (void)bounceWithInterval:(double)delay times:(int)num // if num = 0, bounce forever
{   
    //we aren't using NSCriticalRequest because it's a pain in the butt to cancel. 
    
    if(num == 0) // bounce forever!!
    {
        //currentTimer = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector: @selector(bounceWithTimer:) userInfo:0 repeats:YES];
    }
    else // bounce num # of times
    {
        currentTimer = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector: @selector(bounceWithTimer:) userInfo:[NSNumber numberWithInt:num] repeats:NO];
    }
}

- (void)stopBouncing
{
    if([currentTimer isValid])
    {
        [currentTimer invalidate];
    }
}

//PRIVATE ========

- (void)cancelBouncingForTimer:(NSTimer *)timer
{
    if([NSApp respondsToSelector:@selector(cancelUserAttentionRequest:)] && [timer isValid])
    {
        [NSApp cancelUserAttentionRequest:[[timer userInfo] intValue]];
        NSLog(@"canceled");
    }
    NSLog(@"not canclled");
}
- (void)bounceWithTimer:(NSTimer *)timer
{
    [self bounce];
    if([timer isValid])
    {
        if([[timer userInfo] intValue] > 1)
        {
            [self bounceWithInterval:[timer timeInterval] times:([[timer userInfo] intValue]-1)];
        }
    }
}

@end