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

#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIContactStatusColoringPlugin.h"
#import "AIContactStatusColoringPreferences.h"

@interface AIContactStatusColoringPlugin (PRIVATE)
- (void)applyColorToObject:(AIListObject *)inObject;
- (void)addToFlashArray:(AIListObject *)inObject;
- (void)removeFromFlashArray:(AIListObject *)inObject;
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIContactStatusColoringPlugin

- (void)installPlugin
{
    //init (We cache all the colors to make things faster)
    awayColor = nil;
    idleColor = nil;
    signedOffColor = nil;
    signedOnColor = nil;
    typingColor = nil;
    unviewedContentColor = nil;
    onlineColor = nil;
    idleAndAwayColor = nil;

    awayInvertedColor = nil;
    idleInvertedColor = nil;
    signedOffInvertedColor = nil;
    signedOnInvertedColor = nil;
    typingInvertedColor = nil;
    unviewedContentInvertedColor = nil;
    onlineInvertedColor = nil;
    idleAndAwayInvertedColor = nil;

    awayLabelColor = nil;
    idleLabelColor = nil;
    signedOffLabelColor = nil;
    signedOnLabelColor = nil;
    typingLabelColor = nil;
    unviewedContentLabelColor = nil;
    onlineLabelColor = nil;
    idleAndAwayLabelColor = nil;

    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CONTACT_STATUS_COLORING_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_CONTACT_STATUS_COLORING];
    [self preferencesChanged:nil];

    //Our preference view
    preferences = [[AIContactStatusColoringPreferences contactStatusColoringPreferencesWithOwner:owner] retain];
    [[owner contactController] registerListObjectObserver:self];

    //Observe
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];

    flashingListObjectArray = [[NSMutableArray alloc] init];
}

- (void)uninstallPlugin
{
    //[[owner contactController] unregisterHandleObserver:self];
}

- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys delayed:(BOOL)delayed silent:(BOOL)silent
{
    NSArray		*modifiedAttributes = nil;

    if(	inModifiedKeys == nil || 
        [inModifiedKeys containsObject:@"Away"] ||
        [inModifiedKeys containsObject:@"Idle"] ||
        [inModifiedKeys containsObject:@"Online"] ||
        [inModifiedKeys containsObject:@"Open Tab"] || 
        [inModifiedKeys containsObject:@"Signed On"] || 
        [inModifiedKeys containsObject:@"Signed Off"] || 
        [inModifiedKeys containsObject:@"Typing"] || 
        [inModifiedKeys containsObject:@"UnviewedContent"]){

        //Update the handle's text color
        [self applyColorToObject:inObject];
        modifiedAttributes = [NSArray arrayWithObjects:@"Text Color", @"Inverted Text Color", @"Background Color", @"Tab Color", nil];
    }

    //Update our flash array
    if(inModifiedKeys == nil || [inModifiedKeys containsObject:@"UnviewedContent"]){
        int unviewedContent = [[inObject statusArrayForKey:@"UnviewedContent"] greatestIntegerValue];

        if(unviewedContent && ![flashingListObjectArray containsObject:inObject]){ //Start flashing
            [self addToFlashArray:inObject];
        }else if(!unviewedContent && [flashingListObjectArray containsObject:inObject]){ //Stop flashing
            [self removeFromFlashArray:inObject];
        }
    }

    return(modifiedAttributes);
}

