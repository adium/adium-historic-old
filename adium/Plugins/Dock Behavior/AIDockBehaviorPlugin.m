/*-------------------------------------------------------------------------------------------------------*\
| AIDockBehaviorPlugin.m                                                                                  |
| Adium, Copyright (C) 2001-2002 Adam Iser. <adamiser@mac.com> <http://www.adiumx.com>                    |---\
\---------------------------------------------------------------------------------------------------------/   |
  | This program is free software; you can redistribute it and/or modify it under the terms of the GNU        |
  | General Public License as published by the Free Software Foundation; either version 2 of the License,     |
  | or (at your option) any later version.                                                                    |
  |                                                                                                           |
  | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even    |
  | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General         |
  | Public License for more details.                                                                          |
  |                                                                                                           |
  | You should have received a copy of the GNU General Public License along with this program; if not,        |
  | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.    |
  \----------------------------------------------------------------------------------------------------------*/

#import <AIUtilities/AIUtilities.h>
#import "AIDockBehaviorPlugin.h"
#import "AIDockBehaviorPreferences.h"

@implementation AIDockBehaviorPlugin

- (void)installPlugin
{
    //register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys: 
        [NSNumber numberWithBool:YES], PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT, nil]
    forGroup:PREF_GROUP_DOCK_BEHAVIOR];
    
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys: 
        [NSNumber numberWithDouble:2.0], PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_DELAY, nil]
    forGroup:PREF_GROUP_DOCK_BEHAVIOR];
    
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys: 
        [NSNumber numberWithInt:5], PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_NUM, nil]
    forGroup:PREF_GROUP_DOCK_BEHAVIOR];

    preferences = [[AIDockBehaviorPreferences dockBehaviorPreferencesWithOwner:owner] retain];
    
    //install our observers
    [[owner notificationCenter] addObserver:self selector:@selector(messageIn:) name:Content_DidReceiveContent object:nil];
}

- (void)messageIn:(NSNotification *)notification
{
    if([[[owner preferenceController] preferenceForKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT group:PREF_GROUP_DOCK_BEHAVIOR object:[notification object]] boolValue]) // are we bouncing at all?
    {
        if([[[owner preferenceController] preferenceForKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_NUM group:PREF_GROUP_DOCK_BEHAVIOR object:[notification object]] intValue] == 1 && [[[owner preferenceController] preferenceForKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_DELAY group:PREF_GROUP_DOCK_BEHAVIOR object:[notification object]] doubleValue] == 0.0) //if we only bounce once, and don't have a delay, use the method with less overhead
        {
            [[owner dockController] bounce];
        }
        else
        {
            [[owner dockController] 
                bounceWithInterval:[[[owner preferenceController] preferenceForKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_DELAY group:PREF_GROUP_DOCK_BEHAVIOR object:[notification object]] doubleValue] 
                times:[[[owner preferenceController] preferenceForKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_NUM group:PREF_GROUP_DOCK_BEHAVIOR object:[notification object]] intValue]];
        }
    }
}

@end