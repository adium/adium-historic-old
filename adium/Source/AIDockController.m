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
        int temp = [NSApp requestUserAttention:NSCriticalRequest];
        NSTimer *waitTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(cancelBouncingForTimer:) userInfo:[NSNumber numberWithInt:temp] repeats:NO];
        NSLog(@"staring wait");
        BOOL cont = NO;
        while(cont)
        {
            if(![waitTimer isValid])
            {
                cont = YES;
            }
        }
        NSLog(@"ending wait");
    }
}

- (void)bounceWithInterval:(double)delay forever:(BOOL)booly
{       
    NSLog(@"5");
    [self bounce]; // do one right away
    
    currentTimer = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector: @selector(bounceWithTimer:) userInfo:[NSNumber numberWithInt:4] repeats:NO];
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
    }
}
- (void)bounceWithTimer:(NSTimer *)timer
{
    NSLog(@"%d", [[timer userInfo] intValue]);
    
    [self bounce];
    
    if([[timer userInfo] intValue] > 1)
    {
        currentTimer = [NSTimer scheduledTimerWithTimeInterval:[timer timeInterval] target:self selector: @selector(bounceWithTimer:) userInfo:[NSNumber numberWithInt:[[timer userInfo] intValue]-1] repeats:NO];    
    }

}

@end