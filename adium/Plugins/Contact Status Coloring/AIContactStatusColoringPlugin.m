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

@interface AIContactStatusColoringPlugin (PRIVATE)
- (void)addToFlashArray:(AIListObject *)inObject;
- (void)removeFromFlashArray:(AIListObject *)inObject;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_applyColorToObject:(AIListObject *)inObject;
@end

@implementation AIContactStatusColoringPlugin

#define CONTACT_STATUS_THEMABLE_PREFS   @"Contact Status Coloring Themable Prefs"

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

    alpha = 100.0;

    //Setup our preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CONTACT_STATUS_COLORING_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_CONTACT_STATUS_COLORING];
    preferences = [[AIContactStatusColoringPreferences preferencePane] retain];
    
    //Register themable preferences
    [[adium preferenceController] registerThemableKeys:[NSArray arrayNamed:CONTACT_STATUS_THEMABLE_PREFS forClass:[self class]] forGroup:PREF_GROUP_CONTACT_STATUS_COLORING];    

    //Observe list object changes
    [[adium contactController] registerListObjectObserver:self];

    //Observe preference changes
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];

}

//
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
    NSArray		*modifiedAttributes = nil;

	if([inObject isKindOfClass:[AIListContact class]]){
		if(	inModifiedKeys == nil ||
			[inModifiedKeys containsObject:@"Typing"] ||
			[inModifiedKeys containsObject:@"UnviewedContent"] || 
			[inModifiedKeys containsObject:@"Away"] ||
			[inModifiedKeys containsObject:@"Idle"] ||
			[inModifiedKeys containsObject:@"Online"] ||
			[inModifiedKeys containsObject:@"Signed On"] || 
			[inModifiedKeys containsObject:@"Signed Off"]){
			
			//Update the handle's text color
			[self _applyColorToObject:inObject];
			modifiedAttributes = [NSArray arrayWithObjects:@"Text Color", @"Inverted Text Color", @"Label Color", nil];
		}
		
		//Update our flash array
		if(inModifiedKeys == nil || [inModifiedKeys containsObject:@"UnviewedContent"]){
			int unviewedContent = [inObject integerStatusObjectForKey:@"UnviewedContent"];
			
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

    //Prefetch the value for unviewed content, we need it multiple times below
    unviewedContent = [inObject integerStatusObjectForKey:@"UnviewedContent"];

    //Unviewed content
    if(!color && (unviewedContentEnabled && unviewedContent)){
        if(/*!unviewedFlashEnabled || */!([[adium interfaceController] flashState] % 2)){
            color = unviewedContentColor;
            invertedColor = unviewedContentInvertedColor;
            labelColor = unviewedContentLabelColor;
        }
    }

    //Offline, Signed off, signed on, or typing (These do not show if there is unviewed content)
    if(!color && (!unviewedContentEnabled || !unviewedContent)){
		if(offlineEnabled && (![inObject integerStatusObjectForKey:@"Online"] &&
							  ![inObject integerStatusObjectForKey:@"Signed Off"])){
			color = offlineColor;
			invertedColor = offlineInvertedColor;
			labelColor = offlineLabelColor;		
		}else if(signedOffEnabled && ([inObject integerStatusObjectForKey:@"Signed Off"])){
            color = signedOffColor;
            invertedColor = signedOffInvertedColor;
            labelColor = signedOffLabelColor;
            
        }else if(signedOnEnabled && [inObject integerStatusObjectForKey:@"Signed On"]){
            color = signedOnColor;
            invertedColor = signedOnInvertedColor;
            labelColor = signedOnLabelColor;
            
        }else if(typingEnabled && [inObject integerStatusObjectForKey:@"Typing"]){
            color = typingColor;
            invertedColor = typingInvertedColor;
            labelColor = typingLabelColor;
        }
    }

    if(!color){
        //Prefetch these values, we need them multiple times below
        away = [inObject integerStatusObjectForKey:@"Away"];
        idle = [[inObject numberStatusObjectForKey:@"Idle"] intValue];

        //Idle And Away, Away, or Idle
        if(idleAndAwayEnabled && away && idle != 0){
            color = idleAndAwayColor;
            invertedColor = idleAndAwayInvertedColor;
            labelColor = idleAndAwayLabelColor;
        }else if(awayEnabled && away){
            color = awayColor;
            invertedColor = awayInvertedColor;
            labelColor = awayLabelColor;
        }else if(idleEnabled && idle != 0){
            color = idleColor;
            invertedColor = idleInvertedColor;
            labelColor = idleLabelColor;
        }
    }

    //Online
    if(!color && onlineEnabled && [inObject integerStatusObjectForKey:@"Online"]){
        color = onlineColor;
        invertedColor = onlineInvertedColor;
        labelColor = onlineLabelColor;
    }
	
    //Apply the color
    [[inObject displayArrayForKey:@"Text Color"] setObject:color withOwner:self];
    [[inObject displayArrayForKey:@"Inverted Text Color"] setObject:invertedColor withOwner:self];
    [[inObject displayArrayForKey:@"Label Color"] setObject:labelColor withOwner:self];
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

//
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_CONTACT_STATUS_COLORING]){
		NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_STATUS_COLORING];
		
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
		
        //
        alpha = [[prefDict objectForKey:KEY_STATUS_LABEL_OPACITY] floatValue];
		
		[[adium contactController] updateAllListObjectsForObserver:self];
    }
}

@end
