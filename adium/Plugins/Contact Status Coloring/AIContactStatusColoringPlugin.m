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
- (void)applyColorToContact:(AIListContact *)inContact;
- (void)addToFlashArray:(AIListContact *)inContact;
- (void)removeFromFlashArray:(AIListContact *)inContact;
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIContactStatusColoringPlugin

- (void)installPlugin
{
    //init
    signedOffColor = nil;
    signedOnColor = nil;
    onlineColor = nil;
    awayColor = nil;
    idleColor = nil;
    idleAwayColor = nil;
    openTabColor = nil;
    unviewedContentColor = nil;
    warningColor = nil;

    signedOffInvertedColor = nil;
    signedOnInvertedColor = nil;
    onlineInvertedColor = nil;
    awayInvertedColor = nil;
    idleInvertedColor = nil;
    idleAwayInvertedColor = nil;
    openTabInvertedColor = nil;
    unviewedContentInvertedColor = nil;
    warningInvertedColor = nil;

    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CONTACT_STATUS_COLORING_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_CONTACT_STATUS_COLORING];
    [self preferencesChanged:nil];

    //Our preference view
    preferences = [[AIContactStatusColoringPreferences contactStatusColoringPreferencesWithOwner:owner] retain];
    [[owner contactController] registerContactObserver:self];

    //Observe
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];

    flashingContactArray = [[NSMutableArray alloc] init];
}

- (void)uninstallPlugin
{
    //[[owner contactController] unregisterHandleObserver:self];
}

- (NSArray *)updateContact:(AIListContact *)inContact keys:(NSArray *)inModifiedKeys
{
    NSArray		*modifiedAttributes = nil;

    if(	inModifiedKeys == nil || 
        [inModifiedKeys containsObject:@"Away"] || 
        [inModifiedKeys containsObject:@"Idle"] || 
        [inModifiedKeys containsObject:@"Warning"] ||
        [inModifiedKeys containsObject:@"Online"] ||
        [inModifiedKeys containsObject:@"UnviewedContent"] ||
        [inModifiedKeys containsObject:@"Signed On"] ||
        [inModifiedKeys containsObject:@"Signed Off"]){

        //Update the handle's text color
        [self applyColorToContact:inContact];
        modifiedAttributes = [NSArray arrayWithObject:@"Text Color"];
    }

    //Update our flash array
    if(inModifiedKeys == nil || [inModifiedKeys containsObject:@"UnviewedContent"]){
        int unviewedContent = [[inContact statusArrayForKey:@"UnviewedContent"] greatestIntegerValue];

        if(unviewedContent && ![flashingContactArray containsObject:inContact]){ //Start flashing
            [self addToFlashArray:inContact];
        }else if(!unviewedContent && [flashingContactArray containsObject:inContact]){ //Stop flashing
            [self removeFromFlashArray:inContact];
        }
    }

    return(modifiedAttributes);
}

//Applies the correct text color to the passed contact
- (void)applyColorToContact:(AIListContact *)inContact
{
    AIMutableOwnerArray		*colorArray = [inContact displayArrayForKey:@"Text Color"];
    AIMutableOwnerArray		*invertedColorArray = [inContact displayArrayForKey:@"Inverted Text Color"];
    int				away, warning, online, unviewedContent, signedOn, signedOff;
    double			idle;
    NSColor			*color = nil, *invertedColor = nil;

    //Get all the values
    away = [[inContact statusArrayForKey:@"Away"] greatestIntegerValue];
    idle = [[inContact statusArrayForKey:@"Idle"] greatestDoubleValue];
    warning = [[inContact statusArrayForKey:@"Warning"] greatestIntegerValue];
    online = [[inContact statusArrayForKey:@"Online"] greatestIntegerValue];
    unviewedContent = [[inContact statusArrayForKey:@"UnviewedContent"] greatestIntegerValue];
    signedOn = [[inContact statusArrayForKey:@"Signed On"] greatestIntegerValue];
    signedOff = [[inContact statusArrayForKey:@"Signed Off"] greatestIntegerValue];

    //Determine the correct color
    if(unviewedContent && ([[owner interfaceController] flashState] % 2)){
	color = unviewedContentColor;
	invertedColor = unviewedContentInvertedColor;
    }else if(signedOff){
	color = signedOffColor;
	invertedColor = signedOffInvertedColor;
    }else if(!online){
	color = signedOffColor;
	invertedColor = signedOffInvertedColor;
    }else if(signedOn){
	color = signedOnColor;
	invertedColor = signedOnInvertedColor;
    }else if(idle != 0 && away){
	color = idleAwayColor;
	invertedColor = idleAwayInvertedColor;
    }else if(idle != 0){
	color = idleColor;
	invertedColor = idleInvertedColor;
    }else if(away){
	color = awayColor;
	invertedColor = awayInvertedColor;
    }else if(warning){
	color = warningColor;
	invertedColor = warningInvertedColor;
    }else if(online){		// this should be the last 'if' before the final 'else'
	color = onlineColor;
	invertedColor = onlineInvertedColor;
    }else{
        color = [NSColor colorWithCalibratedRed:(0/255.0) green:(0/255.0) blue:(0/255.0) alpha:1.0];
        invertedColor = [NSColor colorWithCalibratedRed:(255.0/255.0) green:(255.0/255.0) blue:(255.0/255.0) alpha:1.0];
    }

    //Add the new color
    [colorArray setObject:color withOwner:self];
    [invertedColorArray setObject:invertedColor withOwner:self];
}

