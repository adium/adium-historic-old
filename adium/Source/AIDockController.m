/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

// $Id: AIDockController.m,v 1.56 2004/06/05 06:51:24 evands Exp $

#import "AIDockController.h"

#define DOCK_DEFAULT_PREFS	@"DockPrefs"
#define ICON_DISPLAY_DELAY	0.1

@interface AIDockController (PRIVATE)
- (void)_setNeedsDisplay;
- (void)_buildIcon;
- (void)animateIcon:(NSTimer *)timer;
- (void)_singleBounce;
- (void)_continuousBounce;
- (void)_stopBouncing;
- (void)_bounceWithInterval:(double)delay;
- (NSString *)_pathOfIconPackWithName:(NSString *)name;
- (void)preferencesChanged:(NSNotification *)notification;
- (AIIconState *)iconStateFromStateDict:(NSDictionary *)stateDict folderPath:(NSString *)folderPath;
@end

@implementation AIDockController
 
#define DOCK_THEMABLE_PREFS      @"Dock Themable Prefs"

//init and close
- (void)initController
{
    //init
    activeIconStateArray = [[NSMutableArray alloc] initWithObjects:@"Base",nil];
    availableDynamicIconStateDict = [[NSMutableDictionary alloc] init];
    currentIconState = nil;
    currentAttentionRequest = -1;
    animationTimer = nil;
    bounceTimer = nil;
    needsDisplay = NO;

    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DOCK_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_GENERAL];
    
    //Observe pref changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];

    //We always want to stop bouncing when Adium is made active
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillChangeActive:) name:NSApplicationWillBecomeActiveNotification object:nil];

    //We also stop bouncing when Adium is no longer active
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillChangeActive:) name:NSApplicationWillResignActiveNotification object:nil];

    
}

- (void)closeController
{
    NSArray		*stateArrayCopy;
    NSEnumerator	*enumerator;
    NSString		*iconState;

    //Reset our icon by removing all icon states (except for the base state)
    stateArrayCopy = [[activeIconStateArray copy] autorelease]; //Work with a copy, since this array will change as we remove states
    enumerator = [stateArrayCopy objectEnumerator];
    [enumerator nextObject]; //Skip the first icon
    while(iconState = [enumerator nextObject]){
        [self removeIconStateNamed:iconState];
    }

    //Force the icon to update
    [self _buildIcon];
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_GENERAL] == 0){
        NSString	*key = [[notification userInfo] objectForKey:@"Key"];
        
        if(notification == nil || (key && [key compare:KEY_ACTIVE_DOCK_ICON] == 0)){
            NSDictionary        *preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_GENERAL];
            NSMutableDictionary	*newAvailableIconStateDict;
            NSString		*iconPath;
            
            //Load the new icon pack
            iconPath = [self _pathOfIconPackWithName:[preferenceDict objectForKey:KEY_ACTIVE_DOCK_ICON]];
            if(iconPath){
                if(newAvailableIconStateDict = [[self iconPackAtPath:iconPath] retain]){
                    [availableIconStateDict release]; availableIconStateDict = newAvailableIconStateDict;
                }
            }
    
#ifdef MAC_OS_X_VERSION_10_0
            //Write the icon to the Adium application bundle so finder will see it
			NSString	    *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
			NSString		*lastLaunchedVersion = [[owner preferenceController] preferenceForKey:KEY_LAST_VERSION_LAUNCHED
																							group:PREF_GROUP_GENERAL];
			
			//On launch we only need to update the icon file if this is a new version of Adium.  When preferences
			//change we always want to update it
			if(notification != nil || !lastLaunchedVersion || !version || [lastLaunchedVersion compare:version] != 0){
                NSString		*icnsPath = [[NSBundle mainBundle] pathForResource:@"Adium" ofType:@"icns"];
                IconFamily		*iconFamily;
                NSImage			*image;

				image = [[[availableIconStateDict objectForKey:@"State"] objectForKey:@"Base"] image];
                if(image){
                    iconFamily = [IconFamily iconFamilyWithThumbnailsOfImage:image usingImageInterpolation:NSImageInterpolationLow];
                    [iconFamily writeToFile:icnsPath];
                }

				//Remember the version of Adium this image was set for, so we don't need to do it again
				if(version){
					[[owner preferenceController] setPreference:version
														 forKey:KEY_LAST_VERSION_LAUNCHED
														  group:PREF_GROUP_GENERAL];
				}
			}
#endif
            //Recomposite the icon
            [self _setNeedsDisplay];
        }
    }
}

//Icons ------------------------------------------------------------------------------------
- (void)_setNeedsDisplay
{
    if(!needsDisplay){
        needsDisplay = YES;

        //Invoke a display after a short delay
        [NSTimer scheduledTimerWithTimeInterval:ICON_DISPLAY_DELAY
                                         target:self
                                       selector:@selector(_buildIcon)
                                       userInfo:nil
                                        repeats:NO];
    }
}

