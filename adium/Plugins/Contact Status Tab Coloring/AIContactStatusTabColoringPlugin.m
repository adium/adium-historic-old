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

#import "AIContactStatusTabColoringPlugin.h"
#import "AIContactStatusTabColoringPreferences.h"

@interface AIContactStatusTabColoringPlugin (PRIVATE)
- (void)_applyColorToObject:(AIListObject *)inObject;
- (void)_addToFlashArray:(AIListObject *)inObject;
- (void)_removeFromFlashArray:(AIListObject *)inObject;
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIContactStatusTabColoringPlugin

#define TAB_STATUS_THEMABLE_PREFS   @"Tab Coloring Themable Prefs"

//
- (void)installPlugin
{
    //Init
    flashingListObjectArray = [[NSMutableArray alloc] init];
    awayColor = nil;
    idleColor = nil;
    signedOffColor = nil;
    signedOnColor = nil;
    typingColor = nil;
    unviewedContentColor = nil;
    onlineColor = nil;
    idleAndAwayColor = nil;

    //Setup our preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:TAB_COLORING_DEFAULT_PREFS
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_CONTACT_STATUS_COLORING];
    preferences = [[AIContactStatusTabColoringPreferences preferencePane] retain];
    
    //Register themable preferences
    [[adium preferenceController] registerThemableKeys:[NSArray arrayNamed:TAB_STATUS_THEMABLE_PREFS 
																  forClass:[self class]] 
											  forGroup:PREF_GROUP_CONTACT_STATUS_COLORING];    

    //Observe list object changes
    [[adium contactController] registerListObjectObserver:self];

    //Observe preference changes
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:)
									   name:Preference_GroupChanged
									 object:nil];
    [self preferencesChanged:nil];
}

//
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
    NSArray		*modifiedAttributes = nil;

    //Update the tab text color
    if(	inModifiedKeys == nil || 
        [inModifiedKeys containsObject:@"Typing"] ||
        [inModifiedKeys containsObject:@"UnviewedContent"] ||
        [inModifiedKeys containsObject:@"Away"] ||
        [inModifiedKeys containsObject:@"Idle"] ||
        [inModifiedKeys containsObject:@"Online"] ||
        [inModifiedKeys containsObject:@"Signed On"] || 
        [inModifiedKeys containsObject:@"Signed Off"]){

        [self _applyColorToObject:inObject];
        modifiedAttributes = [NSArray arrayWithObject:@"Tab Text Color"];
    }

    //Update our flash array
    if(inModifiedKeys == nil || [inModifiedKeys containsObject:@"UnviewedContent"]){
        int unviewedContent = [[inObject statusArrayForKey:@"UnviewedContent"] intValue];

        if(unviewedContent && ![flashingListObjectArray containsObject:inObject]){ //Start flashing
            [self _addToFlashArray:inObject];
        }else if(!unviewedContent && [flashingListObjectArray containsObject:inObject]){ //Stop flashing
            [self _removeFromFlashArray:inObject];
        }
    }

    return(modifiedAttributes);
}

//Return the correct color
- (void)_applyColorToObject:(AIListObject *)inObject
{
    NSColor	*color = nil;
    int		unviewedContent, away;
    double	idle;

    //Prefetch the value for unviewed content, we need it multiple times below
    unviewedContent = [[inObject statusArrayForKey:@"UnviewedContent"] intValue];

    //Unviewed content
    if(!color && (unviewedContentEnabled && unviewedContent)){
        if(!unviewedFlashEnabled || !([[adium interfaceController] flashState] % 2)){
            color = unviewedContentColor;
        }
    }
    
    //Signed off, signed on, or typing (These do not show if there is unviewed content)
    if(!color && (!unviewedContentEnabled || !unviewedContent)){
        if(signedOffEnabled && ([[inObject statusArrayForKey:@"Signed Off"] intValue] ||
                                ![[inObject statusArrayForKey:@"Online"] intValue])){
            color = signedOffColor;
        
        }else if(signedOnEnabled && [[inObject statusArrayForKey:@"Signed On"] intValue]){
            color = signedOnColor;

        }else if(typingEnabled && [[inObject statusArrayForKey:@"Typing"] intValue]){
            color = typingColor;

        }
    }

    if(!color){
        //Prefetch these values, we need them multiple times below
        away = [[inObject statusArrayForKey:@"Away"] intValue];
        idle = [[inObject statusArrayForKey:@"Idle"] doubleValue];

        //Idle And Away, Away, or Idle
        if(idleAndAwayEnabled && away && idle != 0){
            color = idleAndAwayColor;
        }else if(awayEnabled && away){
            color = awayColor;
        }else if(idleEnabled && idle != 0){
            color = idleColor;
        }
    }

    //Apply the color
    [[inObject displayArrayForKey:@"Tab Text Color"] setObject:color withOwner:self];
}