//Applies the correct text color to the passed contact
- (void)applyColorToObject:(AIListObject *)inObject
{
    AIMutableOwnerArray		*colorArray = [inObject displayArrayForKey:@"Text Color"];
    AIMutableOwnerArray		*invertedColorArray = [inObject displayArrayForKey:@"Inverted Text Color"];
    AIMutableOwnerArray		*labelColorArray = [inObject displayArrayForKey:@"Status Color"];
    AIMutableOwnerArray		*tabBackColorArray = [inObject displayArrayForKey:@"Tab Color"];
    int				away, online, unviewedContent, signedOn, signedOff, typing, openTab;
    double			idle;
    NSColor			*color = nil, *invertedColor = nil, *tabBackColor = nil, *labelColor = nil;

    //Get all the values
    away = [[inObject statusArrayForKey:@"Away"] greatestIntegerValue];
    idle = [[inObject statusArrayForKey:@"Idle"] greatestDoubleValue];
    online = [[inObject statusArrayForKey:@"Online"] greatestIntegerValue];
    signedOn = [[inObject statusArrayForKey:@"Signed On"] greatestIntegerValue];
    signedOff = [[inObject statusArrayForKey:@"Signed Off"] greatestIntegerValue];
    typing = [[inObject statusArrayForKey:@"Typing"] greatestIntegerValue];
    unviewedContent = [[inObject statusArrayForKey:@"UnviewedContent"] greatestIntegerValue];
    openTab = [[inObject statusArrayForKey:@"Open Tab"] greatestIntegerValue];

    //Determine the correct color
    if(unviewedContentEnabled && unviewedContent && !([[owner interfaceController] flashState] % 2)){
	color = unviewedContentColor;
	invertedColor = unviewedContentInvertedColor;
        labelColor = unviewedContentLabelColor;
    }else if(signedOffEnabled && (signedOff || !online) && (!unviewedContentEnabled || !unviewedContent)){
	color = signedOffColor;
	invertedColor = signedOffInvertedColor;
        labelColor = signedOffLabelColor;
    }else if(signedOnEnabled && signedOn && (!unviewedContentEnabled || !unviewedContent)){
	color = signedOnColor;
	invertedColor = signedOnInvertedColor;
        labelColor = signedOnLabelColor;
    }else if(typingEnabled && openTab && typing && (!unviewedContentEnabled || !unviewedContent)){
	color = typingColor;
	invertedColor = typingInvertedColor;
        labelColor = typingLabelColor;
    }else if(idleAndAwayEnabled && away && idle != 0){
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
    }else if(openTabEnabled && openTab){
        color = openTabColor;
        invertedColor = openTabInvertedColor;
        labelColor = openTabLabelColor;
    }else if(onlineEnabled){
        color = onlineColor;
        invertedColor = onlineInvertedColor;
        labelColor = onlineLabelColor;
    }
    
    //Tab Color
    if(unviewedContent && !([[owner interfaceController] flashState] % 2)){
        tabBackColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.15];
    }
    
    //Add the new color
    [colorArray setObject:color withOwner:self];
    [invertedColorArray setObject:invertedColor withOwner:self];
    [labelColorArray setObject:labelColor withOwner:self];
    [tabBackColorArray setObject:tabBackColor withOwner:self];
}

//Flash all handles with unviewed content
- (void)flash:(int)value
{
    NSEnumerator	*enumerator;
    AIListContact	*object;

    enumerator = [flashingListObjectArray objectEnumerator];
    while((object = [enumerator nextObject])){
        [self applyColorToObject:object];
        
        //Force a redraw
        [[owner notificationCenter] postNotificationName:ListObject_AttributesChanged object:object userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObjects:@"Text Color", @"Inverted Text Color", @"Tab Color", nil] forKey:@"Keys"]];
    }
}

//Add a handle to the flash array
- (void)addToFlashArray:(AIListObject *)inObject
{
    //Ensure that we're observing the flashing
    if([flashingListObjectArray count] == 0){
        [[owner interfaceController] registerFlashObserver:self];
    }

    //Add the contact to our flash array
    [flashingListObjectArray addObject:inObject];
    [self flash:[[owner interfaceController] flashState]];
}

//Remove a handle from the flash array
- (void)removeFromFlashArray:(AIListObject *)inObject
{
    //Remove the contact from our flash array
    [flashingListObjectArray removeObject:inObject];

    //If we have no more flashing contacts, stop observing the flashes
    if([flashingListObjectArray count] == 0){
        [[owner interfaceController] unregisterFlashObserver:self];
    }
}

