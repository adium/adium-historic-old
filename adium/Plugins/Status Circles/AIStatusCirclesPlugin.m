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

#import "AIStatusCircle.h"
#import "AIStatusCirclesPlugin.h"
#import "AIStatusCirclesPreferences.h"

@interface AIStatusCirclesPlugin (PRIVATE)
//- (NSString *)idleStringForSeconds:(int)seconds;
//- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIStatusCirclesPlugin

#define STATUS_CIRCLES_THEMABLE_PREFS   @"Status Circles Themable Prefs"

- (void)installPlugin
{
    //init
//    displayStatusCircle		= NO;
//    displayStatusCircleOnLeft	= NO;
//    displayIdleTime		= NO;
//    idleStringColor		= nil;
//	
//    //Register our default preferences
//    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:STATUS_CIRCLES_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_STATUS_CIRCLES];
//    [self preferencesChanged:nil];
//	
//    //Our preference view
//    preferences = [[AIStatusCirclesPreferences statusCirclesPreferences] retain];
//    [[adium contactController] registerListObjectObserver:self];
//    
//    //Register themable preferences
//    [[adium preferenceController] registerThemableKeys:[NSArray arrayNamed:STATUS_CIRCLES_THEMABLE_PREFS forClass:[self class]] forGroup:PREF_GROUP_STATUS_CIRCLES];
//    
//    //Observe
//    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
//	
    //flashingListObjectArray = [[NSMutableArray alloc] init];
}

- (void)uninstallPlugin
{
    //[[adium contactController] unregisterHandleObserver:self];
}

- (void)dealloc
{
    [super dealloc];
}

//- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
//{
//    NSArray *modifiedAttributes = nil;
//	
//	if([inObject isKindOfClass:[AIListContact class]]){
//		if(	inModifiedKeys == nil ||
//			[inModifiedKeys containsObject:@"Label Color"] ||
//			[inModifiedKeys containsObject:@"Typing"] ||
//			[inModifiedKeys containsObject:@"UnviewedContent"] ||
//			[inModifiedKeys containsObject:@"Away"] ||
//			[inModifiedKeys containsObject:@"Idle"] ||
//			[inModifiedKeys containsObject:@"Online"] ||
//			[inModifiedKeys containsObject:@"Signed On"] ||
//			[inModifiedKeys containsObject:@"Signed Off"]){
//			
//			AIMutableOwnerArray	*iconArray;
//			AIStatusCircle		*statusCircle;
//			NSColor			*circleColor;
//			
//			double			idle;
//			
//			if(displayStatusCircleOnLeft){
//				iconArray = [inObject displayArrayForKey:@"Left View"];
//				[[inObject displayArrayForKey:@"Right View"] setObject:nil withOwner:self];
//				
//			}else{
//				iconArray = [inObject displayArrayForKey:@"Right View"];
//				[[inObject displayArrayForKey:@"Left View"]  setObject:nil withOwner:self];
//				
//			}
//			
//			statusCircle = [iconArray objectWithOwner:self];
//			
//			if(displayStatusCircle){
//				
//				if(!statusCircle){
//					statusCircle = [AIStatusCircle statusCircle];
//					[iconArray setObject:statusCircle withOwner:self];
//				}
//				
//				circleColor = [[inObject displayArrayForKey:@"Label Color"] averageColor];
//				
//				if(!circleColor){
//					circleColor = [NSColor colorWithCalibratedRed:(255.0/255.0) green:(255.0/255.0) blue:(255.0/255.0) alpha:1.0];
//				}
//				
//				[statusCircle setColor:circleColor];
//				
//				idle = [inObject doubleStatusObjectForKey:@"Idle"];
//				
//				//Embedded idle time
//				if(displayIdleTime && idle != 0){
//					[statusCircle setStringContent:[self idleStringForSeconds:idle]];
//					[statusCircle setStringColor:idleStringColor];
//				}else{
//					[statusCircle setStringContent:nil];
//					[statusCircle setStringColor:idleStringColor];
//				}
//				
//			}else{
//				if(statusCircle){
//					[iconArray setObject:nil withOwner:self];
//				}
//			}
//			
//			modifiedAttributes = [NSArray arrayWithObjects:@"Left View", @"Right View", nil];
//		}
//	}
//		
//    return(modifiedAttributes);
//}

/*
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
		 [[adium notificationCenter] postNotificationName:ListObject_AttributesChanged object:object userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:@"Left View"] forKey:@"Keys"]];
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
 */

//
//- (NSString *)idleStringForSeconds:(int)seconds
//{
//    NSString	*idleString;
//	
//    //Cap idle at 999 Hours (999*60*60 seconds)
//    if(seconds > 599400){
//        seconds = 599400;
//    }
//	
//    //Create the idle string
//    if(seconds >= 600){
//        idleString = [NSString stringWithFormat:@"%ih",seconds / 60];
//    }else if(seconds >= 60){
//        idleString = [NSString stringWithFormat:@"%i:%02i",seconds / 60, seconds % 60];
//    }else{
//        idleString = [NSString stringWithFormat:@"%i",seconds];
//    }
//	
//    return(idleString);
//}
//
//- (void)preferencesChanged:(NSNotification *)notification
//{
//    //Optimize this...
//    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_STATUS_CIRCLES] == 0/* ||
//		[(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:@"Contact Status Coloring"] == 0 */){
//		NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_STATUS_CIRCLES];
//		
//		//Release the old values..
//		//Cache the preference values
//		displayStatusCircle		= [[prefDict objectForKey:KEY_DISPLAY_STATUS_CIRCLE] boolValue];
//		displayStatusCircleOnLeft	= [[prefDict objectForKey:KEY_DISPLAY_STATUS_CIRCLE_ON_LEFT] boolValue];
//		displayIdleTime			= [[prefDict objectForKey:KEY_DISPLAY_IDLE_TIME] boolValue];
//		idleStringColor			= [[[prefDict objectForKey:KEY_IDLE_TIME_COLOR] representedColor] retain];
//		
//        [AIStatusCircle shouldDisplayIdleTime:displayIdleTime];
//        [AIStatusCircle setIsOnLeft:displayStatusCircleOnLeft];
//        
//        //Update all our status circles
//		[[adium contactController] updateAllListObjectsForObserver:self];
//    }
//}

@end
