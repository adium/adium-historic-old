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
#import "AIStatusCircle.h"
#import "AIStatusCirclesPlugin.h"
#import "AIStatusCirclesPreferences.h"

@interface AIStatusCirclesPlugin (PRIVATE)
- (NSString *)idleStringForSeconds:(int)seconds;
- (void)addToFlashArray:(AIListObject *)inObject;
- (void)removeFromFlashArray:(AIListObject *)inObject;
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIStatusCirclesPlugin

- (void)installPlugin
{
    //init
    displayIdleTime = NO;

    awayColor = nil;
    idleColor = nil;
    idleAwayColor = nil;
    onlineColor = nil;
    openTabColor = nil;
    signedOffColor = nil;
    signedOnColor = nil;
    unviewedContentColor = nil;
    warningColor = nil;

    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:STATUS_CIRCLES_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_STATUS_CIRCLES];
    [self preferencesChanged:nil];

    //Our preference view
    preferences = [[AIStatusCirclesPreferences statusCirclesPreferencesWithOwner:owner] retain];
    [[owner contactController] registerListObjectObserver:self];

    //Observe
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];

    flashingListObjectArray = [[NSMutableArray alloc] init];
}

- (void)uninstallPlugin
{
    //[[owner contactController] unregisterHandleObserver:self];
}

- (void)dealloc
{
    [super dealloc];
}

- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys
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
        [inModifiedKeys containsObject:@"UnviewedContent"] ||
        [inModifiedKeys containsObject:@"UnrespondedContent"] ||
        [inModifiedKeys containsObject:@"Warning"]){

        AIMutableOwnerArray	*iconArray, *tabIconArray;
        AIStatusCircle		*statusCircle, *tabStatusCircle;
        NSColor			*circleColor;
        int			away, online, openTab, signedOn, signedOff, typing, unrespondedContent, unviewedContent, warning;
        double			idle;
        
        //Get the status circle
        iconArray = [inObject displayArrayForKey:@"Left View"];
        tabIconArray = [inObject displayArrayForKey:@"Tab Left View"];
        statusCircle = [iconArray objectWithOwner:self];
        tabStatusCircle = [tabIconArray objectWithOwner:self];
	
        if(!statusCircle || !tabStatusCircle){
            statusCircle = [AIStatusCircle statusCircle];
            [iconArray setObject:statusCircle withOwner:self];

            tabStatusCircle = [AIStatusCircle statusCircle];
            [tabStatusCircle setBezeled:YES];
            [tabIconArray setObject:tabStatusCircle withOwner:self];
        }

        //Get all the values
        away = [[inObject statusArrayForKey:@"Away"] greatestIntegerValue];
        idle = [[inObject statusArrayForKey:@"Idle"] greatestDoubleValue];
        online = [[inObject statusArrayForKey:@"Online"] greatestIntegerValue];
        openTab = [[inObject statusArrayForKey:@"Open Tab"] greatestIntegerValue];
        signedOn = [[inObject statusArrayForKey:@"Signed On"] greatestIntegerValue];
        signedOff = [[inObject statusArrayForKey:@"Signed Off"] greatestIntegerValue];
        typing = [[inObject statusArrayForKey:@"Typing"] greatestIntegerValue];
        unviewedContent = [[inObject statusArrayForKey:@"UnviewedContent"] greatestIntegerValue];
        unrespondedContent = [[inObject statusArrayForKey:@"UnrespondedContent"] greatestIntegerValue];
        warning = [[inObject statusArrayForKey:@"Warning"] greatestIntegerValue];
        
        //Set the circle color
        if(signedOff){
	    circleColor = signedOffColor;
	}else if(!online){
	    circleColor = signedOffColor;
        }else if(signedOn){
	    circleColor = signedOnColor;
        }else if(idle != 0 && away){
	    circleColor = idleAwayColor;
        }else if(idle != 0){
	    circleColor = idleColor;
        }else if(away){
	    circleColor = awayColor;
        }else if(warning){
	    circleColor = warningColor;
        }else if(openTab){
            circleColor = openTabColor;
        }else if(online){	// this should be the last 'if' before the final 'else'
	    circleColor = onlineColor;
        }else{
            circleColor = [NSColor colorWithCalibratedRed:(255.0/255.0) green:(255.0/255.0) blue:(255.0/255.0) alpha:1.0];
        }
	
        [statusCircle setColor:circleColor];
        [tabStatusCircle setColor:circleColor];
        [statusCircle setFlashColor:unviewedContentColor];
        [tabStatusCircle setFlashColor:unviewedContentColor];

        //Embedded idle time
        if(idle != 0 && displayIdleTime){
            [statusCircle setStringContent:[self idleStringForSeconds:idle]];
            [tabStatusCircle setStringContent:[self idleStringForSeconds:idle]];
        }else{
            [statusCircle setStringContent:nil];
            [tabStatusCircle setStringContent:nil];
        }

        //Set the circle state
        if(typing){
            [statusCircle setState:AICirclePreFlash];
            [tabStatusCircle setState:AICirclePreFlash];
        }else if(!unviewedContent){
            [statusCircle setState:(unrespondedContent ? AICircleDot : AICircleNormal)];
            [tabStatusCircle setState:(unrespondedContent ? AICircleDot : AICircleNormal)];
        }else{
            [statusCircle setState:(([[owner interfaceController] flashState] % 2) ? AICircleFlashA: AICircleFlashB)];
            [tabStatusCircle setState:(([[owner interfaceController] flashState] % 2) ? AICircleFlashA: AICircleFlashB)];
        }

        modifiedAttributes = [NSArray arrayWithObjects:@"Left View", @"Tab Left View", nil];
    }

    //Update our flash array (To reflect unviewed content)
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

