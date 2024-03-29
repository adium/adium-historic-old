/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

// $Id$

#import "AIDockController.h"
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <Adium/AIIconState.h>
#import <Adium/IconFamily.h>

#define DOCK_DEFAULT_PREFS			@"DockPrefs"
#define ICON_DISPLAY_DELAY			0.1

#define LAST_ICON_UPDATE_VERSION	@"Adium:Last Icon Update Version"

#define CONTINUOUS_BOUNCE_INTERVAL  0
#define SINGLE_BOUNCE_INTERVAL		999
#define NO_BOUNCE_INTERVAL			1000

@interface AIDockController (PRIVATE)
- (void)_setNeedsDisplay;
- (void)_buildIcon;
- (void)animateIcon:(NSTimer *)timer;
- (void)_singleBounce;
- (BOOL)_continuousBounce;
- (void)_stopBouncing;
- (BOOL)_bounceWithInterval:(double)delay;
- (void)preferencesChanged:(NSNotification *)notification;
- (AIIconState *)iconStateFromStateDict:(NSDictionary *)stateDict folderPath:(NSString *)folderPath;
- (void)updateAppBundleIcon;
@end

@implementation AIDockController
 
//init and close
- (id)init
{
	if ((self = [super init])) {
		activeIconStateArray = [[NSMutableArray alloc] initWithObjects:@"Base",nil];
		availableDynamicIconStateDict = [[NSMutableDictionary alloc] init];
		currentIconState = nil;
		currentAttentionRequest = -1;
		currentBounceInterval = NO_BOUNCE_INTERVAL;
		animationTimer = nil;
		bounceTimer = nil;
		needsDisplay = NO;
	}
	
	return self;
}

- (void)controllerDidLoad
{
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
    //Register our default preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DOCK_DEFAULT_PREFS
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_APPEARANCE];
    
    //Observe pref changes
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_APPEARANCE];
	
    //We always want to stop bouncing when Adium is made active
    [notificationCenter addObserver:self
	                       selector:@selector(appWillChangeActive:) 
	                           name:NSApplicationWillBecomeActiveNotification 
	                         object:nil];
	
    //We also stop bouncing when Adium is no longer active
    [notificationCenter addObserver:self
	                       selector:@selector(appWillChangeActive:) 
	                           name:NSApplicationWillResignActiveNotification 
	                         object:nil];
	
	//If Adium has been upgraded since the last time we ran, re-apply the user's custom icon
	NSString	*lastVersion = [[NSUserDefaults standardUserDefaults] objectForKey:LAST_ICON_UPDATE_VERSION];
	if (![[NSApp applicationVersion] isEqualToString:lastVersion]) {
		[self updateAppBundleIcon];
		[[NSUserDefaults standardUserDefaults] setObject:[NSApp applicationVersion] forKey:LAST_ICON_UPDATE_VERSION];
	}
}

- (void)controllerWillClose
{
	[[adium preferenceController] unregisterPreferenceObserver:self];

	NSArray			*stateArrayCopy;
	NSEnumerator	*enumerator;
	NSString		*iconState;

	//Reset our icon by removing all icon states (except for the base state)
	stateArrayCopy = [activeIconStateArray copy]; //Work with a copy, since this array will change as we remove states
	enumerator = [stateArrayCopy objectEnumerator];
	[enumerator nextObject]; //Skip the first icon
	while ((iconState = [enumerator nextObject])) {
		[self removeIconStateNamed:iconState];
	}

	//Force the icon to update
	[self _buildIcon];

	[stateArrayCopy release];
}


/*!
 * @brief Returns an array of available dock icon pack paths
 */
- (NSArray *)availableDockIconPacks
{
	NSEnumerator * folderPathEnumerator = [[adium allResourcesForName:FOLDER_DOCK_ICONS withExtensions:@"AdiumIcon"] objectEnumerator];
	NSMutableArray * iconPackPaths = [NSMutableArray array]; //this will be the folder path for old packs, and the bundle resource path for new
	NSString * path;
	NSBundle * xtraBundle;
	while ((path = [folderPathEnumerator nextObject])) {
		xtraBundle = [NSBundle bundleWithPath:path];
		if (xtraBundle && ([[xtraBundle objectForInfoDictionaryKey:@"XtraBundleVersion"] intValue] == 1))//This checks for a new-style xtra
			path = [xtraBundle resourcePath];
		[iconPackPaths addObject:path];
	}
	return iconPackPaths;
}



- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if (!key || [key isEqualToString:KEY_ACTIVE_DOCK_ICON]) {
		NSMutableDictionary	*newAvailableIconStateDict;
		NSString			*iconPath;
		
		//Load the new icon pack
		iconPath = [adium pathOfPackWithName:[prefDict objectForKey:KEY_ACTIVE_DOCK_ICON]
								   extension:@"AdiumIcon"
						  resourceFolderName:FOLDER_DOCK_ICONS];

		if (iconPath) {
			if ((newAvailableIconStateDict = [[self iconPackAtPath:iconPath] retain])) {
				[availableIconStateDict release]; availableIconStateDict = newAvailableIconStateDict;
			}
		}
		
		//Write the icon to the Adium application bundle so finder will see it
		//On launch we only need to update the icon file if this is a new version of Adium.  When preferences
		//change we always want to update it
		if (!firstTime) {
			[self updateAppBundleIcon];
		}

		//Recomposite the icon
		[self _setNeedsDisplay];
	}
}

- (void)updateAppBundleIcon
{
	NSImage			*image;
	
	image = [[[availableIconStateDict objectForKey:@"State"] objectForKey:@"ApplicationIcon"] image];
	if (!image) image = [[[availableIconStateDict objectForKey:@"State"] objectForKey:@"Base"] image];

	if (image) {
		[[NSWorkspace sharedWorkspace] setIcon:image 
									   forFile:[[NSBundle mainBundle] bundlePath]
									   options:0];

		//Finder won't update Adium's icon to match the new one until it is restarted if we don't
		//tell NSWorkspace to note the change.
		[[NSWorkspace sharedWorkspace] noteFileSystemChanged:[[NSBundle mainBundle] bundlePath]];
	}
}

//Icons ------------------------------------------------------------------------------------
- (void)_setNeedsDisplay
{
    if (!needsDisplay) {
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
    while ((stateNameKey = [stateNameKeyEnumerator nextObject])) {
		NSDictionary	*stateDict;
		AIIconState		*iconState;
		
		stateDict = [[iconPackDict objectForKey:@"State"] objectForKey:stateNameKey];
		if ((iconState = [self iconStateFromStateDict:stateDict folderPath:folderPath])) {
			[iconStateDict setObject:iconState forKey:stateNameKey];
		}
	}
	
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:[iconPackDict objectForKey:@"Description"], @"Description", iconStateDict, @"State", nil];
}

/*!
 * @brief Get the name and preview steate for a dock icon pack
 *
 * @param outName Reference to an NSString, or NULL if this information is not needed
 * @param outIconState Reference to an AIIconState, or NULL if this information is not needed
 * @param folderPath The path to the dock icon pack
 */
- (void)getName:(NSString **)outName previewState:(AIIconState **)outIconState forIconPackAtPath:(NSString *)folderPath
{
	NSDictionary	*iconPackDict;
	NSDictionary	*stateDict;
	
	//Load the icon pack
    iconPackDict = [NSDictionary dictionaryWithContentsOfFile:[folderPath stringByAppendingPathComponent:@"IconPack.plist"]];
	
	//Load the preview state
	stateDict = [[iconPackDict objectForKey:@"State"] objectForKey:@"Preview"];
	
	if (outIconState) *outIconState = [self iconStateFromStateDict:stateDict folderPath:folderPath];
	if (outName) *outName = [[iconPackDict objectForKey:@"Description"] objectForKey:@"Title"];
}

- (AIIconState *)previewStateForIconPackAtPath:(NSString *)folderPath
{
	AIIconState	*previewState = nil;
	
	[self getName:NULL previewState:&previewState forIconPackAtPath:folderPath];
	
	return previewState;
}

