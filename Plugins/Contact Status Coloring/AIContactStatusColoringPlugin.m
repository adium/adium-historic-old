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

#import "AIContactStatusColoringPlugin.h"
#import "AIContactStatusColoringPreferences.h"
#import "AIListThemeWindowController.h"

@interface AIContactStatusColoringPlugin (PRIVATE)
- (void)addToFlashArray:(AIListObject *)inObject;
- (void)removeFromFlashArray:(AIListObject *)inObject;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_applyColorToObject:(AIListObject *)inObject;

- (void)fadeObject:(AIListObject *)inObject fromOpacity:(float)startValue toOpacity:(float)endValue;
- (void)stopFadeOfObject:(AIListObject *)inObject;
@end

@implementation AIContactStatusColoringPlugin

#define OFFLINE_IMAGE_OPACITY	0.5
#define FULL_IMAGE_OPACITY		1.0
#define	OPACITY_REFRESH			0.2

#define CONTACT_STATUS_THEMABLE_PREFS   		@"Contact Status Coloring Themable Prefs"
#define CONTACT_STATUS_COLORING_DEFAULT_PREFS	@"ContactStatusColoringDefaults"

- (void)installPlugin
{
    //init
    flashingListObjectArray = [[NSMutableArray alloc] init];
    awayColor = nil;
    idleColor = nil;
    signedOffColor = nil;
    signedOnColor = nil;
    typingColor = nil;
    unviewedContentColor = nil;
    onlineColor = nil;
    idleAndAwayColor = nil;
	offlineColor = nil;
	
    awayInvertedColor = nil;
    idleInvertedColor = nil;
    signedOffInvertedColor = nil;
    signedOnInvertedColor = nil;
    typingInvertedColor = nil;
    unviewedContentInvertedColor = nil;
    onlineInvertedColor = nil;
    idleAndAwayInvertedColor = nil;
	offlineInvertedColor = nil;
	
    awayLabelColor = nil;
    idleLabelColor = nil;
    signedOffLabelColor = nil;
    signedOnLabelColor = nil;
    typingLabelColor = nil;
    unviewedContentLabelColor = nil;
    onlineLabelColor = nil;
    idleAndAwayLabelColor = nil;
	offlineLabelColor = nil;
	
	offlineImageFading = NO;
	
	
    //Setup our preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CONTACT_STATUS_COLORING_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_LIST_THEME];
    
    //Observe preferences and list objects
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_LIST_THEME];
	[[adium contactController] registerListObjectObserver:self];
}

//
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
    NSSet		*modifiedAttributes = nil;

	if([inObject isKindOfClass:[AIListContact class]]){
		if(	inModifiedKeys == nil ||
			[inModifiedKeys containsObject:KEY_TYPING] ||
			[inModifiedKeys containsObject:KEY_UNVIEWED_CONTENT] || 
			[inModifiedKeys containsObject:@"Away"] ||
			[inModifiedKeys containsObject:@"Idle"] ||
			[inModifiedKeys containsObject:@"Online"] ||
			[inModifiedKeys containsObject:@"Signed On"] || 
			[inModifiedKeys containsObject:@"Signed Off"]){
			
			//Update the handle's text color
			[self _applyColorToObject:inObject];
			modifiedAttributes = [NSSet setWithObjects:@"Text Color", @"Inverted Text Color", @"Label Color", nil];
		}
		
		//Update our flash array
		if(inModifiedKeys == nil || [inModifiedKeys containsObject:KEY_UNVIEWED_CONTENT]){
			int unviewedContent = [inObject integerStatusObjectForKey:KEY_UNVIEWED_CONTENT];
			
			if(unviewedContent && ![flashingListObjectArray containsObject:inObject]){ //Start flashing
				[self addToFlashArray:inObject];
			}else if(!unviewedContent && [flashingListObjectArray containsObject:inObject]){ //Stop flashing
				[self removeFromFlashArray:inObject];
			}
		}
	}

    return(modifiedAttributes);
}

