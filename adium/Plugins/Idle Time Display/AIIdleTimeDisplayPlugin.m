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
#import "AIIdleView.h"
#import "AIIdleTimeDisplayPlugin.h"
#import "AIIdleTimeDisplayPreferences.h"

@interface AIIdleTimeDisplayPlugin (PRIVATE)
- (NSString *)idleStringForSeconds:(int)seconds;
- (void)addToFlashArray:(AIListObject *)inObject;
- (void)removeFromFlashArray:(AIListObject *)inObject;
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIIdleTimeDisplayPlugin

- (void)installPlugin
{
    //init
    displayIdleTime = NO;

    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:IDLE_TIME_DISPLAY_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_IDLE_TIME_DISPLAY];
    [self preferencesChanged:nil];

    //Our preference view
    preferences = [[AIIdleTimeDisplayPreferences idleTimeDisplayPreferencesWithOwner:owner] retain];
    [[owner contactController] registerListObjectObserver:self];

    //Observe
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
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

    if(inModifiedKeys == nil || [inModifiedKeys containsObject:@"Idle"]){
        AIMutableOwnerArray	*rightViewArray = [inObject displayArrayForKey:@"Right View"];
        AIIdleView		*idleView = [rightViewArray objectWithOwner:self];
        double			idle;
        BOOL			attributesChanged = NO;

        //Set the correct idle time
        idle = [[inObject statusArrayForKey:@"Idle"] greatestDoubleValue];

        if(idle != 0 && displayIdleTime){
            //Add an idle view if one doesn't exist
            if(!idleView){
                idleView = [AIIdleView idleView];
                [rightViewArray setObject:idleView withOwner:self];
            }

            //Set the correct time
            [idleView setStringContent:[self idleStringForSeconds:idle]];
            attributesChanged = YES;

        }else{
            //Remove the idle view if one exists
            if(idleView){
                [rightViewArray setObject:nil withOwner:self];
                attributesChanged = YES;
            }

        }

        if(attributesChanged){
            modifiedAttributes = [NSArray arrayWithObjects:@"Right View", nil];
        }
    }

    return(modifiedAttributes);
}
/*{
NSArray		*modifiedAttributes = nil;

    if(inModifiedKeys == nil || [inModifiedKeys containsObject:@"Idle"]){
        AIMutableOwnerArray	*rightViewArray = [inObject displayArrayForKey:@"Right View"];
        AIIdleView		*idleView = [rightViewArray objectWithOwner:self];
        double			idle;

        //Set the correct idle time
        idle = [[inObject statusArrayForKey:@"Idle"] greatestDoubleValue];

        if(displayIdleTime){
            //Add an idle view if one doesn't exist
            if(!idleView){
                idleView = [AIIdleView idleView];
                [rightViewArray setObject:idleView withOwner:self];
            }

            //Set the correct time
            if(idle != 0){
                [idleView setStringContent:[self idleStringForSeconds:idle]];
            }else{
                [idleView setStringContent:@""];
            }

        }else{
            //Remove the idle view if one exists
            if(idleView){
                [rightViewArray setObject:nil withOwner:self];
            }

        }

        modifiedAttributes = [NSArray arrayWithObjects:@"Right View", nil];
    }

    return(modifiedAttributes);
}*/

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
    if([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_IDLE_TIME_DISPLAY] == 0){
	NSDictionary	*prefDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_IDLE_TIME_DISPLAY];

	//Cache the preference values
	displayIdleTime = [[prefDict objectForKey:KEY_DISPLAY_IDLE_TIME] boolValue];


	NSEnumerator		*enumerator;
	AIListObject		*object;

	enumerator = [[[owner contactController] allContactsInGroup:nil subgroups:YES] objectEnumerator];

	while(object = [enumerator nextObject]){
            [[owner contactController] listObjectAttributesChanged:object modifiedKeys:[self updateListObject:object keys:nil]];
        }
    }
}

@end