- (AIIconState *)iconStateFromStateDict:(NSDictionary *)stateDict folderPath:(NSString *)folderPath
{
	AIIconState		*iconState = nil;
	
	if ([[stateDict objectForKey:@"Animated"] intValue]) { //Animated State
		NSMutableDictionary	*tempIconCache = [NSMutableDictionary dictionary];
		NSArray				*imageNameArray;
		NSEnumerator		*imageNameEnumerator;
		NSString			*imageName;
		NSMutableArray		*imageArray;
		BOOL				overlay, looping;
		float				delay;
		
		//Get the state information
		overlay = [[stateDict objectForKey:@"Overlay"] boolValue];
		looping = [[stateDict objectForKey:@"Looping"] boolValue];
		delay   = [[stateDict objectForKey:@"Delay"]  floatValue];
		imageNameArray = [stateDict objectForKey:@"Images"];
		imageNameEnumerator = [imageNameArray objectEnumerator];

		//Load the images
		imageArray = [NSMutableArray arrayWithCapacity:[imageNameArray count]];
		while ((imageName = [imageNameEnumerator nextObject])) {
			NSString	*imagePath;
			NSImage		*image;
			
#define DOCK_ICON_INTERNAL_PATH @"../Shared Images/"
			if ([imageName hasPrefix:DOCK_ICON_INTERNAL_PATH]) {
				//Special hack for all the incorrectly made icon packs we have floating around out there :P
				imageName = [imageName substringFromIndex:[DOCK_ICON_INTERNAL_PATH length]];
				imagePath = [[NSBundle mainBundle] pathForResource:[[[imageName stringByDeletingPathExtension] stringByAppendingString:@"-localized"] stringByAppendingPathExtension:[imageName pathExtension]]
				                                            ofType:@""
				                                       inDirectory:@"Shared Dock Icon Images"];
				
				if (!imagePath) {
					imagePath = [[NSBundle mainBundle] pathForResource:imageName
																ofType:@""
														   inDirectory:@"Shared Dock Icon Images"];
				}

			} else {
				imagePath = [folderPath stringByAppendingPathComponent:imageName];
			}
			
			image = [tempIconCache objectForKey:imagePath]; //We re-use the same images for each state if possible to lower memory usage.
			if (!image && imagePath) {
				image = [[[NSImage alloc] initByReferencingFile:imagePath] autorelease];
				if (image) [tempIconCache setObject:image forKey:imagePath];
			}
			
			if (image) [imageArray addObject:image];
		}
		
		//Create the state
		if (delay != 0 && [imageArray count] != 0) {
			iconState = [[AIIconState alloc] initWithImages:imageArray
													  delay:delay
													looping:looping
													overlay:overlay];
		} else {
			NSLog(@"Invalid animated icon state (%@)",imageName);
		}
		
	} else { //Static State
		NSString	*imageName;
		NSString	*imagePath;
		NSImage		*image;
		BOOL		overlay;
		
		imageName = [stateDict objectForKey:@"Image"];
		
		if ([imageName hasPrefix:DOCK_ICON_INTERNAL_PATH]) {
			//Special hack for all the incorrectly made icon packs we have floating around out there :P
			imageName = [imageName substringFromIndex:[DOCK_ICON_INTERNAL_PATH length]];
			imagePath = [[NSBundle mainBundle] pathForResource:[[[imageName stringByDeletingPathExtension] stringByAppendingString:@"-localized"] stringByAppendingPathExtension:[imageName pathExtension]]
														ofType:@""
												   inDirectory:@"Shared Dock Icon Images"];
			if (!imagePath) {
				imagePath = [[NSBundle mainBundle] pathForResource:imageName
			                                            ofType:@""
			                                       inDirectory:@"Shared Dock Icon Images"];
			}
		} else {
			imagePath = [folderPath stringByAppendingPathComponent:imageName];
		}

		//Get the state information
		image = [[NSImage alloc] initByReferencingFile:imagePath];
		overlay = [[stateDict objectForKey:@"Overlay"] boolValue];
		
		//Create the state
		iconState = [[AIIconState alloc] initWithImage:image overlay:overlay];		
		[image release];
	}

	return [iconState autorelease];
}

//Set an icon state from our currently loaded icon pack
- (void)setIconStateNamed:(NSString *)inName
{
    if (![activeIconStateArray containsObject:inName]) {
        [activeIconStateArray addObject:inName]; 	//Add the name to our array
        [self _setNeedsDisplay];			//Redisplay our icon
    }
}

//Remove an active icon state
- (void)removeIconStateNamed:(NSString *)inName
{
    if ([activeIconStateArray containsObject:inName]) {
        [activeIconStateArray removeObject:inName]; 	//Remove the name from our array
        
        [self _setNeedsDisplay];			//Redisplay our icon
    }
}

/*!
 * @brief Does the current icon know how to display a given state?
 */
- (BOOL)currentIconSupportsIconStateNamed:(NSString *)inName
{
	return ([[availableIconStateDict objectForKey:@"State"] objectForKey:inName] != nil);
}