//Applies the correct color to the passed object
- (void)_applyColorToObject:(AIListObject *)inObject
{
    NSColor			*color = nil, *invertedColor = nil, *labelColor = nil;
    int				unviewedContent, away;
    int				idle;
	float			opacity = FULL_IMAGE_OPACITY;
	BOOL			isEvent = NO;

    //Prefetch the value for unviewed content, we need it multiple times below
    unviewedContent = [inObject integerStatusObjectForKey:KEY_UNVIEWED_CONTENT];

    //Unviewed content
    if(!color && (unviewedContentEnabled && unviewedContent)){
        if(/*!unviewedFlashEnabled || */!([[adium interfaceController] flashState] % 2)){
            color = unviewedContentColor;
            invertedColor = unviewedContentInvertedColor;
            labelColor = unviewedContentLabelColor;
			isEvent = YES;
        }
    }

    //Offline, Signed off, signed on, or typing (These do not show if there is unviewed content)
    if(!color && (!unviewedContentEnabled || !unviewedContent)){
		if(offlineEnabled && (![inObject online] &&
							  ![inObject integerStatusObjectForKey:@"Signed Off"])){
			color = offlineColor;
			invertedColor = offlineInvertedColor;
			labelColor = offlineLabelColor;
			if(offlineImageFading) opacity = OFFLINE_IMAGE_OPACITY;
			
			[self stopFadeOfObject:inObject];
			
		}else if(signedOffEnabled && ([inObject integerStatusObjectForKey:@"Signed Off"])){

			//Set colors
            color = signedOffColor;
            invertedColor = signedOffInvertedColor;
            labelColor = signedOffLabelColor;
			isEvent = YES;

			[self fadeObject:inObject fromOpacity:1.0 toOpacity:0.8];

        }else if(signedOnEnabled && [inObject integerStatusObjectForKey:@"Signed On"]){
            
			color = signedOnColor;
            invertedColor = signedOnInvertedColor;
            labelColor = signedOnLabelColor;
			isEvent = YES;

			[self fadeObject:inObject fromOpacity:OFFLINE_IMAGE_OPACITY toOpacity:1.0];

        }else if(typingEnabled && ([inObject integerStatusObjectForKey:KEY_TYPING] == AITyping)){
            color = typingColor;
            invertedColor = typingInvertedColor;
            labelColor = typingLabelColor;
			isEvent = YES;
			
			[self stopFadeOfObject:inObject];
			
        }else{
			[self stopFadeOfObject:inObject];	
		}
    }

    if(!color){
        //Prefetch these values, we need them multiple times below
        away = [inObject integerStatusObjectForKey:@"Away" fromAnyContainedObject:NO];
        idle = [inObject integerStatusObjectForKey:@"Idle" fromAnyContainedObject:NO];

        //Idle And Away, Away, or Idle
        if(idleAndAwayEnabled && away && (idle != 0)){
            color = idleAndAwayColor;
            invertedColor = idleAndAwayInvertedColor;
            labelColor = idleAndAwayLabelColor;
        }else if(awayEnabled && away){
            color = awayColor;
            invertedColor = awayInvertedColor;
            labelColor = awayLabelColor;
        }else if(idleEnabled && (idle != 0)){
            color = idleColor;
            invertedColor = idleInvertedColor;
            labelColor = idleLabelColor;
        }
    }

    //Online
    if(!color && onlineEnabled && [inObject online]){
        color = onlineColor;
        invertedColor = onlineInvertedColor;
        labelColor = onlineLabelColor;
    }
	
    //Apply the color and opacity
    [[inObject displayArrayForKey:@"Text Color"] setObject:color withOwner:self];
    [[inObject displayArrayForKey:@"Inverted Text Color"] setObject:invertedColor withOwner:self];
    [[inObject displayArrayForKey:@"Label Color"] setObject:labelColor withOwner:self];
	[[inObject displayArrayForKey:@"Image Opacity"] setObject:[NSNumber numberWithFloat:opacity] withOwner:self];
	[[inObject displayArrayForKey:@"Is Event"] setObject:[NSNumber numberWithBool:isEvent] withOwner:self];
}

