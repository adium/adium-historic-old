/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
#import <AIUtilities/AIUtilities.h>
#import "AIDockController.h"

#define DOCK_DEFAULT_PREFS	@"DockPrefs"

@interface AIDockController (PRIVATE)
- (void)_buildIcon;
- (void)animateIcon:(NSTimer *)timer;
- (void)_singleBounce;
- (void)_continuousBounce;
- (void)_stopBouncing;
- (void)_bounceWithInterval:(double)delay;
- (NSString *)_pathOfIconPackWithName:(NSString *)name;
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIDockController
 
//init and close
- (void)initController
{
    //init
    activeIconStateArray = nil;
    currentIconState = nil;
    currentAttentionRequest = -1;
    animationTimer = nil;
    bounceTimer = nil;

    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DOCK_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_SPELLING];

    //observe pref changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];

    //We always want to stop bouncing when Adium is made active
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillBecomeActive:) name:NSApplicationWillBecomeActiveNotification object:nil];
}

- (void)closeController
{
    //Set the icon to closed
//    [self setAppIcon:[iconFamily closedImage]];
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_GENERAL] == 0){
        NSDictionary 	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_GENERAL];
        NSString	*iconPath;

        //Take down the current icon
        [activeIconStateArray release]; activeIconStateArray = [[NSMutableArray alloc] init];
        [availableIconStateDict release]; availableIconStateDict = nil;

        //Configure the dock icon
        iconPath = [self _pathOfIconPackWithName:[preferenceDict objectForKey:KEY_ACTIVE_DOCK_ICON]];
        if(iconPath){
            availableIconStateDict = [[self iconPackAtPath:iconPath] retain];
        }

        //Composite the new icon
        [self setIconStateNamed:@"Base"];
        [self _buildIcon];
    }
}

//Icons ------------------------------------------------------------------------------------
//Load an icon pack
- (NSDictionary *)iconPackAtPath:(NSString *)folderPath
{
    NSMutableDictionary	*iconStateDict = [[[NSMutableDictionary alloc] init] autorelease];
    AIIconState		*iconState;
    NSDictionary	*iconPackDict;
    NSEnumerator	*stateEnumerator;
    NSString		*stateNameKey;

    //Load the icon pack
    iconPackDict = [NSDictionary dictionaryWithContentsOfFile:[folderPath stringByAppendingPathComponent:@"IconPack.plist"]];
    
    //Process each state in the icon pack
    stateEnumerator = [[[iconPackDict objectForKey:@"State"] allKeys] objectEnumerator];
    while((stateNameKey = [stateEnumerator nextObject])){
        NSDictionary	*stateDict = [[iconPackDict objectForKey:@"State"] objectForKey:stateNameKey];

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

                imagePath = [folderPath stringByAppendingPathComponent:imageName];
                image = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];

                if(image && [image isValid]) [imageArray addObject:image];
            }

            //Create the state
            if(delay != 0 && [imageArray count] != 0){
                iconState = [[[AIIconState alloc] initWithImages:imageArray delay:delay looping:looping overlay:overlay] autorelease];
                [iconStateDict setObject:iconState forKey:stateNameKey];
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
                [iconStateDict setObject:iconState forKey:stateNameKey];
            }else{
                NSLog(@"Invalid static icon state (%@)",stateNameKey);
            }
        }
    }

    return([NSDictionary dictionaryWithObjectsAndKeys:[iconPackDict objectForKey:@"Description"], @"Description", iconStateDict, @"State", nil]);
}

//Sets an icon state from the current icon pack.  If the state is already set or doesn't exist, nothing happens.
- (AIIconState *)setIconStateNamed:(NSString *)inName
{
    AIIconState	*iconState = [[availableIconStateDict objectForKey:@"State"] objectForKey:inName];

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

//Scan for an icon pack with the specified name
- (NSString *)_pathOfIconPackWithName:(NSString *)name
{
    NSDirectoryEnumerator	*fileEnumerator;
    NSString			*iconPath;
    NSString			*filePath;
    int					curPath;

    for (curPath = 0; curPath < 2; curPath ++)
    {
        //
        if (curPath == 0)
            iconPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:FOLDER_DOCK_ICONS];
        else
            iconPath = [[AIAdium applicationSupportDirectory] stringByAppendingPathComponent:FOLDER_DOCK_ICONS];
    
        //Find the desired .AdiumIcon
        fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:iconPath];
        while((filePath = [fileEnumerator nextObject])){
            if([[filePath pathExtension] caseInsensitiveCompare:@"AdiumIcon"] == 0 && [[[filePath lastPathComponent] stringByDeletingPathExtension] caseInsensitiveCompare:name] == 0){
                //Found a match, return the path
                return([iconPath stringByAppendingPathComponent:filePath]);
            }
        }
    }

    //No match found
    return(nil);
}

