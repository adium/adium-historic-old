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
//- (void)privBounce;
//- (void)bounceWithTimer:(NSTimer *)timer;
//- (void)bounceForeverWithTimer:(NSTimer *)timer;
//- (void)setAppIcon:(NSImage *)newIcon;
- (void)loadIconPackFromPath:(NSString *)folderPath;
- (void)_buildIcon;
- (void)animateIcon:(NSTimer *)timer;
@end

@implementation AIDockController
 
//init and close
- (void)initController
{
    NSString 	*familyPath;

    //init
    activeIconStateArray = [[NSMutableArray alloc] init];
    dockImageArray = [[NSMutableArray alloc] init];

    //Set the default icon
    familyPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Adiumy Icons/Adiumy Green.AdiumIcon"];
    [self loadIconPackFromPath:familyPath];
    [self _buildIcon];
}

- (void)closeController
{
    //Set the icon to closed
//    [self setAppIcon:[iconFamily closedImage]];
}




//Icons ------------------------------------------------------------------------------------
//Load an icon pack
- (void)loadIconPackFromPath:(NSString *)folderPath
{
    AIIconState		*iconState;
    NSDictionary	*iconPackDict;
    NSEnumerator	*stateEnumerator;
    NSString		*stateNameKey;
    
    //Flush the icon state dict
    [availableIconStateDict release];
    availableIconStateDict  = [[NSMutableDictionary alloc] init];

    //Load the icon pack
    iconPackDict = [NSDictionary dictionaryWithContentsOfFile:[folderPath stringByAppendingPathComponent:@"IconPack.plist"]];

    //Process each state in the icon pack
    stateEnumerator = [[iconPackDict allKeys] objectEnumerator];
    while((stateNameKey = [stateEnumerator nextObject])){
        NSDictionary	*stateDict = [iconPackDict objectForKey:stateNameKey];
        
        if([[stateDict objectForKey:@"Animated"] intValue]){ //Animated State
            NSEnumerator	*imageNameEnumerator;
            NSString		*imageName;
            NSMutableArray	*imageArray;
            BOOL		overlay, looping;
            float		delay;
            
            //Get the state information
            overlay = [[stateDict objectForKey:@"Overlay"] intValue];
            looping = [[stateDict objectForKey:@"Looping"] intValue];
            delay = [[stateDict objectForKey:@"Delay"] floatValue];
            imageNameEnumerator = [[stateDict objectForKey:@"Images"] objectEnumerator];
            
            //Load the images
            imageArray = [[[NSMutableArray alloc] init] autorelease];
            while((imageName = [imageNameEnumerator nextObject])){
                NSString	*imagePath;
                NSImage		*image;

                NSLog(@"Load:%@",imageName);

                imagePath = [folderPath stringByAppendingPathComponent:imageName];
                image = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];

                if(image && [image isValid]) [imageArray addObject:image];
            }

            //Create the state
            if(delay != 0 && [imageArray count] != 0){
                iconState = [[[AIIconState alloc] initWithImages:imageArray delay:delay looping:looping overlay:overlay] autorelease];
                [availableIconStateDict setObject:iconState forKey:stateNameKey];
            }else{
                NSLog(@"Invalid animated icon state (%@)",stateNameKey);
            }
            
            
        }else{ //Static State
            NSString	*imagePath;
            NSImage	*image;
            BOOL	overlay;

            //Get the state information
            imagePath = [stateDict objectForKey:@"Image"];
            image = [[[NSImage alloc] initWithContentsOfFile:[folderPath stringByAppendingPathComponent:imagePath]] autorelease];
            overlay = [[stateDict objectForKey:@"Overlay"] intValue];
            
            //Create the state
            if(image){
                iconState = [[[AIIconState alloc] initWithImage:image overlay:overlay] autorelease];
                [availableIconStateDict setObject:iconState forKey:stateNameKey];
            }else{
                NSLog(@"Invalid static icon state (%@)",stateNameKey);
            }
        }
    }
}

//Sets an icon state from the current icon pack.  If the state is already set or doesn't exist, nothing happens.
- (AIIconState *)setIconStateNamed:(NSString *)inName
{
    AIIconState	*iconState = [availableIconStateDict objectForKey:inName];

    [self setIconState:iconState];

    return(iconState);
}

//Sets a dynamically created icon state
- (void)setIconState:(AIIconState *)iconState
{
    if(iconState && ![activeIconStateArray containsObject:iconState]){ //Ignore duplicates and missing states
                                                                       //Keep track of it
        [activeIconStateArray addObject:iconState];

        //Rebuild our icon to incorporate the new state
        [self _buildIcon];
    }
}

//Removes an active icon state
- (void)removeIconState:(AIIconState *)inState
{
    if([activeIconStateArray containsObject:inState]){
        //Remove the state
        [activeIconStateArray removeObject:inState];

        //Rebuild our icon to remove any instances of the state
        [self _buildIcon];
    }
}