//Flash all handles with unviewed content
- (void)flash:(int)value
{
    NSEnumerator	*enumerator;
    AIListContact	*object;

    enumerator = [flashingListObjectArray objectEnumerator];
    while((object = [enumerator nextObject])){
        [self _applyColorToObject:object];
        
        //Force a redraw
        [[adium notificationCenter] postNotificationName:ListObject_AttributesChanged object:object userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObjects:@"Text Color", @"Label Color", @"Inverted Text Color", nil] forKey:@"Keys"]];
    }
}

//Add a handle to the flash array
- (void)addToFlashArray:(AIListObject *)inObject
{
    //Ensure that we're observing the flashing
    if([flashingListObjectArray count] == 0){
        [[adium interfaceController] registerFlashObserver:self];
    }

    //Add the contact to our flash array
    [flashingListObjectArray addObject:inObject];
    [self flash:[[adium interfaceController] flashState]];
}

//Remove a handle from the flash array
- (void)removeFromFlashArray:(AIListObject *)inObject
{
    //Remove the contact from our flash array
    [flashingListObjectArray removeObject:inObject];

    //If we have no more flashing contacts, stop observing the flashes
    if([flashingListObjectArray count] == 0){
        [[adium interfaceController] unregisterFlashObserver:self];
    }
}

- (void)fadeObject:(AIListObject *)listObject fromOpacity:(float)startValue toOpacity:(float)endValue
{
	if(![[listObject containingObject] isKindOfClass:[AIMetaContact class]]){
		NSTimer				*tempDisplayOpacityTimer;
		NSDictionary		*tempDisplayOpacityDict;
		AIMutableOwnerArray	*tempDisplayOpacityArray;
		NSNumber			*initialDisplayOpacity;
		
		tempDisplayOpacityArray = [listObject displayArrayForKey:@"Temporary Display Opacity"];
		
		//We should start with the current value. If there isn't one, we start at startValue
		if(!(initialDisplayOpacity= [tempDisplayOpacityArray objectValue])){
			initialDisplayOpacity = [NSNumber numberWithFloat:startValue];
			[tempDisplayOpacityArray setObject:initialDisplayOpacity withOwner:self];
		}
		
		tempDisplayOpacityDict = [NSDictionary dictionaryWithObjectsAndKeys:listObject, @"listObject",
			initialDisplayOpacity, @"initialDisplayOpacity",
			[NSNumber numberWithFloat:endValue], @"endingDisplayOpacity",
			nil];
		
		//If we already have an opacity timer for this object, invalidate it
		tempDisplayOpacityTimer = [listObject statusObjectForKey:@"tempDisplayOpacityTimer" fromAnyContainedObject:NO];
		if(tempDisplayOpacityTimer){
			[tempDisplayOpacityTimer invalidate];
			NSLog(@"fadeObject %@: invalidated %x",listObject,tempDisplayOpacityTimer);
			[listObject setStatusObject:nil
								 forKey:@"tempDisplayOpacityTimer"
								 notify:NotifyNever];	
		}
		
		tempDisplayOpacityTimer = [NSTimer scheduledTimerWithTimeInterval:OPACITY_REFRESH
																   target:self
																 selector:@selector(opacityRefresh:)
																 userInfo:tempDisplayOpacityDict
																  repeats:YES];
		//Store the timer for later use
		[listObject setStatusObject:tempDisplayOpacityTimer
							 forKey:@"tempDisplayOpacityTimer"
							 notify:NotifyNever];
	}
}