//Load an icon pack
- (NSMutableDictionary *)iconPackAtPath:(NSString *)folderPath
{
    NSMutableDictionary	*iconStateDict;
    NSDictionary		*iconPackDict;
    NSEnumerator		*stateNameKeyEnumerator;
    NSString			*stateNameKey;

    //Load the icon pack
    iconPackDict = [NSDictionary dictionaryWithContentsOfFile:[folderPath stringByAppendingPathComponent:@"IconPack.plist"]];

    //Process each state in the icon pack, adding it to the iconStateDict
	iconStateDict = [NSMutableDictionary dictionary];
	
    stateNameKeyEnumerator = [[[iconPackDict objectForKey:@"State"] allKeys] objectEnumerator];
    while((stateNameKey = [stateNameKeyEnumerator nextObject])){
		NSDictionary	*stateDict;
		AIIconState		*iconState;
		
		stateDict = [[iconPackDict objectForKey:@"State"] objectForKey:stateNameKey];
		iconState = [self iconStateFromStateDict:stateDict folderPath:folderPath];
		if (iconState){
			[iconStateDict setObject:[self iconStateFromStateDict:stateDict folderPath:folderPath] forKey:stateNameKey];
		}
	}
	
	return([NSMutableDictionary dictionaryWithObjectsAndKeys:[iconPackDict objectForKey:@"Description"], @"Description", iconStateDict, @"State", nil]);
}

- (AIIconState *)previewStateForIconPackAtPath:(NSString *)folderPath
{
	NSDictionary	*iconPackDict;
	NSDictionary	*stateDict;
	
	//Load the icon pack
    iconPackDict = [NSDictionary dictionaryWithContentsOfFile:[folderPath stringByAppendingPathComponent:@"IconPack.plist"]];
	
	//Load the preview state
	stateDict = [[iconPackDict objectForKey:@"State"] objectForKey:@"Preview"];
	
	return ([self iconStateFromStateDict:stateDict folderPath:folderPath]);
}

- (AIIconState *)iconStateFromStateDict:(NSDictionary *)stateDict folderPath:(NSString *)folderPath
{
	AIIconState		*iconState = nil;
	
	if([[stateDict objectForKey:@"Animated"] intValue]){ //Animated State
		NSMutableDictionary	*tempIconCache = [NSMutableDictionary dictionary];
		NSArray				*imageNameArray;
		NSEnumerator		*imageNameEnumerator;
		NSString			*imageName;
		NSMutableArray		*imageArray;
		BOOL				overlay, looping;
		float				delay;
		
		//Get the state information
		overlay = [[stateDict objectForKey:@"Overlay"] intValue];
		looping = [[stateDict objectForKey:@"Looping"] intValue];
		delay = [[stateDict objectForKey:@"Delay"] floatValue];
		imageNameArray = [stateDict objectForKey:@"Images"];
		imageNameEnumerator = [imageNameArray objectEnumerator];
		
		//Load the images
		imageArray = [NSMutableArray arrayWithCapacity:[imageNameArray count]];
		while((imageName = [imageNameEnumerator nextObject])){
			NSString	*imagePath;
			NSImage		*image;
			
			imagePath = [folderPath stringByAppendingPathComponent:imageName];
			
			image = [tempIconCache objectForKey:imagePath]; //We re-use the same images for each state if possible to lower memory usage.
			if(!image){
				image = [[[NSImage alloc] initByReferencingFile:imagePath] autorelease];
				if(image) [tempIconCache setObject:image forKey:imagePath];
			}
			
			if(image && [image isValid]){
				[imageArray addObject:image];
			}else{
				NSLog(@"Failed to load image %@",imagePath);
			}
		}
		
		//Create the state
		if(delay != 0 && [imageArray count] != 0){
			iconState = [[AIIconState alloc] initWithImages:imageArray
													  delay:delay
													looping:looping
													overlay:overlay];
		}else{
			NSLog(@"Invalid animated icon state (%@)",imageName);
		}
		
	}else{ //Static State
		NSString	*imagePath;
		NSImage	*image;
		BOOL	overlay;
		
		//Get the state information
		imagePath = [stateDict objectForKey:@"Image"];
		image = [[[NSImage alloc] initByReferencingFile:[folderPath stringByAppendingPathComponent:imagePath]] autorelease];
		overlay = [[stateDict objectForKey:@"Overlay"] intValue];
		
		//Create the state
		if(image){
			iconState = [[AIIconState alloc] initWithImage:image overlay:overlay];
		}else{
			NSLog(@"Invalid static icon state (%@)",imagePath);
		}
	}

	return ([iconState autorelease]);
}