//Build/Pre-render the icon images, start/stop animation
- (void)_buildIcon
{
    NSEnumerator	*enumerator;
    NSImage		*workingImage;
    AIIconState		*iconState;
    AIIconState		*animatingState;
    float		animationDelay;
    int			drawFrame;
    AIIconState		*startingState;

    //Release the current images
    [dockImageArray release];
    dockImageArray = [[NSMutableArray alloc] init];
    
    //Find the newest animating state (It will control the animation)
    enumerator = [activeIconStateArray reverseObjectEnumerator];
    while((animatingState = [enumerator nextObject]) && ![animatingState animated]);

    //If there is an animating state, set up the animation timers
    [animationTimer invalidate]; [animationTimer release]; animationTimer = nil;
    if(animatingState){
        animationDelay = [animatingState animationDelay];
        animationFrames = [[animatingState imageArray] count];
        animationTimer = [[NSTimer scheduledTimerWithTimeInterval:animationDelay
                                                           target:self
                                                         selector:@selector(animateIcon:)
                                                         userInfo:nil
                                                          repeats:YES] retain];
    }else{
        animationFrames = 1;
    }
    
    //Take the the newest non-overlay state's image
    enumerator = [activeIconStateArray reverseObjectEnumerator];
    while((startingState = [enumerator nextObject]) && [startingState overlay]);

    //If no non-overlay states are set, use the base state
    if(!startingState) startingState = [availableIconStateDict objectForKey:@"Base"]; 

    if(startingState){ //Abort if no image
        for(drawFrame = 0; drawFrame < animationFrames; drawFrame++){ //Create an image for each stage in animation
    
            //Use the starting state's image as our base
            if([startingState animated]){
                if(startingState == animatingState){
                    workingImage = [[[[startingState imageArray] objectAtIndex:drawFrame] copy] autorelease];
                }else{
                    workingImage = [[[[startingState imageArray] objectAtIndex:0] copy] autorelease];
                }
            }else{
                workingImage = [[[startingState image] copy] autorelease];
            }
    
            //Draw on the images of all overlayed states
            enumerator = [activeIconStateArray objectEnumerator];
            while((iconState = [enumerator nextObject])){
                if([iconState overlay]){
                    NSImage	*overlayImage;
                    
                    //Get the overlay image
                    if([iconState animated]){
                        if(iconState == animatingState){ //Only one state animates at a time
                            overlayImage = [[iconState imageArray] objectAtIndex:drawFrame];
                        }else{
                            overlayImage = [[iconState imageArray] objectAtIndex:0];
                        }
                    }else{
                        overlayImage = [iconState image];
                    }
    
                    //Layer it ontop our working image
                    [workingImage lockFocus];
                    [overlayImage compositeToPoint:NSMakePoint(0,0) operation:NSCompositeSourceOver];
                    [workingImage unlockFocus];
                }
            }
    
            [dockImageArray addObject:workingImage];
        }

        //Set the finished icon
        currentFrame = 0;
        [self animateIcon:nil];
    }
}

//Move the dock to the next animation frame
- (void)animateIcon:(NSTimer *)timer
{
    //Set the image
    [[NSApplication sharedApplication] setApplicationIconImage:[dockImageArray objectAtIndex:currentFrame]];

    //Move to the next image
    currentFrame++;
    if(currentFrame >= animationFrames){
        currentFrame = 0;
    }
}


//returns the % of the dock icon's full size that it currently is (0.0 - 1.0)
- (float)dockIconScale
{
    NSSize trueSize = [[NSScreen mainScreen] visibleFrame].size;
    NSSize availableSize = [[NSScreen mainScreen] frame].size;

    int	dHeight = availableSize.height - trueSize.height;
    int dWidth = availableSize.width - trueSize.width;
    float dockScale = 0;

    if(dHeight != 22){ //dock is on the bottom
        if(dHeight == 26){ //dock is hidden
        }else{ //dock is not hidden
            dockScale = (dHeight-22)/128.0;
        }
    }else if(dWidth != 0){ //dock is on the side
        if(dWidth == 4){ //dock is hidden
        }else{ //dock is not hidden
            dockScale = (dWidth)/128.0;
        }
    }else{
        //multiple monitors?
        //Add support for multiple monitors
    }

    if(dockScale <= 0 || dockScale > 1.0){
        dockScale = 0.3;
    }
    
    NSLog(@"%0.2f",dockScale);
    
    return(dockScale);
}



/*


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

//bouncing methods
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

- (void)appWillBecomeActive:(NSNotification *)notification
{
    if (currentIcon == [iconFamily alertImage])
        [self setAppIcon:[iconFamily openedImage]];
}*/

@end