//Update the 
- (void)opacityRefresh:(NSTimer *)inTimer
{
	NSDictionary	*userInfo = [inTimer userInfo];
	AIListObject	*listObject = [userInfo objectForKey:@"listObject"];
	float			displayOpacity = [[listObject displayArrayObjectForKey:@"Temporary Display Opacity"] floatValue];
	float			initialDisplayOpacity = [[userInfo objectForKey:@"initialDisplayOpacity"] floatValue];
	float			targetDisplayOpacity = [[userInfo objectForKey:@"endingDisplayOpacity"] floatValue];
		
	//Move displayOpacity towards targetDisplayOpacity by a fraction of the difference between our destination and our origin opacities
	displayOpacity = displayOpacity + ((targetDisplayOpacity - initialDisplayOpacity) / (2 / OPACITY_REFRESH));

	[[listObject displayArrayForKey:@"Temporary Display Opacity"] setObject:[NSNumber numberWithFloat:displayOpacity]
																  withOwner:self];
	
	//Force a redraw
	[[adium notificationCenter] postNotificationName:ListObject_AttributesChanged 
											  object:listObject
											userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:@"Temporary Display Opacity"] 
																				 forKey:@"Keys"]];

	//If we are now above the target and the intitial was below, or we are below and the initial was above, stop the continual fading
	//We don't want to remove the Temporary Display Opacity right now; we want to wait until stopFadeOfObject: is called when another status change occurs
	if (((displayOpacity > targetDisplayOpacity) && (initialDisplayOpacity < targetDisplayOpacity)) ||
		((displayOpacity < targetDisplayOpacity) && (initialDisplayOpacity > targetDisplayOpacity))){
		[inTimer invalidate];
		
		[listObject setStatusObject:nil
							 forKey:@"tempDisplayOpacityTimer"
							 notify:NotifyNever];
	}
}

- (void)stopFadeOfObject:(AIListObject *)listObject
{
	NSTimer				*tempDisplayOpacityTimer;
	AIMutableOwnerArray	*tempDisplayOpacityArray;
	
	//If we have an opacity timer for this object, invalidate it
	if(tempDisplayOpacityTimer = [listObject statusObjectForKey:@"tempDisplayOpacityTimer" fromAnyContainedObject:NO]){
		[tempDisplayOpacityTimer invalidate];

		[listObject setStatusObject:nil
							 forKey:@"tempDisplayOpacityTimer"
							 notify:NotifyNever];	
	}
	
	//Clear any temporary display opacity we have set
	if((tempDisplayOpacityArray = [listObject displayArrayForKey:@"Temporary Display Opacity" create:NO]) &&
	   ([tempDisplayOpacityArray objectWithOwner:self])){
		[tempDisplayOpacityArray setObject:nil withOwner:self];

		//Force a redraw
		[[adium notificationCenter] postNotificationName:ListObject_AttributesChanged 
												  object:listObject
												userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:@"Temporary Display Opacity"] 
																					 forKey:@"Keys"]];		
	}
}

