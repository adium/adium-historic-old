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
	offlineColor = nil;

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
        int unviewedContent = [inObject integerStatusObjectForKey:@"UnviewedContent"];

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
    unviewedContent = [inObject integerStatusObjectForKey:@"UnviewedContent"];

    //Unviewed content
    if(!color && (unviewedContentEnabled && unviewedContent)){
        if(!unviewedFlashEnabled || !([[adium interfaceController] flashState] % 2)){
            color = unviewedContentColor;
        }
    }
    
	// We do NOT need to check if custom tab colors are enabled, since the normal
	// status colors are automatically used if the custom colors are disabled
	
    //Signed off, signed on, or typing (These do not show if there is unviewed content)
    if(!color && !unviewedContent && (unviewedContentEnabled || contactListUnviewedContentEnabled)){
		if( ![inObject integerStatusObjectForKey:@"Signed Off"] &&
			![inObject integerStatusObjectForKey:@"Online"]){
			color = offlineColor;
			
        }else if( [inObject integerStatusObjectForKey:@"Signed Off"] && (signedOffEnabled || contactListSignedOffEnabled) ){
            color = signedOffColor;
        
        }else if( [inObject integerStatusObjectForKey:@"Signed On"] && (signedOnEnabled || contactListSignedOnEnabled) ){
            color = signedOnColor;

        }else if( [inObject integerStatusObjectForKey:@"Typing"] && (typingEnabled || contactListTypingEnabled) ){
            color = typingColor;

        }
    }

    if(!color && [inObject integerStatusObjectForKey:@"Online"]){
        //Prefetch these values, we need them multiple times below
        away = [inObject integerStatusObjectForKey:@"Away"];
        idle = [[inObject numberStatusObjectForKey:@"Idle"] doubleValue];

        //Idle And Away, Away, or Idle
        if( away && (idle != 0) && (idleAndAwayEnabled || contactListIdleAndAwayEnabled) ){
            color = idleAndAwayColor;
        }else if( away && (awayEnabled || contactListAwayEnabled) ){
            color = awayColor;
        }else if( idle != 0 && (idleEnabled || contactListIdleEnabled) ){
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
		BOOL			customColorsEnabled = [[prefDict objectForKey:KEY_TAB_USE_CUSTOM_COLORS] boolValue];
			
		//Cache the tab enabled states
		awayEnabled = [[prefDict objectForKey:KEY_TAB_AWAY_ENABLED] boolValue] && customColorsEnabled;
        idleEnabled = [[prefDict objectForKey:KEY_TAB_IDLE_ENABLED] boolValue] && customColorsEnabled;
        signedOffEnabled = [[prefDict objectForKey:KEY_TAB_SIGNED_OFF_ENABLED] boolValue] && customColorsEnabled;
        signedOnEnabled = [[prefDict objectForKey:KEY_TAB_SIGNED_ON_ENABLED] boolValue] && customColorsEnabled;
        typingEnabled = [[prefDict objectForKey:KEY_TAB_TYPING_ENABLED] boolValue] && customColorsEnabled;
        unviewedContentEnabled = [[prefDict objectForKey:KEY_TAB_UNVIEWED_ENABLED] boolValue] && customColorsEnabled;
        idleAndAwayEnabled = [[prefDict objectForKey:KEY_TAB_IDLE_AWAY_ENABLED] boolValue] && customColorsEnabled;
        offlineEnabled = [[prefDict objectForKey:KEY_TAB_OFFLINE_ENABLED] boolValue] && customColorsEnabled;
        unviewedFlashEnabled = [[prefDict objectForKey:KEY_TAB_UNVIEWED_FLASH_ENABLED] boolValue] && customColorsEnabled;
		
		contactListAwayEnabled = [[prefDict objectForKey:KEY_AWAY_ENABLED] boolValue];
        contactListIdleEnabled = [[prefDict objectForKey:KEY_IDLE_ENABLED] boolValue];
        contactListSignedOffEnabled = [[prefDict objectForKey:KEY_SIGNED_OFF_ENABLED] boolValue];
		contactListSignedOnEnabled = [[prefDict objectForKey:KEY_SIGNED_ON_ENABLED] boolValue];
		contactListTypingEnabled = [[prefDict objectForKey:KEY_TYPING_ENABLED] boolValue];
        contactListUnviewedContentEnabled = [[prefDict objectForKey:KEY_UNVIEWED_ENABLED] boolValue];
        contactListIdleAndAwayEnabled = [[prefDict objectForKey:KEY_IDLE_AWAY_ENABLED] boolValue];
        contactListOfflineEnabled = [[prefDict objectForKey:KEY_OFFLINE_ENABLED] boolValue];		
	
		//Release the old values..
		//Cache the new colors
		[signedOffColor release];
		if( signedOffEnabled ) {
			signedOffColor = [[[prefDict objectForKey:KEY_TAB_SIGNED_OFF_COLOR] representedColor] retain];
		} else {
			signedOffColor = [[[prefDict objectForKey:KEY_LABEL_SIGNED_OFF_COLOR] representedColor] retain];
		}
		
		[signedOnColor release];
		if( signedOnEnabled ) {
			signedOnColor = [[[prefDict objectForKey:KEY_TAB_SIGNED_ON_COLOR] representedColor] retain];
		} else {
			signedOnColor = [[[prefDict objectForKey:KEY_LABEL_SIGNED_ON_COLOR] representedColor] retain];
		}
		
		[awayColor release];
		if( awayEnabled ) {
			awayColor = [[[prefDict objectForKey:KEY_TAB_AWAY_COLOR] representedColor] retain];
		} else {
			awayColor = [[[prefDict objectForKey:KEY_AWAY_COLOR] representedColor] retain];
		}
		
		[idleColor release];
		if( idleEnabled ) {
			idleColor = [[[prefDict objectForKey:KEY_TAB_IDLE_COLOR] representedColor] retain];
		} else {
			idleColor = [[[prefDict objectForKey:KEY_IDLE_COLOR] representedColor] retain];
		}
		
		[typingColor release];
		if( typingEnabled ) {
			typingColor = [[[prefDict objectForKey:KEY_TAB_TYPING_COLOR] representedColor] retain];
		} else {
			typingColor = [[[prefDict objectForKey:KEY_LABEL_TYPING_COLOR] representedColor] retain];
		}
		
		[unviewedContentColor release];
		if( unviewedContentEnabled ) {
			unviewedContentColor = [[[prefDict objectForKey:KEY_TAB_UNVIEWED_COLOR] representedColor] retain];
		} else {
			unviewedContentColor = [[[prefDict objectForKey:KEY_LABEL_UNVIEWED_COLOR] representedColor] retain];
		}
		
		[idleAndAwayColor release];
		if( idleAndAwayEnabled ) {
			idleAndAwayColor = [[[prefDict objectForKey:KEY_TAB_IDLE_AWAY_COLOR] representedColor] retain];
		} else {
			idleAndAwayColor = [[[prefDict objectForKey:KEY_IDLE_AWAY_COLOR] representedColor] retain];
		}
		
		[offlineColor release];
		if( offlineEnabled ) {
			offlineColor = [[[prefDict objectForKey:KEY_TAB_OFFLINE_COLOR] representedColor] retain];
		} else {
			offlineColor = [[[prefDict objectForKey:KEY_OFFLINE_COLOR] representedColor] retain];
		}

		
		[[adium contactController] updateAllListObjectsForObserver:self];
    }
}

@end