//Build/Pre-render the icon images, start/stop animation
- (void)_buildIcon
{
    //Stop any existing animation
    [animationTimer invalidate]; [animationTimer release]; animationTimer = nil;
    if(observingFlash){
        [[owner interfaceController] unregisterFlashObserver:self];
        observingFlash = NO;
    }
    
    //Generate the composited icon state
    [currentIconState release];
    currentIconState = [[[AIIconState alloc] initByCompositingStates:activeIconStateArray] retain];

    //
    if(![currentIconState animated]){ //Static icon
        if([currentIconState image]) [[NSApplication sharedApplication] setApplicationIconImage:[currentIconState image]];

    }else{ //Animated icon
        //Our dock icon can run its animation at any speed, but we want to try and sync it with the global Adium flashing.  To do this, we delay starting our timer until the next flash occurs.
        [[owner interfaceController] registerFlashObserver:self];
        observingFlash = YES;

        //Set the first frame of our animation
        [self animateIcon:nil]; //Set the icon and move to the next frame
    }
}

- (void)flash:(int)value
{
    //Start the flash timer
    animationTimer = [[NSTimer scheduledTimerWithTimeInterval:[currentIconState animationDelay]
                                                       target:self
                                                     selector:@selector(animateIcon:)
                                                     userInfo:nil
                                                      repeats:YES] retain];

    //Animate the icon
    [self animateIcon:animationTimer]; //Set the icon and move to the next frame

    //Once our animations stops, we no longer need to observe flashing
    [[owner interfaceController] unregisterFlashObserver:self];
    observingFlash = NO;
}

//Move the dock to the next animation frame (Assumes the current state is animated)
- (void)animateIcon:(NSTimer *)timer
{
    NSImage	*image;

    //Move to the next image
    if(timer){
        [currentIconState nextFrame];
    }

    //Set the image
    image = [currentIconState image];
    if(image) [[NSApplication sharedApplication] setApplicationIconImage:image];
    
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
        
    return(dockScale);
}


//Bouncing ------------------------------------------------------------------------------------
//Perform a bouncing behavior
- (void)performBehavior:(DOCK_BEHAVIOR)behavior
{
    //Stop any current behavior
    [self _stopBouncing];
    
    //Start up the new behavior
    switch(behavior){
        case BOUNCE_NONE: break;
        case BOUNCE_ONCE: [self _singleBounce]; break;
        case BOUNCE_REPEAT: [self _continuousBounce]; break;
        case BOUNCE_DELAY5: [self _bounceWithInterval:5.0]; break;
        case BOUNCE_DELAY10: [self _bounceWithInterval:10.0]; break;
        case BOUNCE_DELAY15: [self _bounceWithInterval:15.0]; break;
        case BOUNCE_DELAY30: [self _bounceWithInterval:30.0]; break;
        case BOUNCE_DELAY60: [self _bounceWithInterval:60.0]; break;
        default: break;
    }    
}

//Start a delayed bounce
- (void)_bounceWithInterval:(double)delay
{
    [self _singleBounce]; // do one right away

    bounceTimer = [[NSTimer scheduledTimerWithTimeInterval:delay
                                                    target:self
                                                  selector:@selector(bounceWithTimer:)
                                                  userInfo:nil
                                                   repeats:YES] retain];
}
- (void)bounceWithTimer:(NSTimer *)timer
{
    //Stop any current behavior
    [self _stopBouncing];

    //Bounce
    [self _singleBounce];
}

//Bounce once
- (void)_singleBounce
{
    if([NSApp respondsToSelector:@selector(requestUserAttention:)]){
        currentAttentionRequest = [NSApp requestUserAttention:NSInformationalRequest];
    }
}

//Bounce continuously
- (void)_continuousBounce
{
    if([NSApp respondsToSelector:@selector(requestUserAttention:)]){
        currentAttentionRequest = [NSApp requestUserAttention:NSCriticalRequest];
    }
}

//Stop bouncing
- (void)_stopBouncing
{
    //Stop any timer
    if(bounceTimer){
        [bounceTimer invalidate]; [bounceTimer release]; bounceTimer = nil;
    }

    //Stop any continuous bouncing
    if(currentAttentionRequest != -1){
        if([NSApp respondsToSelector:@selector(cancelUserAttentionRequest:)]){
            [NSApp cancelUserAttentionRequest:currentAttentionRequest];
        }
        currentAttentionRequest = -1;
    }
}

//
- (void)appWillBecomeActive:(NSNotification *)notification
{
    [self _stopBouncing]; //Stop any bouncing
}

@end
