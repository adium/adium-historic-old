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

#import "AIIdleView.h"
#import "AIIdleTimeDisplayPlugin.h"
#import "AIIdleTimeDisplayPreferences.h"

#define IDLE_TIME_THEMABLE_PREFS    @"Idle Time Themable Prefs"

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
    displayIdleOnLeft = NO;
    idleTextColor = nil;

    //Register our default preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:IDLE_TIME_DISPLAY_DEFAULT_PREFS forClass:[self class]] 
					  forGroup:PREF_GROUP_IDLE_TIME_DISPLAY];
    //Register themable preferences
    [[adium preferenceController] registerThemableKeys:[NSArray arrayNamed:IDLE_TIME_THEMABLE_PREFS forClass:[self class]]
						     forGroup:PREF_GROUP_IDLE_TIME_DISPLAY];
    
    //Our preference view
    preferences = [[AIIdleTimeDisplayPreferences preferencePane] retain];

    //Observe
    [[adium notificationCenter] addObserver:self
								   selector:@selector(preferencesChanged:)
									   name:Preference_GroupChanged 
									 object:nil];
    [self preferencesChanged:nil];
}

- (void)uninstallPlugin
{
    //[[adium contactController] unregisterHandleObserver:self];
}

- (void)dealloc
{
    [idleTextColor release];

    [super dealloc];
}

- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
    NSArray		*modifiedAttributes = nil;

    if(inModifiedKeys == nil || [inModifiedKeys containsObject:@"Idle"]){
        AIMutableOwnerArray	*viewArray;
        AIIdleView		*idleView = nil;
        int				idle;
		
        //Set the correct idle time
        idle = [[inObject numberStatusObjectForKey:@"Idle"] intValue];
		viewArray = [inObject displayArrayForKey:@"Right View"];
		
        idleView = [viewArray objectWithOwner:self];

        if(displayIdleTime && idle != 0){
            //Add an idle view if one doesn't exist
            if(!idleView){
                idleView = [AIIdleView idleView];
                [viewArray setObject:idleView withOwner:self];
            }
			
            //Set the correct time
            [idleView setStringContent:[self idleStringForSeconds:idle]];
			
            //Set the correct color
            [idleView setColor:idleTextColor];
            
        }else{
            //Remove the idle view if one exists
            if(idleView){
                [viewArray setObject:nil withOwner:self];
            }
        }
		
		modifiedAttributes = [NSArray arrayWithObjects:@"Right View", nil];
    }
	
    return(modifiedAttributes);
}

//
- (NSString *)idleStringForSeconds:(int)seconds
{
    NSString	*idleString;

    //Create the idle string
    if(seconds > 599400){//Cap idle at 999 Hours (999*60*60 seconds)
        idleString = @"Idle";
    }else if(seconds >= 600){
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
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_IDLE_TIME_DISPLAY]){
		NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_IDLE_TIME_DISPLAY];
		
        //Cache the preference values
        [idleTextColor release];
		displayIdleTime = [[prefDict objectForKey:KEY_DISPLAY_IDLE_TIME] boolValue];
		displayIdleOnLeft = [[prefDict objectForKey:KEY_DISPLAY_IDLE_TIME_ON_LEFT] boolValue];
        idleTextColor = [[[prefDict objectForKey:KEY_IDLE_TIME_COLOR] representedColor] retain];
        
		if (notification){
			//Update all our idle views
			[[adium contactController] updateAllListObjectsForObserver:self];
		}else{
			[[adium contactController] registerListObjectObserver:self];
		}
    }
}

@end