//Flash all handles with unviewed content
- (void)flash:(int)value
{
    NSEnumerator	*enumerator;
    AIListObject	*object;
    AIStatusCircle	*statusCircle;

    enumerator = [flashingListObjectArray objectEnumerator];
    while((object = [enumerator nextObject])){
        //Set the status circle to the correct state
        statusCircle = [[object displayArrayForKey:@"Left View"] objectWithOwner:self];
        [statusCircle setState:((value % 2) ? AICircleFlashA: AICircleFlashB)];

        statusCircle = [[object displayArrayForKey:@"Tab Left View"] objectWithOwner:self];
        [statusCircle setState:((value % 2) ? AICircleFlashA: AICircleFlashB)];

        //Force a redraw
        [[owner notificationCenter] postNotificationName:ListObject_AttributesChanged object:object userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:@"Left View"] forKey:@"Keys"]];
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

//
- (NSString *)idleStringForSeconds:(int)seconds
{
    NSString	*idleString;

    //Cap idle at 999 Hours (999*60*60 seconds)
    if(seconds > 599400){
        seconds = 599400;
    }

    //Create the idle string
    if(seconds >= 600){
        idleString = [NSString stringWithFormat:@"%ih",seconds / 60];
    }else if(seconds >= 60){
        idleString = [NSString stringWithFormat:@"%i:%02i",seconds / 60, seconds % 60];
    }else{
        idleString = [NSString stringWithFormat:@"%i",seconds];
    }

    return(idleString);
}

- (void)preferencesChanged:(NSNotification *)notification
{
    //Optimize this...
    if([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_STATUS_CIRCLES] == 0){
	NSDictionary	*prefDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_STATUS_CIRCLES];

	//Release the old values..
	//Cache the preference values
	displayIdleTime = [[prefDict objectForKey:KEY_DISPLAY_IDLE_TIME] boolValue];

	awayColor = [[[prefDict objectForKey:KEY_AWAY_COLOR] representedColor] retain];
	idleColor = [[[prefDict objectForKey:KEY_IDLE_COLOR] representedColor] retain];
	idleAwayColor = [[[prefDict objectForKey:KEY_IDLE_AWAY_COLOR] representedColor] retain];
	onlineColor = [[[prefDict objectForKey:KEY_ONLINE_COLOR] representedColor] retain];
	openTabColor = [[[prefDict objectForKey:KEY_OPEN_TAB_COLOR] representedColor] retain];
	signedOffColor = [[[prefDict objectForKey:KEY_SIGNED_OFF_COLOR] representedColor] retain];
	signedOnColor = [[[prefDict objectForKey:KEY_SIGNED_ON_COLOR] representedColor] retain];
	unviewedContentColor = [[[prefDict objectForKey:KEY_UNVIEWED_COLOR] representedColor] retain];
        warningColor = [[[prefDict objectForKey:KEY_WARNING_COLOR] representedColor] retain];

	NSEnumerator		*enumerator;
	AIListObject		*object;

	enumerator = [[[owner contactController] allContactsInGroup:nil subgroups:YES] objectEnumerator];

	while(object = [enumerator nextObject]){
            [[owner contactController] listObjectAttributesChanged:object modifiedKeys:[self updateListObject:object keys:nil]];
        }
    }
}

@end