//Set a custom icon state
- (void)setIconState:(AIIconState *)iconState named:(NSString *)inName
{
    [availableDynamicIconStateDict setObject:iconState forKey:inName]; 	//Add the new state to our available dict
    [self setIconStateNamed:inName];					//Set it
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
    if (observingFlash) {
        [[adium interfaceController] unregisterFlashObserver:self];
        observingFlash = NO;
    }

    //Build an array of the valid active icon states
    availableIcons = [availableIconStateDict objectForKey:@"State"];
    enumerator = [activeIconStateArray objectEnumerator];
    while ((name = [enumerator nextObject])) {
        if ((state = [availableIcons objectForKey:name]) || (state = [availableDynamicIconStateDict objectForKey:name])) {
            [iconStates addObject:state];
        }
    }

    //Generate the composited icon state
    [currentIconState release];
    currentIconState = [[AIIconState alloc] initByCompositingStates:iconStates];

    //
    if (![currentIconState animated]) { //Static icon
		NSImage *image = [currentIconState image];
        if (image) {
			 [[NSApplication sharedApplication] setApplicationIconImage:image];
		}

    } else { //Animated icon
        //Our dock icon can run its animation at any speed, but we want to try and sync it with the global Adium flashing.  To do this, we delay starting our timer until the next flash occurs.
        [[adium interfaceController] registerFlashObserver:self];
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
    [[adium interfaceController] unregisterFlashObserver:self];
    observingFlash = NO;
}

//Move the dock to the next animation frame (Assumes the current state is animated)
- (void)animateIcon:(NSTimer *)timer
{
    NSImage	*image;

    //Move to the next image
    if (timer) {
        [currentIconState nextFrame];
    }
	
    //Set the image
    image = [currentIconState image];
	if (image) {
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

    if (dHeight != 22) { //dock is on the bottom
        if (dHeight == 26) { //dock is hidden
        } else { //dock is not hidden
            dockScale = (dHeight-22)/128.0;
        }
    } else if (dWidth != 0) { //dock is on the side
        if (dWidth == 4) { //dock is hidden
        } else { //dock is not hidden
            dockScale = (dWidth)/128.0;
        }
    } else {
        //multiple monitors?
        //Add support for multiple monitors
    }

    if (dockScale <= 0 || dockScale > 1.0) {
        dockScale = 0.3;
    }

    return dockScale;
}

/*!
 * @brief Return the dock icon image without any auxiliary states
 */
- (NSImage *)baseApplicationIconImage
{
	NSDictionary	*availableIcons = [availableIconStateDict objectForKey:@"State"];
	AIIconState		*baseState;
	NSImage			*baseApplicationIconImage;

	if ((baseState = [availableIcons objectForKey:@"Base"])) {
		AIIconState		*iconState = [[[AIIconState alloc] initByCompositingStates:[NSArray arrayWithObject:baseState]] autorelease];
		baseApplicationIconImage = [iconState image];
	} else {
		baseApplicationIconImage = nil;
	}
	
	return baseApplicationIconImage;
}

//Bouncing -------------------------------------------------------------------------------------------------------------
#pragma mark Bouncing

/*!
 * @brief Perform a bouncing behavior
 *
 * @result YES if the behavior is ongoing; NO if it isn't (because it is immediately complete or some other, faster continuous behavior is in progress)
 */
- (BOOL)performBehavior:(AIDockBehavior)behavior
{
	BOOL	ongoingBehavior = NO;

    //Start up the new behavior
    switch (behavior) {
        case AIDockBehaviorStopBouncing: {
			[self _stopBouncing];
			break;
		}
        case AIDockBehaviorBounceOnce: {
			if (currentBounceInterval >= SINGLE_BOUNCE_INTERVAL) {
				currentBounceInterval = SINGLE_BOUNCE_INTERVAL;
				[self _singleBounce];
			}
			break;
		}
        case AIDockBehaviorBounceRepeatedly: ongoingBehavior = [self _continuousBounce]; break;
        case AIDockBehaviorBounceDelay_FiveSeconds: ongoingBehavior = [self _bounceWithInterval:5.0]; break;
        case AIDockBehaviorBounceDelay_TenSeconds: ongoingBehavior = [self _bounceWithInterval:10.0]; break;
        case AIDockBehaviorBounceDelay_FifteenSeconds: ongoingBehavior = [self _bounceWithInterval:15.0]; break;
        case AIDockBehaviorBounceDelay_ThirtySeconds: ongoingBehavior = [self _bounceWithInterval:30.0]; break;
        case AIDockBehaviorBounceDelay_OneMinute: ongoingBehavior = [self _bounceWithInterval:60.0]; break;
        default: break;
    }
	
	return ongoingBehavior;
}

//Return a string description of the bouncing behavior
- (NSString *)descriptionForBehavior:(AIDockBehavior)behavior
{
	NSString	*desc;
	
    switch (behavior) {
        case AIDockBehaviorStopBouncing: desc = AILocalizedString(@"None",nil); break;
        case AIDockBehaviorBounceOnce: desc = AILocalizedString(@"Once",nil); break;
        case AIDockBehaviorBounceRepeatedly: desc = AILocalizedString(@"Repeatedly",nil); break;
        case AIDockBehaviorBounceDelay_FiveSeconds: desc = AILocalizedString(@"Every 5 Seconds",nil); break;
        case AIDockBehaviorBounceDelay_TenSeconds: desc = AILocalizedString(@"Every 10 Seconds",nil); break;
        case AIDockBehaviorBounceDelay_FifteenSeconds: desc = AILocalizedString(@"Every 15 Seconds",nil); break;
        case AIDockBehaviorBounceDelay_ThirtySeconds: desc = AILocalizedString(@"Every 30 Seconds",nil); break;
        case AIDockBehaviorBounceDelay_OneMinute: desc = AILocalizedString(@"Every 60 Seconds",nil); break;
        default: desc=@""; break;
    }    

	return desc;
}

/*!
 * @brief Start a delayed, repeated bounce
 *
 * @result YES if we are now bouncing more frequently than before; NO if this call had no effect
 */
- (BOOL)_bounceWithInterval:(NSTimeInterval)delay
{
	BOOL	ongoingBehavior;

	//Bounce only if the new delay is a faster bounce than the current one
	if (delay < currentBounceInterval) {
		[self _singleBounce]; // do one right away
		
		currentBounceInterval = delay;
		
		bounceTimer = [[NSTimer scheduledTimerWithTimeInterval:delay
														target:self
													  selector:@selector(bounceWithTimer:)
													  userInfo:nil
													   repeats:YES] retain];
		
		ongoingBehavior = YES;
	} else {
		ongoingBehavior = NO;
	}
	
	return ongoingBehavior;
}

//Activated by the time after each delay
- (void)bounceWithTimer:(NSTimer *)timer
{
    //Bounce
    [self _singleBounce];
}

//Bounce once via NSApp's NSInformationalRequest (also used by the timer to perform a single bounce)
- (void)_singleBounce
{
    if ([NSApp respondsToSelector:@selector(requestUserAttention:)]) {
        currentAttentionRequest = [NSApp requestUserAttention:NSInformationalRequest];
    }
}

/*!
 * @brief Bounce continuously via NSApp's NSCriticalRequest
 *
 * We will bounce until we become the active application or our dock icon is clicked
 *
 * @result YES if we are now bouncing more frequently than before; NO if this call had no effect
 */
- (BOOL)_continuousBounce
{
	BOOL ongoingBehavior;

	if (CONTINUOUS_BOUNCE_INTERVAL < currentBounceInterval) {
		currentBounceInterval = CONTINUOUS_BOUNCE_INTERVAL;
		if ([NSApp respondsToSelector:@selector(requestUserAttention:)]) {
			currentAttentionRequest = [NSApp requestUserAttention:NSCriticalRequest];
		}

		ongoingBehavior = YES;
	} else {
		ongoingBehavior = NO;	
	}
	
	return ongoingBehavior;
}

//Stop bouncing
- (void)_stopBouncing
{
    //Stop any timer
    if (bounceTimer) {
        [bounceTimer invalidate]; [bounceTimer release]; bounceTimer = nil;
    }

    //Stop any continuous bouncing
    if (currentAttentionRequest != -1) {
        if ([NSApp respondsToSelector:@selector(cancelUserAttentionRequest:)]) {
            [NSApp cancelUserAttentionRequest:currentAttentionRequest];
        }
        currentAttentionRequest = -1;
    }
	
	currentBounceInterval = NO_BOUNCE_INTERVAL;
}

//
- (void)appWillChangeActive:(NSNotification *)notification
{
    [self _stopBouncing]; //Stop any bouncing
}

@end