//Flash all handles with unviewed content
- (void)flash:(int)value
{
    NSEnumerator	*enumerator;
    AIListContact	*contact;

    enumerator = [flashingContactArray objectEnumerator];
    while((contact = [enumerator nextObject])){
        [self applyColorToContact:contact];
        
        //Force a redraw
        [[owner notificationCenter] postNotificationName:Contact_AttributesChanged object:contact userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:@"Text Color"] forKey:@"Keys"]];
    }
}

//Add a handle to the flash array
- (void)addToFlashArray:(AIListContact *)inContact
{
    //Ensure that we're observing the flashing
    if([flashingContactArray count] == 0){
        [[owner interfaceController] registerFlashObserver:self];
    }

    //Add the contact to our flash array
    [flashingContactArray addObject:inContact];
    [self flash:[[owner interfaceController] flashState]];
}

//Remove a handle from the flash array
- (void)removeFromFlashArray:(AIListContact *)inContact
{
    //Remove the contact from our flash array
    [flashingContactArray removeObject:inContact];

    //If we have no more flashing contacts, stop observing the flashes
    if([flashingContactArray count] == 0){
        [[owner interfaceController] unregisterFlashObserver:self];
    }
}

- (void)preferencesChanged:(NSNotification *)notification
{
    //Optimize this...
    if([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_CONTACT_STATUS_COLORING] == 0){
	NSDictionary	*prefDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_STATUS_COLORING];

	//Release the old values..
	//Cache the preference values
	signedOffColor = [[[prefDict objectForKey:KEY_SIGNED_OFF_COLOR] representedColor] retain];
	signedOnColor = [[[prefDict objectForKey:KEY_SIGNED_ON_COLOR] representedColor] retain];
	onlineColor = [[[prefDict objectForKey:KEY_ONLINE_COLOR] representedColor] retain];
	awayColor = [[[prefDict objectForKey:KEY_AWAY_COLOR] representedColor] retain];
	idleColor = [[[prefDict objectForKey:KEY_IDLE_COLOR] representedColor] retain];
	idleAwayColor = [[[prefDict objectForKey:KEY_IDLE_AWAY_COLOR] representedColor] retain];
	openTabColor = [[[prefDict objectForKey:KEY_OPEN_TAB_COLOR] representedColor] retain];
	unviewedContentColor = [[[prefDict objectForKey:KEY_UNVIEWED_COLOR] representedColor] retain];
	warningColor = [[[prefDict objectForKey:KEY_WARNING_COLOR] representedColor] retain];

	signedOffInvertedColor = [[[prefDict objectForKey:KEY_SIGNED_OFF_INVERTED_COLOR] representedColor] retain];
	signedOnInvertedColor = [[[prefDict objectForKey:KEY_SIGNED_ON_INVERTED_COLOR] representedColor] retain];
	onlineInvertedColor = [[[prefDict objectForKey:KEY_ONLINE_INVERTED_COLOR] representedColor] retain];
	awayInvertedColor = [[[prefDict objectForKey:KEY_AWAY_INVERTED_COLOR] representedColor] retain];
	idleInvertedColor = [[[prefDict objectForKey:KEY_IDLE_INVERTED_COLOR] representedColor] retain];
	idleAwayInvertedColor = [[[prefDict objectForKey:KEY_IDLE_AWAY_INVERTED_COLOR] representedColor] retain];
	openTabInvertedColor = [[[prefDict objectForKey:KEY_OPEN_TAB_INVERTED_COLOR] representedColor] retain];
	unviewedContentInvertedColor = [[[prefDict objectForKey:KEY_UNVIEWED_INVERTED_COLOR] representedColor] retain];
	warningInvertedColor = [[[prefDict objectForKey:KEY_WARNING_INVERTED_COLOR] representedColor] retain];

	NSEnumerator		*enumerator;
	AIListContact		*contact;

	enumerator = [[[owner contactController] allContactsInGroup:nil subgroups:YES] objectEnumerator];

	while((contact = [enumerator nextObject])){
	    [self updateContact:contact keys:nil];
	}

	[[owner notificationCenter] postNotificationName:Contact_ListChanged object:nil];
    }
}

@end