//Flash all handles with unviewed content
- (void)flash:(int)value
{
    if(unviewedFlashEnabled){
        NSEnumerator	*enumerator;
        AIListContact	*object;

        enumerator = [flashingListObjectArray objectEnumerator];
        while((object = [enumerator nextObject])){
            //Apply new color to the object
            [self _applyColorToObject:object];
            
            //Force a redraw
            [[adium notificationCenter] postNotificationName:ListObject_AttributesChanged 
													  object:object
													userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:@"Tab Text Color"]
																						 forKey:@"Keys"]];
        }
    }
}

//Add a handle to the flash array
- (void)_addToFlashArray:(AIListObject *)inObject
{
    //Ensure that we're observing the flashing
    if([flashingListObjectArray count] == 0){
        [[adium interfaceController] registerFlashObserver:self];
    }

    //Add the contact to our flash array
    [flashingListObjectArray addObject:inObject];
}

//Remove a handle from the flash array
- (void)_removeFromFlashArray:(AIListObject *)inObject
{
    //Remove the contact from our flash array
    [flashingListObjectArray removeObject:inObject];

    //If we have no more flashing contacts, stop observing the flashes
    if([flashingListObjectArray count] == 0){
        [[adium interfaceController] unregisterFlashObserver:self];
    }
}

//Preferences changed
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_CONTACT_STATUS_COLORING] == 0){
		NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_STATUS_COLORING];
		
		//Release the old values..
		//Cache the new colors
		[signedOffColor release];	signedOffColor = [[[prefDict objectForKey:KEY_TAB_SIGNED_OFF_COLOR] representedColor] retain];
        [signedOnColor release];	signedOnColor = [[[prefDict objectForKey:KEY_TAB_SIGNED_ON_COLOR] representedColor] retain];
        [awayColor release];		awayColor = [[[prefDict objectForKey:KEY_TAB_AWAY_COLOR] representedColor] retain];
        [idleColor release];		idleColor = [[[prefDict objectForKey:KEY_TAB_IDLE_COLOR] representedColor] retain];
        [typingColor release];		typingColor = [[[prefDict objectForKey:KEY_TAB_TYPING_COLOR] representedColor] retain];
        [unviewedContentColor release];	unviewedContentColor = [[[prefDict objectForKey:KEY_TAB_UNVIEWED_COLOR] representedColor] retain];
        [idleAndAwayColor release];	idleAndAwayColor = [[[prefDict objectForKey:KEY_TAB_IDLE_AWAY_COLOR] representedColor] retain];
		
        //Cache which states are enabled
        awayEnabled = [[prefDict objectForKey:KEY_TAB_AWAY_ENABLED] boolValue];
        idleEnabled = [[prefDict objectForKey:KEY_TAB_IDLE_ENABLED] boolValue];
        signedOffEnabled = [[prefDict objectForKey:KEY_TAB_SIGNED_OFF_ENABLED] boolValue];
        signedOnEnabled = [[prefDict objectForKey:KEY_TAB_SIGNED_ON_ENABLED] boolValue];
        typingEnabled = [[prefDict objectForKey:KEY_TAB_TYPING_ENABLED] boolValue];
        unviewedContentEnabled = [[prefDict objectForKey:KEY_TAB_UNVIEWED_ENABLED] boolValue];
        idleAndAwayEnabled = [[prefDict objectForKey:KEY_TAB_IDLE_AWAY_ENABLED] boolValue];
        unviewedFlashEnabled = [[prefDict objectForKey:KEY_TAB_UNVIEWED_FLASH_ENABLED] boolValue];
		
		[[adium contactController] updateAllListObjectsForObserver:self];
    }
}

@end

