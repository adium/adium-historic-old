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

- (void)bounceWithInterval:(double)delay forever:(BOOL)booly
{       
    if(!currentTimer)
    {
        NSLog(@"5");
        [self privBounce]; // do one right away
    
        currentTimer = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector: @selector(bounceWithTimer:) userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:delay],@"delay",[NSNumber numberWithInt:4],@"num",nil] repeats:NO];
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
        int temp = [NSApp requestUserAttention:NSCriticalRequest];
        sleep(1);
        if([NSApp respondsToSelector:@selector(cancelUserAttentionRequest:)])
        {
            [NSApp cancelUserAttentionRequest:temp];
        }
    }
}

- (void)bounceWithTimer:(NSTimer *)timer
{
    NSLog(@"%d", [[[timer userInfo] objectForKey:@"num"] intValue]);
    
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

@end