- (void)preferencesChanged:(NSNotification *)notification
{
    //Optimize this...
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_CONTACT_STATUS_COLORING] == 0){
	NSDictionary	*prefDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_STATUS_COLORING];

	//Release the old values..
	//Cache the preference values
	signedOffColor = [[[prefDict objectForKey:KEY_SIGNED_OFF_COLOR] representedColor] retain];
	signedOnColor = [[[prefDict objectForKey:KEY_SIGNED_ON_COLOR] representedColor] retain];
	awayColor = [[[prefDict objectForKey:KEY_AWAY_COLOR] representedColor] retain];
	idleColor = [[[prefDict objectForKey:KEY_IDLE_COLOR] representedColor] retain];
	typingColor = [[[prefDict objectForKey:KEY_TYPING_COLOR] representedColor] retain];
        unviewedContentColor = [[[prefDict objectForKey:KEY_UNVIEWED_COLOR] representedColor] retain];
        onlineColor = [[[prefDict objectForKey:KEY_ONLINE_COLOR] representedColor] retain];
        openTabColor = [[[prefDict objectForKey:KEY_OPEN_TAB_COLOR] representedColor] retain];
        idleAndAwayColor = [[[prefDict objectForKey:KEY_IDLE_AWAY_COLOR] representedColor] retain];
 
	signedOffInvertedColor = [[signedOffColor colorWithInvertedLuminance] retain];
	signedOnInvertedColor = [[signedOnColor colorWithInvertedLuminance] retain];
	awayInvertedColor = [[awayColor colorWithInvertedLuminance] retain];
	idleInvertedColor = [[idleColor colorWithInvertedLuminance] retain];
	typingInvertedColor = [[typingColor colorWithInvertedLuminance] retain];
        unviewedContentInvertedColor = [[unviewedContentColor colorWithInvertedLuminance] retain];
        onlineInvertedColor = [[onlineColor colorWithInvertedLuminance] retain];
        openTabInvertedColor = [[openTabColor colorWithInvertedLuminance] retain];
        idleAndAwayInvertedColor = [[idleAndAwayColor colorWithInvertedLuminance] retain];

        awayLabelColor = [[[prefDict objectForKey:KEY_LABEL_AWAY_COLOR] representedColor] retain];
        idleLabelColor = [[[prefDict objectForKey:KEY_LABEL_IDLE_COLOR] representedColor] retain];
        signedOffLabelColor = [[[prefDict objectForKey:KEY_LABEL_SIGNED_OFF_COLOR] representedColor] retain];
        signedOnLabelColor = [[[prefDict objectForKey:KEY_LABEL_SIGNED_ON_COLOR] representedColor] retain];
        typingLabelColor = [[[prefDict objectForKey:KEY_LABEL_TYPING_COLOR] representedColor] retain];
        unviewedContentLabelColor = [[[prefDict objectForKey:KEY_LABEL_UNVIEWED_COLOR] representedColor] retain];
        onlineLabelColor = [[[prefDict objectForKey:KEY_LABEL_ONLINE_COLOR] representedColor] retain];
        openTabLabelColor = [[[prefDict objectForKey:KEY_LABEL_OPEN_TAB_COLOR] representedColor] retain];
        idleAndAwayLabelColor = [[[prefDict objectForKey:KEY_LABEL_IDLE_AWAY_COLOR] representedColor] retain];

        //
        awayEnabled = [[prefDict objectForKey:KEY_AWAY_ENABLED] boolValue];
        idleEnabled = [[prefDict objectForKey:KEY_IDLE_ENABLED] boolValue];
        signedOffEnabled = [[prefDict objectForKey:KEY_SIGNED_OFF_ENABLED] boolValue];
        signedOnEnabled = [[prefDict objectForKey:KEY_SIGNED_ON_ENABLED] boolValue];
        typingEnabled = [[prefDict objectForKey:KEY_TYPING_ENABLED] boolValue];
        unviewedContentEnabled = [[prefDict objectForKey:KEY_UNVIEWED_ENABLED] boolValue];
        onlineEnabled = [[prefDict objectForKey:KEY_ONLINE_ENABLED] boolValue];
        openTabEnabled = [[prefDict objectForKey:KEY_OPEN_TAB_ENABLED] boolValue];
        idleAndAwayEnabled = [[prefDict objectForKey:KEY_IDLE_AWAY_ENABLED] boolValue];
            
        //        
        NSEnumerator		*enumerator;
	AIListObject		*object;

	enumerator = [[[owner contactController] allContactsInGroup:nil subgroups:YES] objectEnumerator];

	while((object = [enumerator nextObject])){
            [[owner contactController] listObjectAttributesChanged:object modifiedKeys:[self updateListObject:object keys:nil delayed:YES silent:YES] delayed:YES];
	}

	[[owner notificationCenter] postNotificationName:Contact_ListChanged object:nil];
    }
}

@end