//Set an icon state from our currently loaded icon pack
- (void)setIconStateNamed:(NSString *)inName
{
    if(![activeIconStateArray containsObject:inName]){
        [activeIconStateArray addObject:inName]; 	//Add the name to our array
        [self _setNeedsDisplay];			//Redisplay our icon
    }
}

//Remove an active icon state
- (void)removeIconStateNamed:(NSString *)inName
{
    if([activeIconStateArray containsObject:inName]){
        [activeIconStateArray removeObject:inName]; 	//Remove the name from our array
        
        [self _setNeedsDisplay];			//Redisplay our icon
    }
}

//Set a custom icon state
- (void)setIconState:(AIIconState *)iconState named:(NSString *)inName
{
    [availableDynamicIconStateDict setObject:iconState forKey:inName]; 	//Add the new state to our available dict
    [self setIconStateNamed:inName];					//Set it
}

//Scan for an icon pack with the specified name
- (NSString *)_pathOfIconPackWithName:(NSString *)name
{
    NSEnumerator			*resPathEnumerator = [[[AIObject sharedAdiumInstance] resourcePathsForName:FOLDER_DOCK_ICONS] objectEnumerator];
    NSDirectoryEnumerator	*dirEnumerator;
    NSString				*iconsDir;
    NSString				*iconPack;

    while(iconsDir = [resPathEnumerator nextObject]) {
        //Find the desired .AdiumIcon
        dirEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:iconsDir];
        while((iconPack = [dirEnumerator nextObject])){
            if([[iconPack pathExtension] caseInsensitiveCompare:@"AdiumIcon"] == 0 && [[[iconPack lastPathComponent] stringByDeletingPathExtension] caseInsensitiveCompare:name] == 0){
                //Found a match, return the path
                return([iconsDir stringByAppendingPathComponent:iconPack]);
            }
        }
    }

    //No match found
    return(nil);
}

//Build/Pre-render the icon images, start/stop animation
- (void)_buildIcon
{
    NSMutableArray	*iconStates = [NSMutableArray array];
    NSDictionary	*availableIcons;
    NSEnumerator	*enumerator;
    AIIconState		*state;
    NSString		*name;

    //Stop any existing animation
    [animationTimer invalidate]; [animationTimer release]; animationTimer = nil;
    if(observingFlash){
        [[owner interfaceController] unregisterFlashObserver:self];
        observingFlash = NO;
    }

    //Build an array of the valid active icon states
    availableIcons = [availableIconStateDict objectForKey:@"State"];
    enumerator = [activeIconStateArray objectEnumerator];
    while(name = [enumerator nextObject]){
        if((state = [availableIcons objectForKey:name]) || (state = [availableDynamicIconStateDict objectForKey:name])){
            [iconStates addObject:state];
        }
    }

    //Generate the composited icon state
    [currentIconState release];
    currentIconState = [[AIIconState alloc] initByCompositingStates:iconStates];

    //
    if(![currentIconState animated]){ //Static icon
		NSImage *image = [currentIconState image];
        if(image) {
			 [[NSApplication sharedApplication] setApplicationIconImage:image];
		}

    }else{ //Animated icon
        //Our dock icon can run its animation at any speed, but we want to try and sync it with the global Adium flashing.  To do this, we delay starting our timer until the next flash occurs.
        [[owner interfaceController] registerFlashObserver:self];
        observingFlash = YES;

        //Set the first frame of our animation
        [self animateIcon:nil]; //Set the icon and move to the next frame
    }

    needsDisplay = NO;
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
	if(image) {
		[[NSApplication sharedApplication] setApplicationIconImage:image];
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

    return(dockScale);
}


//Bouncing -------------------------------------------------------------------------------------------------------------
#pragma mark Bouncing
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

//Return a string description of the bouncing behavior
- (NSString *)descriptionForBehavior:(DOCK_BEHAVIOR)behavior
{
	NSString	*desc;
	
    switch(behavior){
        case BOUNCE_NONE: desc=@"None"; break;
        case BOUNCE_ONCE: desc=@"Once"; break;
        case BOUNCE_REPEAT: desc=@"Repeatedly"; break;
        case BOUNCE_DELAY5: desc=@"Every 5 Seconds"; break;
        case BOUNCE_DELAY10: desc=@"Every 10 Seconds"; break;
        case BOUNCE_DELAY15: desc=@"Every 15 Seconds"; break;
        case BOUNCE_DELAY30: desc=@"Every 30 Seconds"; break;
        case BOUNCE_DELAY60: desc=@"Every 60 Seconds"; break;
        default: desc=@"Invalid"; break;
    }    
	
	return(AILocalizedString(desc,""));
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

//Activated by the time after each delay
- (void)bounceWithTimer:(NSTimer *)timer
{
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
- (void)appWillChangeActive:(NSNotification *)notification
{
    [self _stopBouncing]; //Stop any bouncing
}

@end