//
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict 
{
	//Release the old values..
	[signedOffColor release];
	[signedOnColor release];
	[awayColor release];
	[idleColor release];
	[typingColor release];
	[unviewedContentColor release];
	[onlineColor release];
	[idleAndAwayColor release];
	[offlineColor release];
	
	[signedOffInvertedColor release];
	[signedOnInvertedColor release];
	[awayInvertedColor release];
	[idleInvertedColor release];
	[typingInvertedColor release];
	[unviewedContentInvertedColor release];
	[onlineInvertedColor release];
	[idleAndAwayInvertedColor release];
	[offlineInvertedColor release];
	
	[awayLabelColor release];
	[idleLabelColor release];
	[signedOffLabelColor release];
	[signedOnLabelColor release];
	[typingLabelColor release];
	[unviewedContentLabelColor release];
	[onlineLabelColor release];
	[idleAndAwayLabelColor release];
	[offlineLabelColor release];
	
	//
	alpha = 1.0;
	offlineImageFading = [[prefDict objectForKey:KEY_LIST_THEME_FADE_OFFLINE_IMAGES] boolValue];
	
	//Cache the preference values
	signedOffColor = [[[prefDict objectForKey:KEY_SIGNED_OFF_COLOR] representedColor] retain];
	signedOnColor = [[[prefDict objectForKey:KEY_SIGNED_ON_COLOR] representedColor] retain];
	awayColor = [[[prefDict objectForKey:KEY_AWAY_COLOR] representedColor] retain];
	idleColor = [[[prefDict objectForKey:KEY_IDLE_COLOR] representedColor] retain];
	typingColor = [[[prefDict objectForKey:KEY_TYPING_COLOR] representedColor] retain];
	unviewedContentColor = [[[prefDict objectForKey:KEY_UNVIEWED_COLOR] representedColor] retain];
	onlineColor = [[[prefDict objectForKey:KEY_ONLINE_COLOR] representedColor] retain];
	idleAndAwayColor = [[[prefDict objectForKey:KEY_IDLE_AWAY_COLOR] representedColor] retain];
	offlineColor = [[[prefDict objectForKey:KEY_OFFLINE_COLOR] representedColor] retain];
	
	signedOffInvertedColor = [[signedOffColor colorWithInvertedLuminance] retain];
	signedOnInvertedColor = [[signedOnColor colorWithInvertedLuminance] retain];
	awayInvertedColor = [[awayColor colorWithInvertedLuminance] retain];
	idleInvertedColor = [[idleColor colorWithInvertedLuminance] retain];
	typingInvertedColor = [[typingColor colorWithInvertedLuminance] retain];
	unviewedContentInvertedColor = [[unviewedContentColor colorWithInvertedLuminance] retain];
	onlineInvertedColor = [[onlineColor colorWithInvertedLuminance] retain];
	idleAndAwayInvertedColor = [[idleAndAwayColor colorWithInvertedLuminance] retain];
	offlineInvertedColor = [[offlineColor colorWithInvertedLuminance] retain];
	
	awayLabelColor = [[[prefDict objectForKey:KEY_LABEL_AWAY_COLOR] representedColorWithAlpha:alpha] retain];
	idleLabelColor = [[[prefDict objectForKey:KEY_LABEL_IDLE_COLOR] representedColorWithAlpha:alpha] retain];
	signedOffLabelColor = [[[prefDict objectForKey:KEY_LABEL_SIGNED_OFF_COLOR] representedColorWithAlpha:alpha] retain];
	signedOnLabelColor = [[[prefDict objectForKey:KEY_LABEL_SIGNED_ON_COLOR] representedColorWithAlpha:alpha] retain];
	typingLabelColor = [[[prefDict objectForKey:KEY_LABEL_TYPING_COLOR] representedColorWithAlpha:alpha] retain];
	unviewedContentLabelColor = [[[prefDict objectForKey:KEY_LABEL_UNVIEWED_COLOR] representedColorWithAlpha:alpha] retain];
	onlineLabelColor = [[[prefDict objectForKey:KEY_LABEL_ONLINE_COLOR] representedColorWithAlpha:alpha] retain];
	idleAndAwayLabelColor = [[[prefDict objectForKey:KEY_LABEL_IDLE_AWAY_COLOR] representedColorWithAlpha:alpha] retain];
	offlineLabelColor = [[[prefDict objectForKey:KEY_LABEL_OFFLINE_COLOR] representedColorWithAlpha:alpha] retain];
	
	//
	awayEnabled = [[prefDict objectForKey:KEY_AWAY_ENABLED] boolValue];
	idleEnabled = [[prefDict objectForKey:KEY_IDLE_ENABLED] boolValue];
	signedOffEnabled = [[prefDict objectForKey:KEY_SIGNED_OFF_ENABLED] boolValue];
	signedOnEnabled = [[prefDict objectForKey:KEY_SIGNED_ON_ENABLED] boolValue];
	typingEnabled = [[prefDict objectForKey:KEY_TYPING_ENABLED] boolValue];
	unviewedContentEnabled = [[prefDict objectForKey:KEY_UNVIEWED_ENABLED] boolValue];
	onlineEnabled = [[prefDict objectForKey:KEY_ONLINE_ENABLED] boolValue];
	idleAndAwayEnabled = [[prefDict objectForKey:KEY_IDLE_AWAY_ENABLED] boolValue];
	offlineEnabled = [[prefDict objectForKey:KEY_OFFLINE_ENABLED] boolValue];
	
	//Update all objects
	if(key){
		[[adium contactController] updateAllListObjectsForObserver:self];
	}
}

@end
